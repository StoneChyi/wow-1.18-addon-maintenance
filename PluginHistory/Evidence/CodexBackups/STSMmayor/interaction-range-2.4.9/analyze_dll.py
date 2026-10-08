from pathlib import Path
import sys,struct,json,re
work=Path(__file__).parent
sys.path.insert(0,str(work/'analysis-deps'))
import pefile,capstone
data=Path(r'E:\1.18\wsloot.dll').read_bytes()
pe=pefile.PE(data=data)
base=pe.OPTIONAL_HEADER.ImageBase
md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_32);md.detail=True
instructions=[]
for section in pe.sections:
    if section.Characteristics & 0x20000000:
        instructions.extend(md.disasm(section.get_data(),base+section.VirtualAddress))
(work/'wsloot-disassembly.txt').write_text('\n'.join(f'{i.address:08X}  {i.mnemonic:<9} {i.op_str}' for i in instructions))
strings={base+pe.get_rva_from_offset(m.start()):m.group().decode('ascii') for m in re.finditer(rb'[\x20-\x7e]{4,}',data)}
relevant={addr:s for addr,s in strings.items() if s in ['Loot','NpcTick','SetMask','GetMask','SetFilter','FilterOn','WSLoot']}
for address,s in relevant.items():
    needle=struct.pack('<I',address)
    for match in re.finditer(re.escape(needle),data):
        offset=match.start(); print(s,hex(address),'pointer at',hex(offset), data[offset:offset+12].hex(' '))
constants={}
for section in pe.sections:
    if not section.Characteristics&0x20000000:
        raw=section.get_data()
        for value in [3.0,4.0,4.5,5.0,5.5,6.0,10.0,20.0,25.0,40.0,100.0]:
            for match in re.finditer(re.escape(struct.pack('<f',value)),raw):
                constants[base+section.VirtualAddress+match.start()]=value
for n,i in enumerate(instructions):
    refs=[]
    for op in i.operands:
        if op.type==capstone.x86.X86_OP_MEM and op.mem.disp in constants:refs.append(constants[op.mem.disp])
    if refs:
        print('FLOAT',refs,'at',hex(i.address))
        print('\n'.join(f'{j.address:08X} {j.mnemonic} {j.op_str}' for j in instructions[max(0,n-6):n+7]))
