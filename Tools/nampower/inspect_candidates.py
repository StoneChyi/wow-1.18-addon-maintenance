"""Static PE/ABI and scoped source checks; does not load candidate DLLs."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

def inspect(path):
    b=path.read_bytes()
    u16=lambda o:struct.unpack_from('<H',b,o)[0]
    u32=lambda o:struct.unpack_from('<I',b,o)[0]
    pe=u32(0x3c); opt=pe+24; dd=opt+96
    if b[pe:pe+4]!=b'PE\0\0' or u16(opt)!=0x10b:
        raise ValueError('Expected PE32 DLL: '+str(path))
    sections=[]
    for i in range(u16(pe+6)):
        o=opt+u16(pe+20)+40*i
        virtual_size,rva,raw_size,raw=struct.unpack_from('<IIII',b,o+8)
        sections.append((rva,max(virtual_size,raw_size),raw))
    def offset(rva):
        for start,size,raw in sections:
            if start<=rva<start+size:return raw+rva-start
        return rva
    def string(o):return b[o:b.index(b'\0',o)].decode('ascii')
    imports={}
    o=offset(u32(dd+8))
    while any(b[o:o+20]):
        original,_,_,name,iat=struct.unpack_from('<IIIII',b,o)
        functions=[];table=offset(original or iat);i=0
        while u32(table+4*i):
            value=u32(table+4*i)
            functions.append('#'+str(value&0xffff) if value&0x80000000 else string(offset(value)+2));i+=1
        imports[string(offset(name))]=functions;o+=20
    exports=[]
    export=u32(dd)
    if export:
        o=offset(export)
        names,addresses=u32(o+24),u32(o+32)
        exports=[string(offset(u32(offset(addresses)+4*i))) for i in range(names)]
    return {'path':str(path),'size':len(b),'sha256':hashlib.sha256(b).hexdigest(),
            'machine':u16(pe+4),'dll':bool(u16(pe+22)&0x2000),
            'imports':imports,'exports':exports,
            'maintenance_marker':b'[MaintenanceSummary]' in b,
            'dynamic_pss_name':b'PssCaptureSnapshot' in b}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace',type=Path,required=True)
    parser.add_argument('--generation',default='r2')
    parser.add_argument('--installed',type=Path,default=Path('E:/1.18/nampower.dll'))
    parser.add_argument('--output',type=Path,required=True)
    a=parser.parse_args();w=a.workspace
    current=inspect(a.installed)
    original=inspect(w/'artifacts/original/nampower.dll');candidate=inspect(w/'artifacts/pss/nampower.dll')
    assert current['sha256']=='1fe36ff8a421393116e6b58d801fa4dced35db59f1457136a79fce247142d4ec', 'Installed DLL changed'
    for entry in (original,candidate):
        assert entry['machine']==0x14c and entry['dll']
        assert entry['exports']==current['exports'], 'Export ABI changed'
        assert entry['maintenance_marker']
        assert not any('vcruntime' in d.lower() or 'msvcp' in d.lower() for d in entry['imports']), 'New VC runtime DLL dependency'
        assert not any(f.startswith('Pss') for funcs in entry['imports'].values() for f in funcs), 'PSS must remain dynamically resolved'
    assert candidate['dynamic_pss_name']
    suffix='-'+a.generation if a.generation else ''
    base=w/'source/nampower-2c7f51cd436e9b0ce88271e84ce5a77c19f2c23b/nampower'
    changed={}
    hook_sequences={}
    for variant in ('original','pss'):
        info=json.loads((w/('prepared-'+variant+suffix)/'prepared.json').read_text())
        source=Path(info['source_directory'])/'nampower'
        differences=[]
        for path in sorted(base.iterdir()):
            if path.is_file() and path.read_bytes()!=(source/path.name).read_bytes():differences.append(path.name)
        assert differences==['main.cpp'], differences
        text=(source/'main.cpp').read_text(encoding='utf-8-sig')
        init=text[text.index('    void initHooks()'):text.index('    void SysMsgInitializeHook')]
        hook_sequences[variant]=re.findall(r'Offsets::\w+',init)
        assert len(hook_sequences[variant])==59
        changed[variant]=differences
    assert hook_sequences['original']==hook_sequences['pss']
    base_text=(base/'main.cpp').read_text(encoding='utf-8-sig')
    base_init=base_text[base_text.index('    void initHooks()'):base_text.index('    void SysMsgInitializeHook')]
    assert re.findall(r'Offsets::\w+',base_init)==hook_sequences['pss']
    report={'ok':True,'installed':current,'original':original,'candidate':candidate,
            'changed_source_files':changed,'hook_count':59,'hook_order_unchanged':True,
            'limits':'Static ABI/source checks and standalone verification are not game acceptance.'}
    a.output.write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps({'ok':True,'installed_sha256':current['sha256'],
        'candidate_sha256':candidate['sha256'],'candidate_size':candidate['size'],
        'exports':candidate['exports'],'imports':list(candidate['imports']),
        'hook_count':59,'hook_order_unchanged':True},indent=2))

if __name__=='__main__':main()
