"""Build a hash-locked candidate from the user's existing x86 DLL.

No game files are replaced. The new section contains only a bounds guard.
"""
import hashlib
import json
import pathlib
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parent
GAME = ROOT.parents[1]
sys.path.insert(0, str(GAME / 'CodexBackups/STSMmayor/interaction-range-2.4.9/analysis-deps'))
import pefile
import capstone

EXPECTED = '191d192710990886edcb6e2aa9d10ac69592f2a66b10fa9d53228b443ed7fd15'
source = GAME / 'weirdperformance.dll'
original = source.read_bytes()
assert hashlib.sha256(original).hexdigest() == EXPECTED, 'Unsupported DLL; do not patch'
pe = pefile.PE(data=original)
assert pe.FILE_HEADER.Machine == 0x14c
assert pe.OPTIONAL_HEADER.ImageBase == 0x10000000
assert pe.OPTIONAL_HEADER.DATA_DIRECTORY[4].Size == 0
assert not pe.get_overlay(), 'Unexpected overlay'
PATCH_RVA = 0x2304
CONTINUE_RVA = 0x230a
DONE_RVA = 0x250f
assert pe.get_data(PATCH_RVA, 14) == bytes.fromhex('8b3de026ce006689b43fe826ce00')
assert pe.get_data(DONE_RVA, 17) == bytes.fromhex('bf0100000089f88d65f45e5f5b5dc20800')
assert not any(PATCH_RVA <= e.rva < CONTINUE_RVA
               for block in pe.DIRECTORY_ENTRY_BASERELOC for e in block.entries if e.type)

def align(value, alignment):
    return (value + alignment - 1) & ~(alignment - 1)

new_rva = align(max(s.VirtualAddress + max(s.Misc_VirtualSize, s.SizeOfRawData)
                    for s in pe.sections), pe.OPTIONAL_HEADER.SectionAlignment)
raw_offset = align(len(original), pe.OPTIONAL_HEADER.FileAlignment)
code = bytearray()
listing = []

def emit(description, value):
    listing.append({'rva': hex(new_rva + len(code)), 'operation': description,
                    'bytes': value.hex(' ')})
    code.extend(value)

def jump(target):
    return b'\xe9' + struct.pack('<i', target - (new_rva + len(code) + 5))

emit('mov edi, [0x00ce26e0] ; replay displaced instruction', bytes.fromhex('8b3de026ce00'))
emit('cmp edi, 8192 ; unsigned capacity check', bytes.fromhex('81ff00200000'))
emit('jb normal ; preserve original path below capacity', bytes.fromhex('720d'))
emit('mov edi, [esp+8] ; query context already stored by original function', bytes.fromhex('8b7c2408'))
emit('mov edi, [edi] ; optional overflow/fallback flag pointer', bytes.fromhex('8b3f'))
emit('test edi, edi', bytes.fromhex('85ff'))
emit('jz done', bytes.fromhex('7408'))
emit('or byte [edi], 1 ; same overflow indication as sibling spatial path', bytes.fromhex('800f01'))
emit('jmp done ; original successful epilogue', jump(DONE_RVA))
emit('jmp normal ; original store and subsequent collision calculation', jump(CONTINUE_RVA))

# Resolve short branches explicitly so an instruction-size change cannot silently
# redirect execution. Below-capacity goes to final jump; null flag goes to done.
code[13] = len(code) - 5 - 14
code[23] = 3
listing[2]['bytes'] = code[12:14].hex(' ')
listing[6]['bytes'] = code[22:24].hex(' ')

assert len(code) == 37
section_header = pe.sections[-1].get_file_offset() + 40
assert section_header + 40 <= pe.sections[0].PointerToRawData
assert original[section_header:section_header + 40] == bytes(40)
raw_size = align(len(code), pe.OPTIONAL_HEADER.FileAlignment)
patched = bytearray(original)
patched.extend(bytes(raw_offset - len(patched) + raw_size))
patched[raw_offset:raw_offset + len(code)] = code
patched[section_header:section_header + 40] = struct.pack(
    '<8sIIIIIIHHI', b'.idxfix\0', len(code), new_rva, raw_size,
    raw_offset, 0, 0, 0, 0, 0x60000020)
struct.pack_into('<H', patched, pe.FILE_HEADER.get_field_absolute_offset('NumberOfSections'),
                 pe.FILE_HEADER.NumberOfSections + 1)
struct.pack_into('<I', patched, pe.OPTIONAL_HEADER.get_field_absolute_offset('SizeOfImage'),
                 align(new_rva + len(code), pe.OPTIONAL_HEADER.SectionAlignment))
struct.pack_into('<I', patched, pe.OPTIONAL_HEADER.get_field_absolute_offset('SizeOfCode'),
                 pe.OPTIONAL_HEADER.SizeOfCode + raw_size)
patch_offset = pe.get_offset_from_rva(PATCH_RVA)
patched[patch_offset:patch_offset + 6] = b'\xe9' + struct.pack('<i', new_rva - PATCH_RVA - 5) + b'\x90'
new_pe = pefile.PE(data=patched)
struct.pack_into('<I', patched, new_pe.OPTIONAL_HEADER.get_field_absolute_offset('CheckSum'),
                 new_pe.generate_checksum())
candidate_dir = ROOT / 'candidate'
candidate_dir.mkdir(exist_ok=True)
output = candidate_dir / 'weirdperformance.dll'
output.write_bytes(patched)
(ROOT / 'original-weirdperformance.dll').write_bytes(original)
manifest = {
    'original_sha256': EXPECTED,
    'candidate_sha256': hashlib.sha256(patched).hexdigest(),
    'patch_rva': hex(PATCH_RVA), 'stub_rva': hex(new_rva),
    'changed_original_offsets': [hex(i) for i, (a,b) in enumerate(zip(original,patched)) if a != b],
    'guard_listing': listing,
    'note': 'Candidate only; original DLL and configuration are unchanged.'
}
(ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
dis = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_32)
print('candidate', output)
print('sha256', manifest['candidate_sha256'])
for i in dis.disasm(code, pe.OPTIONAL_HEADER.ImageBase + new_rva):
    print(hex(i.address), i.mnemonic, i.op_str)
