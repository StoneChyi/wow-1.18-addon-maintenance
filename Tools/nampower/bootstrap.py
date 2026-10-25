"""Prepare pinned source and portable Microsoft tools in an explicit E: workspace.

No installer, registry edit, global PATH change, or game deployment is performed.
Range-extracted ZIP members are HTTPS/CRC checked, not whole-package SHA checked.
"""
import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.request
import zipfile
from remote_zip import RemoteZip

HERE=Path(__file__).resolve().parent

def whole_zip(url,target,expected,output):
    if target.exists():
        data=target.read_bytes()
    else:
        with urllib.request.urlopen(url,timeout=90) as response:
            data=response.read(25*1024*1024)
        if hashlib.sha256(data).hexdigest()!=expected:
            raise ValueError('Downloaded archive hash mismatch: '+url)
        target.write_bytes(data)
    if hashlib.sha256(data).hexdigest()!=expected:
        raise ValueError('Cached archive hash mismatch: '+str(target))
    with zipfile.ZipFile(target) as archive:
        for member in archive.infolist():
            dest=(output/member.filename).resolve()
            if not dest.is_relative_to(output.resolve()):raise ValueError('Unsafe source ZIP member')
            if member.is_dir():dest.mkdir(parents=True,exist_ok=True);continue
            content=archive.read(member)
            if dest.exists() and dest.read_bytes()!=content:
                raise FileExistsError('Different original source already exists: '+str(dest))
            dest.parent.mkdir(parents=True,exist_ok=True)
            if not dest.exists():dest.write_bytes(content)
    print('SHA256 verified:',target.name,flush=True)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--workspace',type=Path,required=True)
    p.add_argument('--proxy')
    p.add_argument('--accept-msvc-license',action='store_true')
    a=p.parse_args();root=a.workspace.resolve()
    if root.drive.upper()!='E:':raise ValueError('This workflow requires an E: workspace')
    if not a.accept_msvc_license:
        p.error('Read the Microsoft license URL in build-pins.json and pass --accept-msvc-license')
    for name in ('downloads','temp','toolchain-fetch'): (root/name).mkdir(parents=True,exist_ok=True)
    os.environ['TEMP']=os.environ['TMP']=str(root/'temp')
    if a.proxy:os.environ['HTTPS_PROXY']=os.environ['HTTP_PROXY']=a.proxy
    pins=json.loads((HERE/'build-pins.json').read_text())
    jobs=[
        ('https://codeload.github.com/brues-code/nampower/zip/'+pins['source_commit'],root/'downloads/nampower-source.zip',pins['source_archive_sha256'],root/'source'),
        ('https://github.com/namreeb/hadesmem/releases/download/v1.7.0/hadesmem-v142-Release-Win32.zip',root/'downloads/hadesmem-v142-Release-Win32.zip',pins['hadesmem_archive_sha256'],root/'dependencies'),
        ('https://codeload.github.com/asmjit/asmjit/zip/f7de7b8d35c76e2a5f5792971371a9fd39e6557b',root/'downloads/asmjit-f7de7b8d35c76e2a5f5792971371a9fd39e6557b.zip','b6ead050541139368288d9bbe03e8e26ce9e47ec782ff59da25eb6a6fc958fe7',root/'dependency-source'),
        ('https://codeload.github.com/vmt/udis86/zip/0dc7184bd33b9f2866a2a95acf17b308466a1116',root/'downloads/udis86-0dc7184bd33b9f2866a2a95acf17b308466a1116.zip','d1dcd6b2c7ce19cfb377a7cae368000dd7d14d648ecbbaa3537e0a3c719567cb',root/'dependency-source')]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(lambda job:whole_zip(*job),jobs))
    records=[];portable=root/'portable'
    for package in pins['msvc']:
        print('MSVC',package['package'],flush=True)
        remote=RemoteZip(package['url']) # manifest size is not necessarily transfer size
        names=[e['name'] for e in remote.entries if e['name'].startswith('Contents/') and not e['name'].endswith('/')
               and Path(e['name']).name.lower() not in ('vctip.exe','vctip.exe.config')]
        if '.CRT.x86.Desktop.' in package['package']:
            names=[n for n in names if '/lib/x86/' in n and n.lower().endswith('.lib') and '/spectre/' not in n.lower()
                   and Path(n).name.lower() not in ('libcmtd.lib','libcpmtd.lib','libvcruntimed.lib','libconcrtd.lib','msvcrtd.lib','msvcprtd.lib','vcruntimed.lib')]
        if '.CRT.x86.Store.' in package['package']:
            names=[n for n in names if n.lower().endswith('/lib/x86/oldnames.lib')]
        r=remote.extract(names,portable,strip_prefix='Contents/',workers=8)
        r['published_package_sha256_not_verified_for_partial_fetch']=package['sha256'];records.append(r)
    for package in pins['sdk']:
        print('SDK',package['id'],flush=True)
        remote=RemoteZip(package['url'])
        names=[e['name'] for e in remote.entries if not e['name'].endswith('/')]
        if package['id'].endswith('.x86'):
            needed={'kernel32.lib','user32.lib','crypt32.lib','shlwapi.lib','advapi32.lib','ole32.lib','oleaut32.lib','version.lib','shell32.lib','ws2_32.lib','uuid.lib'}
            names=[n for n in names if n.lower().startswith('c/ucrt/x86/') or
                   (n.lower().startswith('c/um/x86/') and Path(n).name.lower() in needed)]
            target=portable/'sdk-x86'
        else:
            names=[n for n in names if re.match(r'^c/Include/[^/]+/(shared|um|ucrt)/',n)]
            target=portable/'sdk-headers'
        records.append(remote.extract(names,target,workers=8))
    remote=RemoteZip('https://archives.boost.io/release/1.80.0/source/boost_1_80_0.zip')
    names=[e['name'] for e in remote.entries if not e['name'].endswith('/') and (
        e['name'].startswith('boost_1_80_0/boost/') or
        any(e['name'].startswith('boost_1_80_0/libs/'+component+'/src/') for component in ('filesystem','program_options','system')) or
        e['name']=='boost_1_80_0/LICENSE_1_0.txt')]
    records.append(remote.extract(names,root/'dependency-source',workers=8))
    (root/'bootstrap-extraction.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
    print('Portable inputs ready on E:',root,flush=True)

if __name__=='__main__':main()
