"""Execute the real original/patched x86 collision function with synthetic data."""
import json
import pathlib
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parent
GAME = ROOT.parents[1]
sys.path[:0] = [str(ROOT / 'test-deps'),
               str(GAME / 'CodexBackups/STSMmayor/interaction-range-2.4.9/analysis-deps')]
import pefile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *

CTX = 0x20001000
OWNER = 0x20002000
MASKS = 0x20010000
GROUP = 0x20030000
VERTS = 0x20040000
OUTPUT = 0x20041000
STACK = 0x30008000
STOP = 0x00401000
COUNTER = 0x00ce26e0
BUFFER = 0x00ce26e8
VICTIM = 0x00ce6738

def u32(value):
    return struct.pack('<I', value)

def read32(uc, address):
    return struct.unpack('<I', uc.mem_read(address, 4))[0]

def make_emulator(path, base):
    pe = pefile.PE(str(path))
    pe.relocate_image(base)
    uc = Uc(UC_ARCH_X86, UC_MODE_32)
    uc.mem_map(0x00400000, 0x00a00000)
    size = (pe.OPTIONAL_HEADER.SizeOfImage + 4095) & ~4095
    uc.mem_map(base, size)
    uc.mem_write(base, pe.get_memory_mapped_image())
    uc.mem_map(0x20000000, 0x00100000)
    uc.mem_map(0x30000000, 0x00010000)
    # Real function calls this game cache lookup with five stack arguments.
    uc.mem_write(0x00693d60, b'\xb8' + u32(GROUP) + b'\xc2\x14\x00')
    uc.mem_write(0x00ca03e4, u32(1))
    uc.mem_write(CTX + 4, u32(MASKS))
    uc.mem_write(CTX + 0x10, u32(OUTPUT))
    uc.mem_write(CTX + 0x14, struct.pack('<f', 1000.0))
    uc.mem_write(CTX + 0x48, struct.pack('<f', 1.0))
    uc.mem_write(CTX + 0x4c, struct.pack('<f', 1000.0))
    uc.mem_write(CTX + 0x50, b'\x80')
    uc.mem_write(GROUP + 6, struct.pack('<H', 1))
    uc.mem_write(GROUP + 0x18a4, struct.pack('<H', 1))
    uc.mem_write(GROUP + 0x18a6, bytes(6))
    # A degenerate triangle exercises the real SSE path and exits the triangle
    # calculation without any successful intersection.
    regs = {UC_X86_REG_EBX: 0x11223344, UC_X86_REG_ESI: 0x22334455,
            UC_X86_REG_EDI: 0x33445566, UC_X86_REG_EBP: 0x44556677}
    return uc, regs

def invoke(uc, regs, base, index, owner=True):
    uc.mem_write(CTX, u32(OWNER if owner else 0))
    uc.mem_write(GROUP + 0x2206, struct.pack('<H', index))
    uc.mem_write(0x30000000, bytes(0x10000))
    uc.mem_write(STACK, u32(STOP) + bytes(8))
    uc.reg_write(UC_X86_REG_ESP, STACK)
    uc.reg_write(UC_X86_REG_ECX, CTX)
    uc.reg_write(UC_X86_REG_MXCSR, 0x1f80)
    for reg, value in regs.items():
        uc.reg_write(reg, value)
    uc.emu_start(base + 0x2130, STOP, count=100000)
    assert uc.reg_read(UC_X86_REG_EIP) == STOP
    assert uc.reg_read(UC_X86_REG_ESP) == STACK + 12
    assert uc.reg_read(UC_X86_REG_EAX) == 1
    for reg, value in regs.items():
        assert uc.reg_read(reg) == value, f'nonvolatile register {reg} changed'

original = ROOT / 'original-weirdperformance.dll'
candidate = ROOT / 'candidate/weirdperformance.dll'
results = []
for base in [0x10000000, 0x5b730000]:
    for count in [0, 1, 8190, 8191]:
        snapshots = []
        for path in [original, candidate]:
            uc, regs = make_emulator(path, base)
            uc.mem_write(COUNTER, u32(count))
            invoke(uc, regs, base, 0x1bca)
            assert read32(uc, COUNTER) == count + 1
            assert uc.mem_read(BUFFER + count * 2, 2) == b'\xca\x1b'
            snapshots.append((bytes(uc.mem_read(0x00cde648, 0x8100)),
                              bytes(uc.mem_read(CTX, 0x100)),
                              bytes(uc.mem_read(MASKS, 0x10000))))
        assert snapshots[0] == snapshots[1], 'normal path differs from original'
        results.append(f'PASS normal-path parity count={count} base={base:#x}')
    for count in [8192, 8193, 8232, 65535, 0xffffffff]:
        for owner in [True, False]:
            uc, regs = make_emulator(candidate, base)
            uc.mem_write(COUNTER, u32(count))
            uc.mem_write(VICTIM, u32(0x01234568))
            before = bytes(uc.mem_read(BUFFER, 0x4100))
            invoke(uc, regs, base, 0x1bca, owner=owner)
            assert read32(uc, COUNTER) == count
            assert bytes(uc.mem_read(BUFFER, 0x4100)) == before
            assert read32(uc, VICTIM) == 0x01234568
            assert read32(uc, OWNER) == (1 if owner else 0)
            results.append(f'PASS overflow count={count} owner={owner} base={base:#x}')
    # Reproduce the exact numeric corruption pattern found in the real dump.
    for path in [original, candidate]:
        uc, regs = make_emulator(path, base)
        uc.mem_write(COUNTER, u32((VICTIM - BUFFER) // 2))
        uc.mem_write(VICTIM, u32(0x01234568))
        invoke(uc, regs, base, 0x1bca)
        invoke(uc, regs, base, 0x1bcb)
        value = read32(uc, VICTIM)
        if path == original:
            assert value == 0x1bcb1bca
        else:
            assert value == 0x01234568
        results.append(f'PASS corruption reproduction {path.name} candidate={path==candidate} '
                       f'victim={value:#x} base={base:#x}')

old = pefile.PE(str(original))
new = pefile.PE(str(candidate))
def import_names(pe):
    return [(e.dll.decode(), [(i.name.decode() if i.name else i.ordinal) for i in e.imports])
            for e in pe.DIRECTORY_ENTRY_IMPORT]
assert import_names(old) == import_names(new)
assert old.OPTIONAL_HEADER.AddressOfEntryPoint == new.OPTIONAL_HEADER.AddressOfEntryPoint
assert new.verify_checksum()
assert new.sections[-1].Name.rstrip(b'\0') == b'.idxfix'
assert new.sections[-1].Characteristics == 0x60000020
# Existing code/data and relocations are identical outside the six-byte jump.
for sec in old.sections:
    a = bytearray(sec.get_data())
    b = bytearray(new.get_data(sec.VirtualAddress, sec.SizeOfRawData))
    if sec.VirtualAddress <= 0x2304 < sec.VirtualAddress + sec.SizeOfRawData:
        offset = 0x2304 - sec.VirtualAddress
        a[offset:offset+6] = b[offset:offset+6]
    assert a == b, f'unexpected changes to {sec.Name!r}'
results.append('PASS PE structure, checksum, imports, entry point and original-section preservation')
(ROOT / 'verification.txt').write_text('\n'.join(results) + '\n', encoding='utf-8')
print('\n'.join(results))
print(f'{len(results)} checks passed; real gameplay validation remains outstanding.')
