"""Verify prepared source bindings and record all local build inputs."""
import argparse
import hashlib
import json
from pathlib import Path

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--workspace',type=Path,required=True)
parser.add_argument('--generation',default='')
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args()
workspace=args.workspace.resolve()
output=args.output.resolve()
if workspace.drive.upper()!='E:' or not output.is_relative_to(workspace):
    raise ValueError('Build input records must remain inside the E: workspace')
here=Path(__file__).resolve().parent
suffix='-'+args.generation if args.generation else ''
prepared=[]
for variant in ('original','pss'):
    folder=workspace/('prepared-'+variant+suffix)
    info=json.loads((folder/'prepared.json').read_text())
    for name,expected in info['shared_headers'].items():
        if hashlib.sha256((here/'include'/name).read_bytes()).hexdigest()!=expected:
            raise ValueError('Shared header changed after preparation: '+name)
    for path,expected in [
        (Path(info['source_directory'])/'nampower/main.cpp',info['prepared_main_sha256']),
        (Path(info['hadesmem_directory'])/'include/memory/hadesmem/detail/patcher_aux.hpp',info['prepared_patcher_sha256'])]:
        if hashlib.sha256(path.read_bytes()).hexdigest()!=expected:
            raise ValueError('Prepared source changed: '+str(path))
    prepared.append(folder)
roots=[here,workspace/'portable',workspace/'dependency-source']+prepared
entries=[]
total=hashlib.sha256()
for index,root in enumerate(roots):
    for path in sorted(root.rglob('*')):
        if not path.is_file() or '__pycache__' in path.parts:
            continue
        if not path.resolve().is_relative_to(root.resolve()):
            raise ValueError('Build input symlink escapes its root')
        relative=str(index)+'/'+path.relative_to(root).as_posix()
        digest=hashlib.sha256(path.read_bytes()).hexdigest()
        total.update(relative.encode()+b'\0'+digest.encode()+b'\n')
        entries.append({'path':relative,'sha256':digest})
record={'aggregate_sha256':total.hexdigest(),'roots':[str(p) for p in roots],
        'file_count':len(entries),'files':entries,
        'note':'Content hashes identify build inputs; timestamps/PDBs prevent a bit-identical-build claim.'}
output.write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in record.items() if k!='files'},indent=2))
