"""Prepare native terrain + ADT ownership in an ignored candidate, then deploy.

No game archive is modified. Top-down fallback is explicitly limited to missing
minimap cells: terrain textures/heights/water, without invented model geometry.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
import re
import shutil
import struct

import numpy as np
from PIL import Image, ImageChops, ImageFilter, ImageDraw
from build_turtle_seamless_map import ROOT, ADDON, STAGING, decode_blp, encode_blp, lua, write, json_write
from turtle_map_archive import Client, dbc, dbc_string
from build_turtle_map_atlas import source_maps

OUT=STAGING/'v5-terrain-candidate'
STEP=1600/3
DENSITIES=(1,2,4,8,16)


def chunks(data,start=0):
    off=start
    while off+8<=len(data):
        size=struct.unpack_from('<I',data,off+4)[0]
        if off+8+size>len(data):raise ValueError('Truncated terrain chunk')
        yield data[off:off+4],data[off+8:off+8+size]
        off+=8+size


def parse_adt(data,materials=False):
    cells={};textures=[]
    for tag,p in chunks(data):
        if tag==b'XETM':textures=[s.decode('ascii') for s in p.split(b'\0') if s]
        if tag!=b'KNCM':continue
        x,y=struct.unpack_from('<II',p,4)
        if x>15 or y>15 or len(p)<128:raise ValueError('Invalid terrain cell')
        # Legacy MCNR has 13 padding bytes outside its declared chunk length.
        # Follow MCNK's offsets (relative to its tag, 8 bytes before p), not a
        # linear child walk which would interpret that padding as a chunk.
        children={}
        for expected,field in ((b'TVCM',20),(b'YLCM',28),(b'LACM',36),(b'QLCM',96)):
            if not materials and expected in (b'YLCM',b'LACM'):continue
            offset=struct.unpack_from('<I',p,field)[0]-8
            if offset<128 or offset+8>len(p):continue
            tag=p[offset:offset+4];size=struct.unpack_from('<I',p,offset+4)[0]
            if expected==b'QLCM':
                # Vanilla ocean MCLQ can declare zero locally; the MCNK header
                # carries its real total length. The client reads that length.
                size=max(size,max(0,struct.unpack_from('<I',p,100)[0]-8))
            if tag!=expected or offset+8+size>len(p):
                if expected==b'QLCM' and not (struct.unpack_from('<I',p,0)[0]&28):continue
                raise ValueError(f'Invalid terrain child offset {expected!r} at {offset}: {tag!r}, cell {x},{y}')
            children[tag]=p[offset+8:offset+8+size]
        z=struct.unpack_from('<f',p,112)[0]
        vertices=np.array(struct.unpack('<145f',children[b'TVCM']),dtype=float)+z
        outer=np.array([vertices[row*17:row*17+9] for row in range(9)])
        area=struct.unpack_from('<I',p,52)[0]
        water=children.get(b'QLCM')
        level=struct.unpack_from('<2f',water)[1] if water and len(water)>=8 else 0
        cells[(x,y)]=dict(area=area,heights=outer,maximum=float(vertices.max()),minimum=float(vertices.min()),water=bool(water) and len(water)>=8,water_level=level,children=children)
    if len(cells)!=256:raise ValueError('Incomplete ADT ownership grid')
    return cells,textures


def render_missing(cells,textures,client):
    image=Image.new('RGBA',(256,256),(0,29,43,0));cache={}
    for (cx,cy),cell in cells.items():
        if cell['maximum']<=cell['water_level'] and cell['water']:continue
        data=cell['children'];layers=list(struct.iter_unpack('<4I',data.get(b'YLCM',b'')))
        color=Image.new('RGB',(16,16),(99,99,81))
        for i,(texture_id,flags,offset,_) in enumerate(layers):
            if texture_id>=len(textures):raise ValueError('Bad terrain material id')
            name=textures[texture_id]
            if name not in cache:cache[name]=decode_blp(client.read(name)[0]).convert('RGB').resize((16,16),Image.Resampling.LANCZOS)
            texture=cache[name]
            if i==0:color=texture.copy();continue
            alpha=data.get(b'LACM',b'')[offset:offset+2048]
            if len(alpha)!=2048 or flags&0x200:raise ValueError('Unsupported fallback alpha encoding')
            raw=np.frombuffer(alpha,dtype=np.uint8)
            a=np.empty(4096,dtype=np.uint8);a[::2]=(raw&15)*17;a[1::2]=(raw>>4)*17
            mask=Image.fromarray(a.reshape(64,64)).resize((16,16),Image.Resampling.BILINEAR)
            color=Image.composite(texture,color,mask)
        heights=np.asarray(Image.fromarray(cell['heights'].astype('float32')).resize((16,16),Image.Resampling.BICUBIC))
        gy,gx=np.gradient(heights)
        shade=np.clip(1-(gx+gy)*.025,.65,1.2)
        rgb=np.clip(np.asarray(color,dtype=float)*shade[:,:,None],0,255).astype('uint8')
        alpha=np.where(heights>cell['water_level'],255,0).astype('uint8') if cell['water'] else np.full((16,16),255,dtype='uint8')
        rgba=Image.fromarray(np.dstack((rgb,alpha)))
        image.paste(rgba,(cx*16,cy*16))
    return image


def rle(values):
    result=[];previous=values[0]
    for i,value in enumerate(values[1:],1):
        if value!=previous:result.append(f'{i:03x}{previous:03x}');previous=value
    result.append(f'{len(values):03x}{previous:03x}')
    return ''.join(result)


def area_aliases(rows,strings,maps):
    by_area={m['area']:m['id'] for m in maps if m['kind']=='surface'}
    aliases={}
    for row in rows:
        if row[0] in by_area:
            for offset in row[11:19]:
                name=dbc_string(strings,offset)
                if name:aliases[name]=by_area[row[0]]
    return aliases


def build():
    (OUT/'Art').mkdir(parents=True,exist_ok=True)
    client=Client(ROOT,include_terrain=True);maps=source_maps()
    old=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.3.0资源-20261024.json').read_text(encoding='utf-8'))
    layout=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json').read_text(encoding='utf-8'))['transforms']
    rows,strings,_=dbc(client.read('DBFilesClient\\AreaTable.dbc')[0]);parents={r[0]:r[2] for r in rows}
    names={r[0]:dbc_string(strings,r[15]) or dbc_string(strings,r[11]) for r in rows}
    by_area={m['area']:m['id'] for m in maps if m['kind']=='surface'}
    def resolve(area):
        seen=set()
        while area and area not in seen:
            if area in by_area:return by_area[area]
            seen.add(area);area=parents.get(area,0)
        return 0
    trs,origin=client.read('Textures\\Minimap\\md5translate.trs');refs={}
    for line in trs.decode('utf-8',errors='replace').splitlines():
        match=re.match(r'(Azeroth|Kalimdor)\\map(\d+)_(\d+)\.blp\s+(\S+)',line,re.I)
        if match:refs[(match[1].lower(),int(match[2]),int(match[3]))]=match[4]
    written=[];sources=[];territories={};continents=[];missing=[];labels={};counts=Counter()
    def save(image,prefix,density):
        cols,rows=math.ceil(image.width/254),math.ceil(image.height/254);present={};alpha=image.getchannel('A')
        for row in range(rows):
            for col in range(cols):
                x,y=col*254,row*254
                if not alpha.crop((x,y,x+254,y+254)).getbbox():continue
                tile=image.crop((x-1,y-1,x+255,y+255));name=f'{prefix}_{col}_{row}.blp'
                payload=encode_blp(tile);write(OUT/'Art'/name,payload)
                written.append(dict(file=name,sha256=hashlib.sha256(payload).hexdigest()));present[row*cols+col+1]=True
        return dict(density=density,cols=cols,rows=rows,tiles=present,prefix=prefix)
    try:
        for continent_id,continent in ((1,'Kalimdor'),(0,'Azeroth')):
            extent=next(c['rect'] for c in old['continents'] if c['id']==continent_id)
            left,top,width,height=extent;t=layout[str(continent_id)];step=STEP*t['scale']
            master=Image.new('RGBA',(width*16,height*16));ownership={};acc={}
            wdt,wdt_source=client.read(f'World\\Maps\\{continent}\\{continent}.wdt')
            valid=[]
            for tag,p in chunks(wdt):
                if tag==b'NIAM':valid=[(i%64,i//64) for i,(flags,_) in enumerate(struct.iter_unpack('<II',p)) if flags&1]
            for index,(tx,ty) in enumerate(valid):
                wx=t['x']+(tx-32)*step;wy=t['y']+(ty-32)*step
                if wx+step<=left or wy+step<=top or wx>=left+width or wy>=top+height:continue
                path=f'World\\Maps\\{continent}\\{continent}_{tx}_{ty}.adt'
                adt,adt_source=client.read(path)
                try:cells,textures=parse_adt(adt)
                except ValueError as error:raise ValueError(path+': '+str(error)) from error
                zone_ids=[resolve(cells[(x,y)]['area']) for y in range(16) for x in range(16)]
                ownership[ty*64+tx+1]=rle(zone_ids)
                key=(continent.lower(),tx,ty);source=refs.get(key);classification='minimap'
                if source:
                    data,archive=client.read('Textures\\Minimap\\'+source);image=decode_blp(data).convert('RGBA')
                    rgb=np.asarray(image,dtype=np.int16)
                    deep=(rgb[:,:,0]<15)&(rgb[:,:,1]<48)&(rgb[:,:,2]<70)&(rgb[:,:,2]>rgb[:,:,1]+6)&(rgb[:,:,1]>rgb[:,:,0]+6)
                    a=Image.fromarray(np.where(deep,0,255).astype('uint8')).filter(ImageFilter.GaussianBlur(.6))
                    checksum=hashlib.sha256(data).hexdigest()
                elif all(c['water'] and c['maximum']<=c['water_level'] for c in cells.values()):
                    classification='verified-water';counts[classification]+=1;continue
                else:
                    classification='terrain-material-fallback';archive=adt_source;checksum=hashlib.sha256(adt).hexdigest()
                    try:
                        material_cells,textures=parse_adt(adt,materials=True)
                        image=render_missing(material_cells,textures,client)
                    except (ValueError,FileNotFoundError) as error:
                        missing.append(dict(continent=continent,x=tx,y=ty,error=str(error)));continue
                    image.save(OUT/f'fallback-{continent}-{tx}-{ty}.png')
                counts[classification]+=1
                sources.append(dict(continent=continent,x=tx,y=ty,kind=classification,source=archive,sha256=checksum,adt_sha256=hashlib.sha256(adt).hexdigest()))
                alpha=np.asarray(a) if source else np.asarray(image.getchannel('A'))
                for cy in range(16):
                    for cx in range(16):
                        zone=zone_ids[cy*16+cx]
                        if zone and alpha[cy*16:cy*16+16,cx*16:cx*16+16].mean()>128:
                            values=acc.setdefault(zone,[0,0,0]);values[0]+=wx+(cx+.5)/16*step;values[1]+=wy+(cy+.5)/16*step;values[2]+=1
                x=round((wx-left)*16);y=round((wy-top)*16)
                right=round((wx+step-left)*16);bottom=round((wy+step-top)*16)
                stamp=image.resize((right-x,bottom-y),Image.Resampling.LANCZOS)
                # Paste rather than alpha-composite: each geographic cell has
                # exactly one source, independent of region/page draw priority.
                master.paste(stamp,(x,y))
                if index%150==0:print(continent,'terrain cell',index,'/',len(valid),flush=True)
            # Remove ONLY ocean connected to the exterior. Inland lakes and
            # dark forest shadows remain their native pixels, not paper holes.
            rgba=np.asarray(master)
            deep=(rgba[:,:,0]<15)&(rgba[:,:,1]<48)&(rgba[:,:,2]<70)&(rgba[:,:,2]>rgba[:,:,1])&(rgba[:,:,1]>rgba[:,:,0])
            water=Image.fromarray(np.where(deep|(rgba[:,:,3]==0),255,0).astype('uint8'))
            water=water.resize((width*4,height*4),Image.Resampling.BOX).point(lambda p:255 if p>200 else 0)
            ImageDraw.floodfill(water,(0,0),128)
            remove=water.point(lambda p:255 if p==128 else 0).resize(master.size,Image.Resampling.BILINEAR)
            master.putalpha(ImageChops.subtract(master.getchannel('A'),remove))
            del rgba,deep,water,remove
            master.save(OUT/f'{continent}-terrain.png')
            thumb=master.copy();thumb.thumbnail((1100,1600));thumb.save(OUT/f'{continent}-preview.png')
            levels=[save(master if d==16 else master.resize((width*d,height*d),Image.Resampling.LANCZOS),f'v5_t{continent_id}_{d}',d) for d in DENSITIES]
            continents.append(dict(id=continent_id,rect=extent,levels=levels))
            territories[continent_id]=dict(step=step,x=t['x'],y=t['y'],tiles=ownership)
            for zone,(x,y,n) in acc.items():labels[zone]=[x/n,y/n]
            print('Completed terrain continent',continent_id,flush=True)
        classic=Image.open(STAGING/'previews/World.png').convert('RGBA')
        classic_data=dict(rect=[0,0,1002,668],level=save(classic,'v5_classic',1))
        terrain=dict(version=1,continents=continents,classic=classic_data,territory=territories,labels=labels,aliases=area_aliases(rows,strings,maps))
        write(OUT/'TerrainData.lua',('-- Native terrain grid + ADT AreaID ownership; no painted territory masks.\nTurtleSeamlessMap_Terrain = '+lua(terrain)+'\n').encode('utf-8'))
        report=dict(version='0.4.0',counts=dict(counts),files=written,sources=sources,unresolved=missing,labels=labels,territory_tiles={k:len(v['tiles']) for k,v in territories.items()},continents=continents,total_files=len(written),total_bytes=sum((OUT/'Art'/r['file']).stat().st_size for r in written),index_source=origin,area_table_sha256=hashlib.sha256(client.read('DBFilesClient\\AreaTable.dbc')[0]).hexdigest(),fallback_limit='Terrain materials, vertex heights and water only; no WMO/M2 rendering for unindexed cells')
        json_write(OUT/'manifest.json',report)
        if missing:raise RuntimeError('Unresolved land cells; candidate must not be deployed')
        print('Terrain candidate complete',len(written),report['total_bytes'],dict(counts),flush=True)
    finally:
        for archive in client.archives:archive.close()


def deploy():
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'));assert not report['unresolved']
    for r in report['files']:
        assert re.fullmatch(r'v5_(?:t[01]_\d+|classic)_\d+_\d+\.blp',r['file'])
        data=(OUT/'Art'/r['file']).read_bytes();assert hashlib.sha256(data).hexdigest()==r['sha256']
        assert decode_blp(data).size==(256,256)
    expected={r['file'] for r in report['files']};art=(ADDON/'Art').resolve()
    candidate_art=(OUT/'Art').resolve()
    assert candidate_art.is_relative_to(STAGING.resolve())
    for path in candidate_art.glob('v5_*.blp'):
        if path.name not in expected:
            assert path.resolve().parent==candidate_art;path.unlink()
    assert art.is_relative_to((ROOT/'Interface/AddOns/TurtleSeamlessMap').resolve())
    for name in expected:shutil.copyfile(OUT/'Art'/name,art/name)
    for path in art.glob('v5_*.blp'):
        if path.name not in expected:
            assert path.resolve().parent==art;path.unlink()
    text=(OUT/'TerrainData.lua').read_text(encoding='utf-8')
    # Also support an already generated candidate from this same migration.
    if '["aliases"]=' not in text:
        client=Client(ROOT)
        try:
            rows,strings,_=dbc(client.read('DBFilesClient\\AreaTable.dbc')[0])
            text+='TurtleSeamlessMap_Terrain.aliases = '+lua(area_aliases(rows,strings,source_maps()))+'\n'
        finally:
            for archive in client.archives:archive.close()
    write(ADDON/'TerrainData.lua',text.encode('utf-8'))
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.4.0地形资源-20261024.json',report)
    print('Deployed terrain candidate',len(expected),'new files; v4 hand-drawn art preserved')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--deploy-reviewed',action='store_true');args=parser.parse_args()
    if args.deploy_reviewed:deploy()
    else:build()
