"""Task-local HTTP-range ZIP reader. No installs/deletes, outputs restricted to E:.

Partial downloads cannot verify a whole-package SHA256. Member sizes and CRC32
are verified against the HTTPS central directory; record this distinction.
"""
import argparse
import bisect
import concurrent.futures
import fnmatch
import json
import os
from pathlib import Path, PurePosixPath
import stat
import struct
import threading
import time
import urllib.parse
import urllib.request
import uuid
import zlib


def e_path(path):
    value = Path(path)
    if not value.is_absolute() or value.drive.upper() != 'E:':
        raise ValueError('Output path must be absolute on E:')
    resolved = value.resolve()
    if resolved.drive.upper() != 'E:':
        raise ValueError('Output resolves outside E:')
    return resolved


def safe_member(name):
    if '\\' in name or '\x00' in name or ':' in name or name.startswith('/'):
        raise ValueError('Unsafe ZIP member: ' + repr(name))
    parts = PurePosixPath(name).parts
    if not parts or any(p in ('..', '.') for p in parts):
        raise ValueError('Unsafe ZIP member: ' + repr(name))
    return parts


class RemoteZip:
    def __init__(self, url, size=None, timeout=60):
        if urllib.parse.urlsplit(url).scheme != 'https':
            raise ValueError('HTTPS required')
        self.url, self.timeout = url, timeout
        self.bytes_fetched = 0
        self._lock = threading.Lock()
        if size is None:
            req = urllib.request.Request(url, method='HEAD', headers={'Accept-Encoding': 'identity'})
            with urllib.request.urlopen(req, timeout=timeout) as response:
                if urllib.parse.urlsplit(response.geturl()).scheme != 'https':
                    raise ValueError('Non-HTTPS redirect')
                size = int(response.headers['Content-Length'])
        self.size = int(size)
        self.entries = self._directory()
        self.by_name = {e['name']: e for e in self.entries}
        if len(self.by_name) != len(self.entries):
            raise ValueError('Duplicate ZIP member names')

    def _range(self, start, end):
        if not 0 <= start <= end < self.size:
            raise ValueError('Invalid byte range')
        error = None
        for attempt in range(3):
            try:
                req = urllib.request.Request(self.url, headers={
                    'Range': f'bytes={start}-{end}', 'Accept-Encoding': 'identity'})
                with urllib.request.urlopen(req, timeout=self.timeout) as response:
                    # Never consume a full file when the server ignores Range.
                    if response.status != 206:
                        raise ValueError(f'HTTP 206 required, received {response.status}')
                    if urllib.parse.urlsplit(response.geturl()).scheme != 'https':
                        raise ValueError('Non-HTTPS redirect')
                    expected = f'bytes {start}-{end}/{self.size}'
                    if response.headers.get('Content-Range') != expected:
                        raise ValueError('Content-Range mismatch: ' + str(response.headers.get('Content-Range')))
                    content = response.read(end-start+2)
                    if len(content) != end-start+1:
                        raise ValueError('Range body length mismatch')
                with self._lock:
                    self.bytes_fetched += len(content)
                return content
            except (OSError, urllib.error.URLError) as exc:
                error = exc
                if attempt < 2:
                    time.sleep(0.5 * (attempt+1))
        raise error

    def _directory(self):
        tail = self._range(max(0, self.size-65557), self.size-1)
        pos = tail.rfind(b'PK\x05\x06')
        if pos < 0 or len(tail)-pos < 22:
            raise ValueError('ZIP end record missing')
        sig, disk, cd_disk, disk_count, count, length, offset, comment = struct.unpack_from('<4s4H2IH', tail, pos)
        if disk or cd_disk or disk_count != count:
            raise ValueError('Multi-volume ZIP not supported')
        if count == 65535 or length == 0xffffffff or offset == 0xffffffff:
            locator_pos=pos-20
            if locator_pos<0 or tail[locator_pos:locator_pos+4]!=b'PK\x06\x07':
                raise ValueError('ZIP64 locator missing')
            _,zip_disk,zip_offset,disks=struct.unpack_from('<4sIQI',tail,locator_pos)
            if zip_disk or disks!=1:
                raise ValueError('Multi-volume ZIP64 not supported')
            record=self._range(zip_offset,zip_offset+55)
            fields64=struct.unpack('<4sQ2H2I4Q',record)
            if fields64[0]!=b'PK\x06\x06' or fields64[4] or fields64[5] or fields64[6]!=fields64[7]:
                raise ValueError('Invalid ZIP64 end record')
            count,length,offset=fields64[7],fields64[8],fields64[9]
        if comment != len(tail)-pos-22 or length > 32*1024*1024:
            raise ValueError('Unexpected ZIP end record/directory size')
        data = self._range(offset, offset+length-1)
        entries, cursor = [], 0
        for _ in range(count):
            fields = struct.unpack_from('<4s6H3I5H2I', data, cursor)
            if fields[0] != b'PK\x01\x02':
                raise ValueError('Bad central directory signature')
            flags, method, crc, compressed, uncompressed = fields[3], fields[4], fields[7], fields[8], fields[9]
            nl, el, cl, disk_start, external, local = fields[10], fields[11], fields[12], fields[13], fields[15], fields[16]
            name_bytes = data[cursor+46:cursor+46+nl]
            name = name_bytes.decode('utf-8' if flags & 0x800 else 'cp437')
            safe_member(name)
            if disk_start or max(compressed, uncompressed, local) == 0xffffffff:
                raise ValueError('ZIP64 or multi-volume member not supported')
            entries.append({'name': name, 'flags': flags, 'method': method, 'crc32': crc,
                            'compressed': compressed, 'uncompressed': uncompressed,
                            'local_offset': local, 'external': external, '_name_bytes': name_bytes})
            cursor += 46+nl+el+cl
        if cursor != len(data):
            raise ValueError('Central directory trailing data/size mismatch')
        return entries

    def list(self):
        return [{k:v for k,v in entry.items() if not k.startswith('_')} for entry in self.entries]

    def extract(self, names, destination, strip_prefix='', workers=6,
                gap=65536, max_range=8*1024*1024, max_file=256*1024*1024):
        destination = e_path(destination)
        destination.mkdir(parents=True, exist_ok=True)
        if workers < 1 or workers > 8 or max_range < 65536:
            raise ValueError('Workers must be 1..8 and range size >=64KiB')
        selected = []
        for name in dict.fromkeys(names):
            entry = self.by_name[name]
            if name.endswith('/'):
                continue
            if entry['flags'] & 1 or entry['method'] not in (0, 8):
                raise ValueError('Encrypted/unsupported member: ' + name)
            if stat.S_IFMT(entry['external'] >> 16) == stat.S_IFLNK:
                raise ValueError('Symlink member rejected: ' + name)
            if entry['uncompressed'] > max_file:
                raise ValueError('Member exceeds size limit: ' + name)
            if strip_prefix and not name.startswith(strip_prefix):
                raise ValueError('Strip prefix mismatch: ' + name)
            relative = name[len(strip_prefix):] if strip_prefix else name
            target = e_path(destination.joinpath(*safe_member(relative)))
            if not target.is_relative_to(destination):
                raise ValueError('Member escapes destination: ' + name)
            if target.exists():
                # Never overwrite a different existing file.
                data = target.read_bytes()
                if len(data) != entry['uncompressed'] or (zlib.crc32(data)&0xffffffff) != entry['crc32']:
                    raise FileExistsError('Different existing output: ' + str(target))
                continue
            selected.append((entry, target))
        selected.sort(key=lambda item: item[0]['local_offset'])
        if not selected:
            return {'selected': len(names), 'written': 0, 'bytes_fetched': self.bytes_fetched,
                    'whole_package_sha256_verified': False}
        # Header extra fields are at most 65535 bytes. Filename must match the
        # central directory. This bounded padding permits batching before local
        # headers have been fetched, avoiding thousands of HTTP requests.
        merged = []
        for entry, _ in selected:
            start = entry['local_offset']
            end = min(self.size-1, start+30+len(entry['_name_bytes'])+65535+entry['compressed']-1)
            if merged and start <= merged[-1][1]+gap+1:
                merged[-1][1] = max(merged[-1][1], end)
            else:
                merged.append([start, end])
        ranges = [(s, min(end, s+max_range-1)) for start,end in merged
                  for s in range(start, end+1, max_range)]
        cached = {}
        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
            pending = {pool.submit(self._range, start, end):(start,end) for start,end in ranges}
            for future in concurrent.futures.as_completed(pending):
                start,end = pending[future]
                cached[start] = future.result()
        starts = sorted(cached)
        def read(start, length):
            chunks=[]
            while length:
                index=bisect.bisect_right(starts,start)-1
                if index<0:
                    raise ValueError('Requested bytes not prefetched')
                base=starts[index];data=cached[base]
                offset=start-base;take=min(length,len(data)-offset)
                if take<=0:
                    raise ValueError('Gap in prefetched bytes')
                chunks.append(data[offset:offset+take]);start+=take;length-=take
            return b''.join(chunks)
        written=[]
        for entry,target in selected:
            header=read(entry['local_offset'],30)
            values=struct.unpack('<4s5H3I2H',header)
            if values[0]!=b'PK\x03\x04' or values[3]!=entry['method'] or values[2]!=entry['flags']:
                raise ValueError('Local header differs from central directory')
            nl,el=values[9],values[10]
            local_name=read(entry['local_offset']+30,nl)
            if local_name!=entry['_name_bytes']:
                raise ValueError('Local filename differs from central directory')
            packed=read(entry['local_offset']+30+nl+el,entry['compressed'])
            if entry['method']==0:
                data=packed
            else:
                decoder=zlib.decompressobj(-15)
                data=decoder.decompress(packed,entry['uncompressed']+1)
                if len(data)>entry['uncompressed'] or not decoder.eof or decoder.unused_data or decoder.unconsumed_tail:
                    raise ValueError('Invalid/oversized deflate stream: '+entry['name'])
            if len(data)!=entry['uncompressed'] or (zlib.crc32(data)&0xffffffff)!=entry['crc32']:
                raise ValueError('Member size/CRC mismatch: '+entry['name'])
            target.parent.mkdir(parents=True,exist_ok=True)
            # Recheck after parent creation (including any existing symlinks).
            if not e_path(target).is_relative_to(destination):
                raise ValueError('Output path escapes destination')
            part=e_path(str(target)+'.part-'+uuid.uuid4().hex)
            with part.open('xb') as stream:
                stream.write(data)
            # Windows rename refuses an existing destination. No deletes used.
            part.rename(target)
            written.append({'name':entry['name'],'path':str(target),'bytes':len(data),
                            'crc32':f"{entry['crc32']:08x}"})
        return {'url':self.url,'package_bytes':self.size,'selected':len(names),'written':len(written),
                'range_requests':len(ranges)+2,'bytes_fetched':self.bytes_fetched,'files':written,
                'whole_package_sha256_verified':False}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode',choices=['list','extract'])
    parser.add_argument('--url',required=True)
    parser.add_argument('--size',type=int)
    parser.add_argument('--dest')
    parser.add_argument('--strip-prefix',default='')
    parser.add_argument('--include',action='append',default=[])
    parser.add_argument('--exclude',action='append',default=[])
    parser.add_argument('--workers',type=int,default=6)
    parser.add_argument('--out',required=True)
    args=parser.parse_args()
    output=e_path(args.out)
    remote=RemoteZip(args.url,args.size)
    if args.mode=='list':
        result={'url':args.url,'package_bytes':remote.size,'bytes_fetched':remote.bytes_fetched,
                'whole_package_sha256_verified':False,'entries':remote.list()}
    else:
        if not args.dest or not args.include:
            parser.error('extract requires --dest and explicit --include patterns')
        names=[entry['name'] for entry in remote.entries
               if any(fnmatch.fnmatchcase(entry['name'],p) for p in args.include)
               and not any(fnmatch.fnmatchcase(entry['name'],p) for p in args.exclude)]
        if not names:
            raise ValueError('No matching members')
        result=remote.extract(names,args.dest,args.strip_prefix,args.workers)
    output.parent.mkdir(parents=True,exist_ok=True)
    if output.exists():
        raise FileExistsError('Manifest output already exists: '+str(output))
    output.write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k not in ['entries','files']},indent=2))


if __name__=='__main__':
    main()
