"""Read-only MPQ v0/v1 reader for map extraction. Unsupported codecs fail closed.

No archive is ever modified. Tables and file sectors are checked before use.
"""
import bz2
import struct
import zlib
from pathlib import Path

MASK = 0xffffffff
CRYPT = [0] * 0x500
seed = 0x100001
for a in range(256):
    for b in range(5):
        seed = (seed * 125 + 3) % 0x2aaaab
        high = (seed & 0xffff) << 16
        seed = (seed * 125 + 3) % 0x2aaaab
        CRYPT[a + b * 256] = high | (seed & 0xffff)


def hash_name(name, kind):
    first, second = 0x7fed7fed, 0xeeeeeeee
    for char in name.replace('/', '\\').upper().encode('ascii'):
        first = (CRYPT[kind * 256 + char] ^ (first + second)) & MASK
        second = (char + first + second + (second << 5) + 3) & MASK
    return first


def decrypt(data, key):
    result = bytearray(data)
    second = 0xeeeeeeee
    for off in range(0, len(data) - 3, 4):
        second = (second + CRYPT[0x400 + (key & 255)]) & MASK
        word = struct.unpack_from('<I', data, off)[0] ^ ((key + second) & MASK)
        struct.pack_into('<I', result, off, word)
        key = (((~key << 21) + 0x11111111) | (key >> 11)) & MASK
        second = (word + second + (second << 5) + 3) & MASK
    return bytes(result)


def decompress(data, expected):
    if len(data) == expected:
        return data
    method, payload = data[0], data[1:]
    if method == 2:
        result = zlib.decompress(payload)
    elif method == 16:
        result = bz2.decompress(payload)
    else:
        raise ValueError('Unsupported MPQ compression: ' + hex(method))
    if len(result) != expected:
        raise ValueError('MPQ decompressed length mismatch')
    return result


class Archive:
    def __init__(self, path):
        self.path = Path(path)
        self.file = self.path.open('rb')
        self.header = self.file.read(32)
        magic, size, total, version, shift, hp, bp, hc, bc = struct.unpack('<4sIIHHIIII', self.header)
        if magic != b'MPQ\x1a' or version not in (0, 1) or size != (32 if version == 0 else 44):
            raise ValueError('Only MPQ v0/v1 supported: ' + str(path))
        if version == 1:
            extended, high_hash, high_block = struct.unpack('<QHH', self.file.read(12))
            if extended:
                raise ValueError('Extended block offsets not supported')
            hp += high_hash << 32
            bp += high_block << 32
        self.sector = 512 << shift
        self.file.seek(hp)
        self.hashes = list(struct.iter_unpack('<IIHHI', decrypt(self.file.read(hc * 16), hash_name('(hash table)', 3))))
        self.file.seek(bp)
        self.blocks = list(struct.iter_unpack('<IIII', decrypt(self.file.read(bc * 16), hash_name('(block table)', 3))))

    def entry(self, name):
        ha, hb = hash_name(name, 1), hash_name(name, 2)
        start = hash_name(name, 0) % len(self.hashes)
        matches = []
        for delta in range(len(self.hashes)):
            a, b, locale, platform, block = self.hashes[(start + delta) % len(self.hashes)]
            if block == 0xffffffff:
                break
            if a == ha and b == hb and block < len(self.blocks):
                matches.append((locale, block))
        if not matches:
            return None
        # This installed client is zhCN; prefer its entry, then locale-neutral.
        matches.sort(key=lambda pair: (pair[0] != 0x804, pair[0] != 0))
        return self.blocks[matches[0][1]]

    def read(self, name):
        entry = self.entry(name)
        if entry is None:
            raise FileNotFoundError(name)
        offset, compressed, size, flags = entry
        if not flags & 0x80000000 or flags & 0x02000000:
            raise FileNotFoundError(name)
        self.file.seek(offset)
        data = self.file.read(compressed)
        if len(data) != compressed:
            raise ValueError('Truncated MPQ file')
        key = hash_name(name.replace('/', '\\').split('\\')[-1], 3)
        if flags & 0x20000:
            key = ((key + offset) ^ size) & MASK
        encrypted = flags & 0x10000
        if flags & 0x01000000:
            if encrypted:
                data = decrypt(data, key)
            return decompress(data, size) if flags & 0x200 else data
        if not flags & 0x300:
            return decrypt(data, key) if encrypted else data
        if flags & 0x100:
            raise ValueError('Unsupported MPQ implode codec')
        count = (size + self.sector - 1) // self.sector
        table = data[:(count + 1) * 4]
        if encrypted:
            table = decrypt(table, (key - 1) & MASK)
        offsets = struct.unpack('<' + 'I' * (count + 1), table)
        if offsets[0] < len(table) or offsets[-1] > len(data) or list(offsets) != sorted(offsets):
            raise ValueError('Invalid MPQ sector offsets')
        parts = []
        for index in range(count):
            part = data[offsets[index]:offsets[index + 1]]
            if encrypted:
                part = decrypt(part, (key + index) & MASK)
            parts.append(decompress(part, min(self.sector, size - index * self.sector)))
        result = b''.join(parts)
        if len(result) != size:
            raise ValueError('MPQ file length mismatch')
        return result

    def close(self):
        self.file.close()


class Client:
    def __init__(self, root, include_terrain=False):
        self.root = Path(root)
        data = self.root / 'Data'
        base = ['base.MPQ', 'dbc.MPQ', 'texture.MPQ', 'interface.MPQ']
        if include_terrain:base.insert(0,'terrain.MPQ')
        paths = [data / name for name in base if (data / name).exists()]
        patches = sorted([p for p in data.iterdir() if p.name.lower() == 'patch.mpq' or p.name.lower().startswith('patch-') and p.suffix.lower() == '.mpq'], key=lambda p: p.name.upper())
        # patch.MPQ precedes patch-2 ... patch-Z in the client's patch chain.
        patches.sort(key=lambda p: (p.name.lower() != 'patch.mpq', p.name.upper()))
        self.archives = [Archive(p) for p in paths + patches]

    def read(self, name):
        path = self.root / name.replace('\\', '/')
        if path.is_file():
            return path.read_bytes(), 'loose:' + name
        for archive in reversed(self.archives):
            if archive.entry(name):
                return archive.read(name), 'Data/' + archive.path.name
        raise FileNotFoundError(name)

    def listed(self):
        names = {}
        for archive in self.archives:
            try:
                content = archive.read('(listfile)').decode('utf-8', errors='replace')
            except FileNotFoundError:
                continue
            for name in content.splitlines():
                names[name.lower()] = name
        return sorted(names.values(), key=str.lower)


def dbc(data):
    magic, count, fields, size, strings = struct.unpack_from('<4sIIII', data)
    if magic != b'WDBC' or size != fields * 4 or len(data) != 20 + count * size + strings:
        raise ValueError('Invalid DBC file')
    rows = list(struct.iter_unpack('<' + 'I' * fields, data[20:20 + count * size]))
    text = data[20 + count * size:]
    return rows, text, fields


def dbc_string(text, offset):
    end = text.find(b'\0', offset)
    if end < 0:
        raise ValueError('Invalid DBC string')
    value = text[offset:end]
    try:
        return value.decode('utf-8')
    except UnicodeDecodeError:
        return value.decode('gb18030')
