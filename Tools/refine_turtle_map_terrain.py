"""Build 0.5 terrain repairs and native indoor cities in an ignored candidate.

Read-only game data. Coordinates and ADT ownership are unchanged. Uniform land
cells are reconstructed from their materials/heights and surrounding appearance;
these are explicitly inferred scenery, never new roads, buildings or POIs.
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
from build_turtle_map_terrain import STEP, DENSITIES, chunks, parse_adt
from build_turtle_map_atlas import source_maps
from turtle_map_archive import Client

OUT = STAGING/'v6-terrain-candidate'
SEA = (0, 29, 43, 255)


def read_terrain(path):
    import sys
    sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
    from lupa.lua51 import LuaRuntime
    runtime=LuaRuntime();runtime.execute(path.read_text(encoding='utf8'))
    def convert(v):
        if not hasattr(v,'items'):return v
        return {k:convert(x) for k,x in v.items()}
    return convert(runtime.globals().TurtleSeamlessMap_Terrain)


def write_terrain(terrain):
    def arrays(v):
        if isinstance(v,dict):
            keys=set(v)
            if keys and keys==set(range(1,len(keys)+1)):return [arrays(v[k]) for k in range(1,len(keys)+1)]
            return {k:arrays(x) for k,x in v.items()}
        if isinstance(v,list):return [arrays(x) for x in v]
        return v
    write(OUT/'TerrainData.lua',('-- Native terrain, audited scenery repairs and WMO interior atlases.\nTurtleSeamlessMap_Terrain = '+lua(arrays(terrain))+'\n').encode('utf8'))


def indoor_voids(image):
    """Close narrow rendering cracks and fill enclosed unwalkable rock only.

    Snow/forest on the surface must not shine through the underground rooms.
    Exterior alpha is retained; this never adds a floor or a route.
    """
    mask=image.getchannel('A').point(lambda a:255 if a>32 else 0)
    # Connect *all* exterior components around the image, even where a hallway
    # touches an image edge. Starting a fill in just one corner invents a box.
    padded=Image.new('L',(image.width+64,image.height+64));padded.paste(mask,(32,32))
    closed=padded.filter(ImageFilter.MaxFilter(25)).filter(ImageFilter.MinFilter(25))
    exterior=closed.copy();ImageDraw.floodfill(exterior,(0,0),128)
    holes=exterior.point(lambda a:0 if a==128 else 255).crop((32,32,image.width+32,image.height+32))
    # Include only the filled enclosed footprint and existing room pixels.
    pixels=np.asarray(image);solid=pixels[pixels[:,:,3]>200,:3]
    shade=tuple(int(v*.45) for v in np.quantile(solid,.2,axis=0))
    backdrop=Image.new('RGBA',image.size,shade+(0,));backdrop.putalpha(holes)
    backdrop.alpha_composite(image)
    return backdrop,int(((np.asarray(holes)>0)&(pixels[:,:,3]<32)).sum())


def flat_cells(image):
    """Strictly uniform 16x16 land chunks; textured sand, roads and water stay."""
    # Average each DXT block first: quantization can add several levels of
    # pixel noise to an otherwise completely flat source surface.
    small = image.convert('RGB').resize((64,64),Image.Resampling.BOX)
    a = np.asarray(small, dtype=float).reshape(16,4,16,4,3).transpose(0,2,1,3,4)
    mean = a.mean(axis=(2,3))
    return ((a.std(axis=(2,3)).max(axis=2) < 1.25)
            & ~((mean[:,:,2] > mean[:,:,0]+8) & (mean[:,:,2] > mean[:,:,1]+5))
            & (mean.mean(axis=2) > 15) & (mean.mean(axis=2) < 190))


def repair_mask(image, seeds):
    """Follow flat eight-pixel margins connected to an audited flat chunk."""
    a=np.asarray(image.convert('RGB').resize((64,64),Image.Resampling.BOX),dtype=float).reshape(32,2,32,2,3).transpose(0,2,1,3,4)
    mean=a.mean(axis=(2,3))
    candidate=(a.std(axis=(2,3)).max(axis=2)<1.25)&~((mean[:,:,2]>mean[:,:,0]+8)&(mean[:,:,2]>mean[:,:,1]+5))
    seed=np.repeat(np.repeat(seeds,2,axis=0),2,axis=1)
    selected=Image.fromarray(seed.astype('uint8')*255)
    allowed=Image.fromarray((candidate|seed).astype('uint8')*255)
    for _ in range(32):
        grown=ImageChops.darker(selected.filter(ImageFilter.MaxFilter(3)),allowed)
        if grown.tobytes()==selected.tobytes():break
        selected=grown
    return selected.resize((256,256),Image.Resampling.NEAREST)


def material_cells(data):
    """Read available layers without trusting oversized *unused* MCAL lengths."""
    cells, _ = parse_adt(data)
    textures = []
    issues = []
    for tag,p in chunks(data):
        if tag == b'XETM':
            textures = [s.decode('ascii') for s in p.split(b'\0') if s]
        if tag != b'KNCM': continue
        x,y = struct.unpack_from('<II',p,4)
        for expected,field in ((b'YLCM',28),(b'LACM',36)):
            off = struct.unpack_from('<I',p,field)[0]-8
            if off < 128 or off+8 > len(p): continue
            tag,size = p[off:off+4],struct.unpack_from('<I',p,off+4)[0]
            if tag != expected: continue
            if off+8+size > len(p):
                issues.append([x,y,expected.decode('ascii'),'truncated-unused-tail'])
                size = len(p)-off-8
            cells[(x,y)]['children'][expected] = p[off+8:off+8+size]
    return cells,textures,issues


def render_repair(cells, textures, client, selected, cache):
    result = Image.new('RGB',(256,256))
    issues = []
    for cy,cx in np.argwhere(selected):
        cell = cells[(int(cx),int(cy))]
        data = cell['children']; color = None
        layers = list(struct.iter_unpack('<4I',data.get(b'YLCM',b'')))
        for i,(tid,flags,offset,_) in enumerate(layers):
            if tid >= len(textures):
                issues.append([int(cx),int(cy),'invalid-material']);continue
            name = textures[tid]
            if name not in cache:
                cache[name] = decode_blp(client.read(name)[0]).convert('RGB').resize((16,16),Image.Resampling.LANCZOS)
            texture = cache[name]
            if color is None: color = texture.copy();continue
            alpha = data.get(b'LACM',b'')[offset:offset+2048]
            if len(alpha) != 2048 or flags & 0x200:
                issues.append([int(cx),int(cy),'base-material-only']);continue
            raw = np.frombuffer(alpha,dtype=np.uint8)
            a = np.empty(4096,dtype=np.uint8);a[::2]=(raw&15)*17;a[1::2]=(raw>>4)*17
            color = Image.composite(texture,color,Image.fromarray(a.reshape(64,64)).resize((16,16),Image.Resampling.BILINEAR))
        if color is None:
            issues.append([int(cx),int(cy),'no-material-context-fill'])
            color = Image.new('RGB',(16,16),(128,128,128))
        height = np.asarray(Image.fromarray(cell['heights'].astype('float32')).resize((16,16),Image.Resampling.BICUBIC))
        gy,gx = np.gradient(height)
        rgb = np.asarray(color,dtype=float)*np.clip(1-(gx+gy)*.025,.65,1.2)[:,:,None]
        grain = np.clip(rgb/np.maximum(rgb.mean(axis=(0,1)),12),.65,1.35)
        result.paste(Image.fromarray((grain*128).astype('uint8')),(int(cx)*16,int(cy)*16))
    return result,issues


def blend_repairs(master, repair, mask):
    """Normalize replacement color to nearby valid terrain; feather only seams.

    Work on quarter-size color fields to bound memory. Native detail outside a
    three-pixel seam remains byte-identical before final atlas compression.
    """
    small = (math.ceil(master.width/4),math.ceil(master.height/4))
    src = master.convert('RGB').resize(small,Image.Resampling.BOX)
    alpha = master.getchannel('A').resize(small,Image.Resampling.BOX)
    m = mask.resize(small,Image.Resampling.BOX)
    good = ImageChops.multiply(ImageChops.invert(m),alpha)
    # Exclude deep sea from land color estimation; preserve coastal land hues.
    a = np.asarray(src)
    land = Image.fromarray(np.where((a[:,:,2]>a[:,:,0]+10)&(a[:,:,2]>a[:,:,1]+5),0,255).astype('uint8'))
    good = np.asarray(ImageChops.multiply(good,land),dtype=float)/255
    fallback = np.asarray(src,dtype=float);color=fallback.copy()
    def box_mean(a,r):
        # Float summed-area blur avoids color banding from dividing quantized
        # eight-bit weighted colors near large missing regions.
        h,w=a.shape;integral=np.pad(a.cumsum(axis=0).cumsum(axis=1),((1,0),(1,0)))
        x=np.arange(w);y=np.arange(h);l=np.maximum(0,x-r);t=np.maximum(0,y-r);right=np.minimum(w,x+r+1);bottom=np.minimum(h,y+r+1)
        return ((integral[bottom[:,None],right]-integral[t[:,None],right]-integral[bottom[:,None],l]+integral[t[:,None],l])/
                ((bottom-t)[:,None]*(right-l)))
    remaining=np.ones(good.shape,dtype=bool)
    for radius in (160,48,12):
        weights=box_mean(good,radius);remaining&=weights<.005
        confidence=np.clip((weights-.005)/.30,0,1)
        for channel in range(3):
            values=box_mean(fallback[:,:,channel]*good,radius)/np.maximum(weights,.005)
            color[:,:,channel]=color[:,:,channel]*(1-confidence)+values*confidence
    target = Image.fromarray(np.clip(color,0,255).astype('uint8')).resize(master.size,Image.Resampling.BILINEAR)
    # Keep the fine material/height variation, without importing its base tint.
    # Process bounded horizontal strips rather than allocating a float continent.
    soft = mask.filter(ImageFilter.GaussianBlur(2.5))
    result = master.copy();raw = repair.convert('RGB')
    changed = 0
    for y in range(0,master.height,256):
        box = (0,y,master.width,min(master.height,y+256))
        grain = np.clip(np.asarray(raw.crop(box),dtype=float)/128,.65,1.35)
        patch = np.clip(np.asarray(target.crop(box),dtype=float)*grain,0,255).astype('uint8')
        # Soft fringe uses native pixels rather than uninitialized repair pixels.
        core = np.asarray(mask.crop(box))>128
        patch[~core] = np.asarray(master.crop(box).convert('RGB'))[~core]
        piece = Image.composite(Image.fromarray(patch).convert('RGBA'),master.crop(box),soft.crop(box))
        result.paste(piece,box[:2]);changed += int(core.sum())
    return result,dict(repair_pixels=changed,unresolved_context_pixels=int((remaining&(np.asarray(m)>128)).sum()))


def save_pyramid(image, rect, prefix, written, densities=DENSITIES):
    levels=[]
    for density in densities:
        im=image if image.size==(round(rect[2]*density),round(rect[3]*density)) else image.resize((round(rect[2]*density),round(rect[3]*density)),Image.Resampling.LANCZOS)
        cols,rows=math.ceil(im.width/254),math.ceil(im.height/254);present={};alpha=im.getchannel('A')
        for row in range(rows):
            for col in range(cols):
                x,y=col*254,row*254
                if not alpha.crop((x,y,x+254,y+254)).getbbox():continue
                tile=im.crop((x-1,y-1,x+255,y+255));name=f'{prefix}_{density}_{col}_{row}.blp';payload=encode_blp(tile)
                write(OUT/'Art'/name,payload);written.append(dict(file=name,sha256=hashlib.sha256(payload).hexdigest()));present[row*cols+col+1]=True
        levels.append(dict(density=density,cols=cols,rows=rows,tiles=present,prefix=f'{prefix}_{density}'))
    return dict(rect=rect,levels=levels)


def native_city(client, refs, mid, model, placement, transform, written):
    root,archive=client.read(model);groups=list(struct.iter_unpack('<I6fi',dict(chunks(root))[b'IGOM']))
    lo=np.array([min(r[1] for r in groups),min(r[2] for r in groups)])
    hi=np.array([max(r[4] for r in groups),max(r[5] for r in groups)])
    v=placement;angle=math.radians(90-v[6])
    matrix=np.array([[math.cos(angle),math.sin(angle)],[math.sin(angle),-math.cos(angle)]])
    corners=np.array([[x,y] for x in (lo[0],hi[0]) for y in (lo[1],hi[1])])@matrix.T+np.array([v[2],v[4]])
    actual=np.concatenate((corners.min(axis=0),corners.max(axis=0)))
    error=float(np.max(abs(actual-np.array([v[8],v[10],v[11],v[13]]))))
    if error>.01:raise ValueError('WMO placement bounding boxes disagree')
    local=Image.new('RGBA',(math.ceil((hi[0]-lo[0])*2),math.ceil((hi[1]-lo[1])*2)))
    prefix=model[6:-4].lower();sources=[];selected=[]
    for i in sorted(range(len(groups)),key=lambda i:groups[i][6],reverse=True):
        g=groups[i]
        # Undercity's surface ruins are a separate layer; show underground rooms.
        if mid==382 and g[3]>-30:continue
        for logical,hashed in refs.items():
            if not logical.startswith(prefix+f'_{i:03d}_'):continue
            match=re.search(r'_(\d+)_(\d+)\.blp$',logical);tx,ty=map(int,match.groups())
            data,origin=client.read('Textures\\Minimap\\'+hashed)
            im=decode_blp(data).convert('RGBA').transpose(Image.Transpose.FLIP_TOP_BOTTOM)
            local.alpha_composite(im,(round((g[1]-lo[0])*2)+tx*256,round((g[2]-lo[1])*2)+ty*256))
            sources.append(dict(logical=logical,sha256=hashlib.sha256(data).hexdigest(),source=origin));selected.append(i)
    local,void_pixels=indoor_voids(local)
    local.save(OUT/f'city-{mid}-local.png')
    low=corners.min(axis=0);high=corners.max(axis=0);scale=transform['scale']
    left=transform['x']+(low[0]-32*STEP)*scale;top=transform['y']+(low[1]-32*STEP)*scale
    rect=[left,top,(high[0]-low[0])*scale,(high[1]-low[1])*scale]
    size=(math.ceil(rect[2]*64),math.ceil(rect[3]*64))
    # Output world pixel -> local minimap pixel, including native Y inversion.
    inv=matrix.T
    origin=(low-np.array([v[2],v[4]]))@inv.T-lo
    coefficients=(inv[0,0]*2/(64*scale),inv[0,1]*2/(64*scale),origin[0]*2,
                  inv[1,0]*2/(64*scale),inv[1,1]*2/(64*scale),origin[1]*2)
    image=local.transform(size,Image.Transform.AFFINE,coefficients,Image.Resampling.BICUBIC)
    image.save(OUT/f'city-{mid}-world.png')
    scene=save_pyramid(image,rect,f'v6_city{mid}',written,(8,16,32,64))
    return scene,dict(id=mid,model=model,source=archive,root_sha256=hashlib.sha256(root).hexdigest(),placement=list(v),placement_error_yards=error,groups=sorted(set(selected)),sources=sources,rect=rect,occluded_rock_pixels=void_pixels,limitation='Native pre-rendered groups, lower floors win where projections overlap; surface ruins excluded in Undercity. Enclosed transparent rock gaps use a dark native-color backing, not new walkable space.')


def city_placements(client):
    """Read unique WMO placements near the original DBC city bounds."""
    found={}
    for mid,word in ((341,'ironforge.wmo'),(382,'undercity.wmo')):
        b=next(m for m in source_maps() if m['id']==mid)['bounds']
        cx=math.floor(32-(b[0]+b[1])/2/STEP);cy=math.floor(32-(b[2]+b[3])/2/STEP)
        matches={}
        for tx in range(cx-2,cx+3):
            for ty in range(cy-2,cy+3):
                path=f'World\\Maps\\Azeroth\\Azeroth_{tx}_{ty}.adt'
                try:data=dict(chunks(client.read(path)[0]))
                except FileNotFoundError:continue
                names=data.get(b'OMWM',b'');offsets=[v[0] for v in struct.iter_unpack('<I',data.get(b'DIWM',b''))]
                for row in struct.iter_unpack('<II12f4H',data.get(b'FDOM',b'')):
                    start=offsets[row[0]];name=names[start:names.index(b'\0',start)].decode('ascii')
                    if name.lower().endswith(word):matches[row[1]]=dict(path=name,placement=row,adt=path)
        if len(matches)!=1:raise ValueError(f'Expected one unique city WMO: {mid}, got {len(matches)}')
        found[mid]=next(iter(matches.values()))
    return found


def build():
    (OUT/'Art').mkdir(parents=True,exist_ok=True)
    client=Client(ROOT,include_terrain=True,include_wmo=True)
    old=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.4.0地形资源-20261024.json').read_text(encoding='utf8'))
    transforms=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json').read_text(encoding='utf8'))['transforms']
    refs={}
    for line in client.read('Textures\\Minimap\\md5translate.trs')[0].decode('utf8',errors='replace').splitlines():
        p=line.split()
        if len(p)>=2:
            key=p[0].lower();refs[key]=p[1]
            # Native index mixes map25_09 and map25_9 spellings.
            match=re.fullmatch(r'(azeroth|kalimdor)\\map(\d+)_(\d+)\.blp',key)
            if match:refs[f'{match[1]}\\map{int(match[2])}_{int(match[3])}.blp']=p[1]
    written=[];continents=[];audit=[];stats=Counter();cache={};checks=[]
    try:
        for cid,name in ((1,'Kalimdor'),(0,'Azeroth')):
            rect=next(c['rect'] for c in old['continents'] if c['id']==cid);left,top,width,height=rect
            master=Image.new('RGBA',(width*16,height*16));repair=Image.new('RGB',master.size);mask=Image.new('L',master.size)
            t=transforms[str(cid)];step=STEP*t['scale']
            valid=[]
            for tag,p in chunks(client.read(f'World\\Maps\\{name}\\{name}.wdt')[0]):
                if tag==b'NIAM':valid=[(i%64,i//64) for i,(flags,_) in enumerate(struct.iter_unpack('<II',p)) if flags&1]
            for tx,ty in valid:
                wx=t['x']+(tx-32)*step;wy=t['y']+(ty-32)*step
                if wx+step<=left or wy+step<=top or wx>=left+width or wy>=top+height:continue
                adt,origin=client.read(f'World\\Maps\\{name}\\{name}_{tx}_{ty}.adt');cells,_=parse_adt(adt)
                stats['adt_tiles_audited']+=1;stats['terrain_chunks_audited']+=len(cells)
                reference=refs.get(f'{name}\\map{tx}_{ty}.blp'.lower());selected=np.zeros((16,16),bool)
                if reference:
                    raw,source=client.read('Textures\\Minimap\\'+reference);image=decode_blp(raw).convert('RGBA');stats['native_tiles_audited']+=1
                    selected=flat_cells(image)
                    for (cx,cy),cell in cells.items():
                        if cell['water'] and cell['maximum']<=cell['water_level']:selected[cy,cx]=False
                    if selected.any():
                        pixel_mask=repair_mask(image,selected)
                        # Render every touched chunk, including partial margins.
                        selected=np.asarray(pixel_mask).reshape(16,16,16,16).transpose(0,2,1,3).max(axis=(2,3))>0
                        material,textures,issues=material_cells(adt)
                        fill,extra=render_repair(material,textures,client,selected,cache)
                        audit.append(dict(continent=name,x=tx,y=ty,flat_chunks=int(selected.sum()),cells=[[int(x),int(y)] for y,x in np.argwhere(selected)],issues=issues+extra,source=source,sha256=hashlib.sha256(raw).hexdigest(),adt_sha256=hashlib.sha256(adt).hexdigest()))
                        stats['repaired_tiles']+=1;stats['repaired_chunks']+=int(selected.sum())
                elif all(c['water'] and c['maximum']<=c['water_level'] for c in cells.values()):
                    image=Image.new('RGBA',(256,256),SEA);stats['verified_water_tiles']+=1
                else:
                    from build_turtle_map_terrain import render_missing
                    material,textures,_=material_cells(adt);image=render_missing(material,textures,client);stats['existing_material_fallbacks']+=1
                x,y=round((wx-left)*16),round((wy-top)*16);right,bottom=round((wx+step-left)*16),round((wy+step-top)*16);size=(right-x,bottom-y)
                master.paste(image.resize(size,Image.Resampling.LANCZOS),(x,y))
                if selected.any():
                    repair.paste(fill.resize(size,Image.Resampling.LANCZOS),(x,y))
                    mask.paste(pixel_mask.resize(size,Image.Resampling.NEAREST),(x,y))
            before=master.copy()
            master,quality=blend_repairs(master,repair,mask)
            # No invented off-map land: soften outer absence into matching water.
            alpha=master.getchannel('A');fade=alpha.filter(ImageFilter.GaussianBlur(8));master.putalpha(ImageChops.darker(alpha,fade))
            master.save(OUT/f'{name}-terrain.png');mask.save(OUT/f'{name}-repair-mask.png')
            before.save(OUT/f'{name}-before.png')
            check=dict(continent=name,**quality)
            # Verify unchanged RGB outside the explicitly bounded repair seam.
            outside=ImageChops.invert(mask.filter(ImageFilter.MaxFilter(11)))
            diff=ImageChops.multiply(ImageChops.difference(before.convert('RGB'),master.convert('RGB')),Image.merge('RGB',(outside,outside,outside)))
            check['outside_repair_max_delta']=max(v[1] for v in diff.getextrema());checks.append(check)
            scene=save_pyramid(master,rect,f'v6_t{cid}',written);scene['id']=cid;continents.append(scene)
            print('Refined',name,dict(stats),check,flush=True)
            del before,master,repair,mask,diff,outside
        cities={};city_audit=[]
        placements=city_placements(client)
        for mid in (341,382):
            p=placements[mid];scene,info=native_city(client,refs,mid,p['path'],p['placement'],transforms['0'],written);cities[mid]=scene;info['placement_adt']=p['adt'];city_audit.append(info)
        # A single native deep-water sample is intentionally uniform. There are
        # no repeated parchment illustrations or invented islands at high zoom.
        sea=Image.new('RGBA',(1002,668),SEA)
        ocean=save_pyramid(sea,[0,0,1002,668],'v6_sea',written,(1,))
        terrain=read_terrain(ADDON/'TerrainData.lua')
        terrain['continents']=continents;terrain['cities']=cities;terrain['ocean']=dict(rect=ocean['rect'],level=ocean['levels'][0]);terrain['revision']=6
        write_terrain(terrain)
        report=dict(version='0.5.0',counts=dict(stats),repairs=audit,checks=checks,cities=city_audit,continents=continents,files=written,total_files=len(written),total_bytes=sum((OUT/'Art'/r['file']).stat().st_size for r in written),ocean_rgba=SEA,unresolved=[],repair_limit='Only detected uniform land cells: material/height detail with nearby color normalization. Inferred transition scenery is not surveyed geography; no roads/buildings/POIs are fabricated.')
        json_write(OUT/'manifest.json',report)
        print('Candidate complete',report['total_files'],report['total_bytes'],flush=True)
    finally:
        for archive in client.archives:archive.close()


def deploy():
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'));assert not report['unresolved']
    expected={r['file'] for r in report['files']};art=(ADDON/'Art').resolve()
    assert art== (ROOT/'Interface/AddOns/TurtleSeamlessMap/Art').resolve()
    for row in report['files']:
        name=row['file'];assert re.fullmatch(r'v6_(?:t[01]|city(?:341|382)|sea)_\d+_\d+_\d+\.blp',name)
        raw=(OUT/'Art'/name).read_bytes();assert hashlib.sha256(raw).hexdigest()==row['sha256'];assert decode_blp(raw).size==(256,256)
    for name in expected:shutil.copyfile(OUT/'Art'/name,art/name)
    for pattern in ('v5_t*.blp','v6_*.blp'):
        for p in art.glob(pattern):
            if p.name not in expected:
                assert p.resolve().parent==art;p.unlink()
    shutil.copyfile(OUT/'TerrainData.lua',ADDON/'TerrainData.lua')
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.5.0地形资源-20261024.json',report)
    print('Deployed',len(expected),'v6 assets; v4 art and v5 classic overview retained')


def refresh_cities():
    """Refine native interiors without recompressing unchanged continents."""
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'))
    transforms=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.2.0*.json')).read_text(encoding='utf8'))['transforms']
    client=Client(ROOT,include_terrain=True,include_wmo=True)
    try:
        refs={}
        for line in client.read('Textures\\Minimap\\md5translate.trs')[0].decode('utf8',errors='replace').splitlines():
            p=line.split()
            if len(p)>=2:refs[p[0].lower()]=p[1]
        written=[r for r in report['files'] if not r['file'].startswith('v6_city')]
        scenes={};audit=[]
        for mid,p in city_placements(client).items():
            scene,info=native_city(client,refs,mid,p['path'],p['placement'],transforms['0'],written)
            scenes[mid]=scene;info['placement_adt']=p['adt'];audit.append(info)
        terrain=read_terrain(OUT/'TerrainData.lua');terrain['cities']=scenes;write_terrain(terrain)
        report.update(cities=audit,files=written,total_files=len(written),total_bytes=sum((OUT/'Art'/r['file']).stat().st_size for r in written))
        json_write(OUT/'manifest.json',report)
        print('Updated native indoor candidate',[(r['id'],r['occluded_rock_pixels']) for r in audit],flush=True)
    finally:
        for archive in client.archives:archive.close()


def audit_candidate():
    """Measure every in-scope horizontal/vertical ADT join, without blurring
    genuine biome changes merely to make a numeric seam score smaller."""
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'))
    transforms=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.2.0*.json')).read_text(encoding='utf8'))['transforms']
    client=Client(ROOT,include_terrain=True);joins=[]
    try:
        for scene,name in zip(report['continents'],('Kalimdor','Azeroth')):
            rect=scene['rect'];t=transforms[str(scene['id'])];step=STEP*t['scale']
            before=Image.open(OUT/f'{name}-before.png').convert('RGB');after=Image.open(OUT/f'{name}-terrain.png').convert('RGB')
            valid={}
            for tag,p in chunks(client.read(f'World\\Maps\\{name}\\{name}.wdt')[0]):
                if tag!=b'NIAM':continue
                for i,(flags,_) in enumerate(struct.iter_unpack('<II',p)):
                    tx,ty=i%64,i//64;wx=t['x']+(tx-32)*step;wy=t['y']+(ty-32)*step
                    if flags&1 and wx+step>rect[0] and wy+step>rect[1] and wx<rect[0]+rect[2] and wy<rect[1]+rect[3]:
                        valid[(tx,ty)]=(round((wx-rect[0])*16),round((wy-rect[1])*16),round((wx+step-rect[0])*16),round((wy+step-rect[1])*16))
            for (tx,ty),(x,y,r,b) in valid.items():
                for dx,dy in ((1,0),(0,1)):
                    if (tx+dx,ty+dy) not in valid:continue
                    box=(r-1,max(0,y),r+1,min(after.height,b)) if dx else (max(0,x),b-1,min(after.width,r),b+1)
                    if box[0]<0 or box[1]<0 or box[2]>after.width or box[3]>after.height or box[2]<=box[0] or box[3]<=box[1]:continue
                    values=[]
                    for image in (before,after):
                        pixels=np.asarray(image.crop(box),dtype=float)
                        delta=pixels[:,0]-pixels[:,1] if dx else pixels[0]-pixels[1]
                        values.append(round(float(abs(delta).mean()),4))
                    joins.append(dict(continent=name,x=tx,y=ty,direction='east' if dx else 'south',before=values[0],after=values[1]))
        report['join_audit']=dict(count=len(joins),joins=joins,limit='Numeric audit of every adjacent in-scope ADT seam. Natural biome/coast changes are preserved; this does not certify visual correctness in game.')
        report['material_issues']=dict(Counter(str(issue[-1]) for repair in report['repairs'] for issue in repair['issues']))
        json_write(OUT/'manifest.json',report)
        print('Audited adjacent ADT seams:',len(joins),'material issues:',report['material_issues'],flush=True)
    finally:
        for archive in client.archives:archive.close()


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--deploy-reviewed',action='store_true');parser.add_argument('--audit-candidate',action='store_true');parser.add_argument('--refresh-cities',action='store_true');args=parser.parse_args()
    if args.deploy_reviewed:deploy()
    elif args.audit_candidate:audit_candidate()
    elif args.refresh_cities:refresh_cities()
    else:build();audit_candidate()
