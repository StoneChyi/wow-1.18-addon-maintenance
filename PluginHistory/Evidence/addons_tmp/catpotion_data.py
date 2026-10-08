import struct, zlib, bz2, json
from pathlib import Path

ROOT = Path('E:/1.18')
OUT = ROOT / 'addons_tmp/catpotion-research'
OUT.mkdir(exist_ok=True)

def cache_items():
    raw = (ROOT / 'WDB/itemcache.wdb').read_bytes()
    p, result = 20, {}
    while p + 8 <= len(raw):
        iid, size = struct.unpack_from('<II', raw, p)
        p += 8
        if not iid or not size: break
        data = raw[p:p+size]
        p += size
        q, names = 8, []
        for _ in range(4):
            end = data.index(0, q)
            try: names.append(data[q:end].decode('utf-8'))
            except UnicodeDecodeError: names.append(data[q:end].decode('gb18030', errors='replace'))
            q = end + 1
        fields = struct.unpack_from('<24i', data, q)
        # display ... container slots: 23 integers, then 10 stat pairs,
        # five (min,max,school) damage tuples, seven resistances, delay/ammo/range.
        offset = q + 20*4 + 20*4 + 15*4 + 7*4 + 3*4
        spells = [struct.unpack_from('<6i', data, offset + i*24) for i in range(5)]
        result[iid] = dict(id=iid, name=names[0], display=fields[0], inventory=fields[5], spells=spells)
    return result

CRYPT = [0]*0x500
seed = 0x100001
for first in range(256):
    for second in range(5):
        seed = (seed*125+3) % 0x2AAAAB
        upper = (seed & 0xFFFF) << 16
        seed = (seed*125+3) % 0x2AAAAB
        CRYPT[first + second*256] = upper | (seed & 0xFFFF)

def hashname(name, kind):
    a, b = 0x7FED7FED, 0xEEEEEEEE
    for ch in name.upper().encode('ascii'):
        a = (CRYPT[kind*256+ch] ^ (a+b)) & 0xFFFFFFFF
        b = (ch+a+b+(b << 5)+3) & 0xFFFFFFFF
    return a

def decrypt(data, key):
    seed, out = 0xEEEEEEEE, bytearray()
    for value in struct.unpack('<%dI' % (len(data)//4), data):
        seed = (seed + CRYPT[0x400+(key & 255)]) & 0xFFFFFFFF
        value ^= (key + seed) & 0xFFFFFFFF
        key = (((~key << 21)+0x11111111) | (key >> 11)) & 0xFFFFFFFF
        seed = (value+seed+(seed << 5)+3) & 0xFFFFFFFF
        out += struct.pack('<I', value)
    return out

def decompress(data, size):
    if len(data) == size: return data
    mask, data = data[0], data[1:]
    if mask == 2: return zlib.decompress(data)
    if mask == 16: return bz2.decompress(data)
    raise ValueError('unsupported compression %s' % mask)

class MPQ:
    def __init__(self, path):
        self.path, self.file = path, path.open('rb')
        header = self.file.read(32)
        magic, hs, archive, ver, shift, ho, bo, hn, bn = struct.unpack('<4sIIHHIIII', header)
        if magic != b'MPQ\x1a': raise ValueError('header '+str(path))
        self.sector = 512 << shift
        self.file.seek(ho)
        self.hashes = list(struct.iter_unpack('<IIHHI', decrypt(self.file.read(hn*16), hashname('(hash table)', 3))))
        self.file.seek(bo)
        self.blocks = list(struct.iter_unpack('<4I', decrypt(self.file.read(bn*16), hashname('(block table)', 3))))
    def read(self, name):
        ha, hb = hashname(name, 1), hashname(name, 2)
        matches = [h for h in self.hashes if h[0] == ha and h[1] == hb and h[4] < len(self.blocks)]
        if not matches: return None
        off, packed, size, flags = self.blocks[matches[0][4]]
        self.file.seek(off)
        data = self.file.read(packed)
        if flags & 0x10000: raise ValueError('encrypted '+name)
        if flags & 0x1000000:
            return decompress(data, size) if flags & 0x200 else data
        if not flags & 0x200: return data[:size]
        n = (size + self.sector-1)//self.sector
        offsets = struct.unpack_from('<%dI' % (n+1), data)
        return b''.join(decompress(data[offsets[i]:offsets[i+1]], min(self.sector, size-i*self.sector)) for i in range(n))

def dbc(raw):
    magic, rows, fields, size, strings = struct.unpack_from('<4s4I', raw)
    assert magic == b'WDBC'
    ss = raw[20+rows*size:]
    def string(off): return ss[off:ss.index(0,off)].decode('utf-8',errors='replace')
    values = {r[0]:r for r in struct.iter_unpack('<%dI' % fields, raw[20:20+rows*size])}
    return values, string, fields

if __name__ == '__main__':
    items = cache_items()
    (OUT/'item-cache.json').write_text(json.dumps(items, ensure_ascii=False), encoding='utf-8')
    files = sorted((ROOT/'Data').glob('*'), key=lambda p: p.name.lower(), reverse=True)
    needed = ['Spell.dbc', 'ItemDisplayInfo.dbc', 'SpellIcon.dbc']
    for path in files:
        if path.suffix.lower() != '.mpq': continue
        try:
            archive = MPQ(path)
            for name in needed[:]:
                raw = archive.read('DBFilesClient\\'+name)
                if raw:
                    (OUT/name).write_bytes(raw)
                    print(name, path.name, len(raw), struct.unpack_from('<4I',raw,4))
                    needed.remove(name)
            archive.file.close()
        except Exception as e: print(path.name, str(e))
        if not needed: break
    ids = [2459,8956,3387,61181,12450,61675,15723,13446,13444,13442,10646,15993,10507,18637,4392,12662,20520]
    for iid in ids: print(json.dumps(items.get(iid),ensure_ascii=False))
