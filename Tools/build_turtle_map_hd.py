"""0.6 map candidates: real material detail, coherent scenery and finer atlases.

All client files are read-only. Generated textures and temporary geometry remain
in ignored staging; only reviewed map art and manifests are deployed.
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
from PIL import Image,ImageChops,ImageFilter
from build_turtle_seamless_map import ROOT,ADDON,STAGING,decode_blp,encode_blp,lua,write,json_write
from build_turtle_map_terrain import STEP,chunks,parse_adt
from refine_turtle_map_terrain import material_cells,flat_cells,repair_mask,read_terrain,indoor_voids,blend_repairs,save_pyramid
from turtle_map_archive import Client
from turtle_map_scenery import Scenery,placements,rasterize

OUT=STAGING/'v7-hd-candidate'
SEA=(0,29,43,255)
Image.MAX_IMAGE_PIXELS=400000000  # Only locally generated, known-size atlases.


class Ground:
    def __init__(self,client):self.client=client;self.cache={};self.sources={};self.counts=Counter();self.unavailable=Counter()

    def texture(self,name,size):
        key=(name,size)
        if key not in self.cache:
            try:data,archive=self.client.read(name)
            except FileNotFoundError:
                self.unavailable[name]+=1;return None
            image=decode_blp(data).convert('RGB')
            self.sources[name]=dict(source=archive,sha256=hashlib.sha256(data).hexdigest())
            # Retain real source material structure. Four map-symbol repetitions
            # per chunk provide legible grain without inventing a landmark.
            small=image.resize((size//4,size//4),Image.Resampling.LANCZOS)
            tiled=Image.new('RGB',(size,size))
            for y in range(4):
                for x in range(4):tiled.paste(small,(x*small.width,y*small.height))
            self.cache[key]=tiled
        return self.cache[key]

    def tile(self,data,resolution=512,reference=None,pure=False):
        cells,textures,issues=material_cells(data);self.counts['tiles']+=1
        if issues:self.counts['unused_alpha_tails']+=len(issues)
        size=resolution//16;image=Image.new('RGB',(resolution,resolution));depth=np.empty((resolution,resolution),dtype='<f4')
        for (x,y),cell in cells.items():
            layers=list(struct.iter_unpack('<4I',cell['children'].get(b'YLCM',b'')));color=None
            for i,(tid,flags,offset,_) in enumerate(layers):
                if tid>=len(textures):raise ValueError('Invalid HD terrain texture index')
                tex=self.texture(textures[tid],size)
                if tex is None:
                    self.counts['native_texture_fallback_cells']+=1
                    if reference is not None:
                        tex=reference.convert('RGB').crop((x*16,y*16,(x+1)*16,(y+1)*16)).resize((size,size),Image.Resampling.LANCZOS)
                    elif color is not None:continue
                    else:tex=Image.new('RGB',(size,size),(95,85,65))
                if color is None:color=tex.copy();continue
                raw=cell['children'].get(b'LACM',b'')[offset:offset+2048]
                if len(raw)!=2048 or flags&0x200:raise ValueError('Unsupported HD alpha')
                raw=np.frombuffer(raw,dtype='u1');alpha=np.empty(4096,dtype='u1');alpha[::2]=(raw&15)*17;alpha[1::2]=(raw>>4)*17
                a=alpha.reshape(64,64).copy()
                # Legacy 63-sample alpha fields duplicate their last row/column.
                a[-1]=a[-2];a[:,-1]=a[:,-2]
                mask=Image.fromarray(a).resize((size,size),Image.Resampling.BILINEAR)
                color=Image.composite(tex,color,mask)
            if color is None:color=Image.new('RGB',(size,size),(95,85,65));self.counts['no_material_cells']+=1
            h=np.asarray(Image.fromarray(cell['heights'].astype('float32')).resize((size,size),Image.Resampling.BILINEAR))
            gy,gx=np.gradient(h);shade=np.clip(1-(gx+gy)*size/32*.025,.6,1.25)
            rgb=np.clip(np.asarray(color,dtype=float)*shade[:,:,None],0,255).astype('uint8')
            image.paste(Image.fromarray(rgb),(x*size,y*size));depth[y*size:(y+1)*size,x*size:(x+1)*size]=h
        if reference is not None and not pure:
            ref=reference.convert('RGB').resize(image.size,Image.Resampling.LANCZOS)
            broad=image.filter(ImageFilter.GaussianBlur(1.6))
            ratio=np.clip(np.asarray(image,dtype=float)/np.maximum(np.asarray(broad,dtype=float),12),.65,1.40)
            image=Image.fromarray(np.clip(np.asarray(ref,dtype=float)*ratio,0,255).astype('uint8'))
        rgb=np.asarray(image).copy()
        water_reference=np.asarray(reference.convert('RGB').resize(image.size,Image.Resampling.LANCZOS)) if reference is not None else None
        for (x,y),cell in cells.items():
            h=depth[y*size:(y+1)*size,x*size:(x+1)*size]
            if cell['water']:
                wet=h<=cell['water_level']
                sample=rgb[y*size:(y+1)*size,x*size:(x+1)*size]
                if water_reference is not None:
                    ref=water_reference[y*size:(y+1)*size,x*size:(x+1)*size]
                    sample[wet]=ref[wet]
                else:sample[wet]=SEA[:3]
                h[wet]=cell['water_level']
        for tag,p in chunks(data):
            if tag!=b'KNCM':continue
            x,y=struct.unpack_from('<II',p,4);holes=struct.unpack_from('<H',p,60)[0]
            if not holes:continue
            for hy in range(4):
                for hx in range(4):
                    if holes&(1<<(hy*4+hx)):
                        depth[y*size+hy*size//4:y*size+(hy+1)*size//4,x*size+hx*size//4:x*size+(hx+1)*size//4]=-10000
        return Image.fromarray(rgb).convert('RGBA'),depth


def minimap_index(client):
    refs={}
    for line in client.read('Textures\\Minimap\\md5translate.trs')[0].decode('utf8',errors='replace').splitlines():
        match=re.match(r'(Azeroth|Kalimdor)\\map(\d+)_(\d+)\.blp\s+(\S+)',line,re.I)
        if match:refs[(match[1].lower(),int(match[2]),int(match[3]))]=match[4]
    return refs


def region(client,ground,scenery,name,bounds,resolution,label,pure=False):
    """One engine-coordinate canvas crosses every ADT border only once."""
    tx0,ty0,tx1,ty1=bounds;size=((tx1-tx0)*resolution,(ty1-ty0)*resolution)
    canvas=Image.new('RGBA',size,SEA);height=np.full((size[1],size[0]),-10000,dtype='<f4');objects=[];adt_sources=[]
    refs=minimap_index(client)
    for ty in range(ty0,ty1):
        for tx in range(tx0,tx1):
            path=f'World\\Maps\\{name}\\{name}_{tx}_{ty}.adt'
            try:data,archive=client.read(path)
            except FileNotFoundError:continue
            reference=None
            if (name.lower(),tx,ty) in refs:reference=decode_blp(client.read('Textures\\Minimap\\'+refs[(name.lower(),tx,ty)])[0])
            tile,depth=ground.tile(data,resolution,reference,pure);objects.extend(placements(data))
            canvas.paste(tile,((tx-tx0)*resolution,(ty-ty0)*resolution));height[(ty-ty0)*resolution:(ty-ty0+1)*resolution,(tx-tx0)*resolution:(tx-tx0+1)*resolution]=depth
            adt_sources.append(dict(path=path,source=archive,sha256=hashlib.sha256(data).hexdigest()))
        print('Region',label,'row',ty,flush=True)
    path=OUT/(label+'.job');output=scenery.job(path,canvas,height,objects,[tx0*STEP,ty0*STEP,tx1*STEP,ty1*STEP])
    rasterize([path]);result=Image.frombytes('RGBA',size,output.read_bytes())
    if not pure:
        # Anchor the diffuse-only renderer to native luminance. Preserve model
        # edges and source hues; this is not a full client lighting simulation.
        wanted=canvas.convert('L').filter(ImageFilter.GaussianBlur(10));actual=result.convert('L').filter(ImageFilter.GaussianBlur(10))
        for y in range(0,size[1],256):
            box=(0,y,size[0],min(size[1],y+256));piece=result.crop(box)
            gain=np.clip(np.asarray(wanted.crop(box),dtype=float)/np.maximum(np.asarray(actual.crop(box),dtype=float),16),.70,1.15)
            rgb=Image.fromarray(np.clip(np.asarray(piece.convert('RGB'),dtype=float)*gain[:,:,None],0,255).astype('uint8')).convert('RGBA');rgb.putalpha(piece.getchannel('A'));result.paste(rgb,box[:2])
    result.save(OUT/(label+'.png'))
    json_write(OUT/(label+'-sources.json'),dict(adt=adt_sources,ground=ground.sources,models=scenery.sources,counts=dict(scenery.counts),errors=scenery.errors))
    return result


def probe(label):
    OUT.mkdir(parents=True,exist_ok=True);client=Client(ROOT,True,True,True)
    try:
        g=Ground(client);s=Scenery(client)
        if label=='aq':region(client,g,s,'Kalimdor',(26,43,33,53),512,'aq',True)
        elif label=='stormwind':
            from build_turtle_map_atlas import source_maps
            b=next(m for m in source_maps() if m['id']==301)['bounds']
            bounds=(math.floor(32-max(b[:2])/STEP),math.floor(32-max(b[2:])/STEP),math.ceil(32-min(b[:2])/STEP),math.ceil(32-min(b[2:])/STEP))
            print('City tiles',bounds,flush=True);region(client,g,s,'Azeroth',bounds,768,'stormwind')
        print('Models',dict(s.counts),'issues',s.errors,flush=True)
    finally:
        for archive in client.archives:archive.close()


def flat_margin(image):
    small=np.asarray(image.convert('RGB').resize((64,64),Image.Resampling.BOX),dtype=float)
    a=small.reshape(16,4,16,4,3).transpose(0,2,1,3,4);mean=a.mean(axis=(2,3))
    seed=(a.std(axis=(2,3)).max(axis=2)<2.5)&~((mean[:,:,2]>mean[:,:,0]+8)&(mean[:,:,2]>mean[:,:,1]+5))&(mean.mean(axis=2)>15)&(mean.mean(axis=2)<210)
    return repair_mask(image,seed),seed


def spectral_margin(image):
    """Detect smooth, low-detail gradients as well as perfectly flat chunks.

    A broad shaded placeholder can have a large standard deviation but almost
    no local structure. Landmarks/roads generally have stronger local residuals.
    """
    small=image.convert('RGB').resize((64,64),Image.Resampling.BOX)
    a=np.asarray(small,dtype=float);residual=a-np.asarray(small.filter(ImageFilter.GaussianBlur(1.0)),dtype=float)
    field=a.reshape(16,4,16,4,3).transpose(0,2,1,3,4)
    high=residual.reshape(16,4,16,4,3).transpose(0,2,1,3,4)
    mean=field.mean(axis=(2,3));spread=field.std(axis=(2,3)).max(axis=2)
    energy=np.sqrt((high*high).mean(axis=(2,3))).max(axis=2)
    seed=((spread<2.5)|((energy<2.1)&(spread<12)))&~((mean[:,:,2]>mean[:,:,0]+8)&(mean[:,:,2]>mean[:,:,1]+5))&(mean.mean(axis=2)>15)&(mean.mean(axis=2)<210)
    return seed


def refine_boundaries():
    """Replace low-detail gradients with context-matched rock/soil texture.

    Relief grain is explicitly decorative, not surveyed height. Native roads,
    city frames and the registered AQ join are protected; coordinates never move.
    """
    import refine_turtle_map_terrain as legacy
    legacy.OUT=OUT
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'));client=Client(ROOT,True)
    refs=minimap_index(client);g=Ground(client);new_files=[r for r in report['files'] if not r['file'].startswith('v7_t')];scenes=[];audit=[]
    from PIL import ImageDraw
    from build_turtle_map_atlas import source_maps
    maps=source_maps();transforms=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.2.0*.json')).read_text(encoding='utf8'))['transforms']
    try:
        for scene,name in zip(report['continents'],('Kalimdor','Azeroth')):
            cid=scene['id'];left,top,width,height=rect=scene['rect'];t=transforms[str(cid)];step=STEP*t['scale']
            before=Image.open(OUT/f'{name}-before.png').convert('RGBA');mask=Image.new('L',before.size);grain=Image.new('RGB',before.size,(128,128,128));count=0;roads=0
            for source in (s for s in report['sources'] if s['continent']==name):
                tx,ty=source['x'],source['y'];ref=refs.get((name.lower(),tx,ty))
                if not ref:continue
                native=decode_blp(client.read('Textures\\Minimap\\'+ref)[0]).convert('RGBA');seed=spectral_margin(native)
                if not seed.any():continue
                data=client.read(f'World\\Maps\\{name}\\{name}_{tx}_{ty}.adt')[0];cells,textures,_=material_cells(data)
                for (x,y),cell in cells.items():
                    layers=list(struct.iter_unpack('<4I',cell['children'].get(b'YLCM',b'')))
                    protected=any(tid<len(textures) and re.search(r'road|path|cobble|brick|street',textures[tid],re.I) for tid,_,_,_ in layers)
                    if protected and seed[y,x]:roads+=1;seed[y,x]=False
                    if cell['water'] and cell['maximum']<=cell['water_level']:seed[y,x]=False
                if not seed.any():continue
                m=repair_mask(native,seed)
                # Keep road protection after margin propagation, too.
                draw=ImageDraw.Draw(m)
                for (x,y),cell in cells.items():
                    layers=list(struct.iter_unpack('<4I',cell['children'].get(b'YLCM',b'')))
                    if any(tid<len(textures) and re.search(r'road|path|cobble|brick|street',textures[tid],re.I) for tid,_,_,_ in layers):draw.rectangle((x*16,y*16,x*16+15,y*16+15),fill=0)
                choices=[n for n in textures if re.search(r'rock|cliff|stone|sand|grass|snow',n,re.I) and not re.search(r'road|path|brick',n,re.I)]
                candidates=[]
                for tex in choices:
                    image=g.texture(tex,64)
                    if image is not None:
                        a=np.asarray(image,dtype=float);candidates.append((float(a.std(axis=(0,1)).mean()/max(a.mean(),12)),image))
                if candidates:
                    tile=max(candidates,key=lambda item:item[0])[1]
                    a=np.asarray(tile,dtype=float);lum=a.mean(axis=2);pattern=np.clip(lum/max(float(lum.mean()),12),.65,1.35)
                    p=Image.fromarray(np.repeat((pattern*128).astype('uint8')[:,:,None],3,axis=2)).resize((256,256),Image.Resampling.LANCZOS)
                else:
                    p=Image.open(OUT/'ground'/f'{cid}-{tx}-{ty}.png').convert('RGB').resize((256,256),Image.Resampling.LANCZOS)
                    a=np.asarray(p,dtype=float);p=Image.fromarray((np.clip(a/np.maximum(a.mean(axis=(0,1)),12),.65,1.35)*128).astype('uint8'))
                wx=t['x']+(tx-32)*step;wy=t['y']+(ty-32)*step;x,y=round((wx-left)*16),round((wy-top)*16);r,b=round((wx+step-left)*16),round((wy+step-top)*16)
                mask.paste(m.resize((r-x,b-y),Image.Resampling.NEAREST),(x,y));grain.paste(p.resize((r-x,b-y),Image.Resampling.LANCZOS),(x,y));count+=1
            # Protect all seven original city coordinate frames and the gate
            # reconstruction. Do not repaint a landmark as inferred scenery.
            draw=ImageDraw.Draw(mask)
            protected=[m['rect'] for m in maps if m.get('city') and m['map']==cid]
            if cid==1:protected.append([150,495,45,30])
            for r in protected:draw.rectangle((round((r[0]-left)*16),round((r[1]-top)*16),round((r[0]+r[2]-left)*16),round((r[1]+r[3]-top)*16)),fill=0)
            mask.save(OUT/f'{name}-spectral-mask.png')
            # A coherent multi-scale texture modulation prevents a tiled flat
            # appearance. This is decoration in missing-detail areas only.
            rng=np.random.default_rng(0x112+cid);shade=np.zeros((height*4,width*4),dtype=float)
            for spacing,weight in ((12,.12),(4,.08),(1,.035)):
                noise=Image.fromarray(rng.integers(0,256,(math.ceil(height/spacing)+1,math.ceil(width/spacing)+1),dtype='uint8')).resize((width*4,height*4),Image.Resampling.BICUBIC)
                values=np.asarray(noise,dtype=float)/255;gy,gx=np.gradient(values);shade+=(values-.5)*weight+(gx+gy)*weight*4
            shade=Image.fromarray(np.clip((1+shade)*128,80,180).astype('uint8')).resize(before.size,Image.Resampling.BILINEAR)
            grain=ImageChops.multiply(grain,Image.merge('RGB',(shade,shade,shade))).point(lambda value:min(255,value*2))
            corrected,quality=blend_repairs(before,grain,mask);del grain,before,shade
            master=Image.open(OUT/f'{name}-terrain.png').convert('RGBA');output=master.copy();soft=mask.filter(ImageFilter.GaussianBlur(2));del mask
            for y in range(0,master.height,256):
                bottom=min(master.height,y+256);box=(0,max(0,y-12),master.width,min(master.height,bottom+12))
                old=master.crop(box);fine=np.asarray(old.convert('RGB'),dtype=float)/np.maximum(np.asarray(old.convert('RGB').filter(ImageFilter.GaussianBlur(3)),dtype=float),12)
                fine=np.clip(fine,.75,1.30)
                region=(0,box[1]/2,width*16,box[3]/2)
                base=corrected.resize(old.size,Image.Resampling.BILINEAR,box=region)
                rgb=Image.fromarray(np.clip(np.asarray(base.convert('RGB'),dtype=float)*fine,0,255).astype('uint8')).convert('RGBA');rgb.putalpha(old.getchannel('A'))
                alpha=soft.resize(old.size,Image.Resampling.BILINEAR,box=region)
                changed=Image.composite(rgb,old,alpha).crop((0,y-box[1],master.width,bottom-box[1]));output.paste(changed,(0,y))
            del master;master=output
            master.save(OUT/f'{name}-terrain.png',compress_level=3)
            current=save_pyramid(master,rect,f'v7_t{cid}',new_files,(1,2,4,8,16,32));current['id']=cid;scenes.append(current)
            preview=master.copy();preview.thumbnail((1100,1600));preview.save(OUT/f'{name}-preview.png')
            audit.append(dict(continent=name,refined_tiles=count,protected_road_chunks=roads,decorative_seed=0x112+cid,**quality));del master,corrected,soft
            print('Spectral boundary refinement',name,count,quality,flush=True)
        report.update(files=new_files,continents=scenes,total_files=len(new_files),total_bytes=sum((OUT/'Art'/r['file']).stat().st_size for r in new_files),spectral_refinement=audit)
        json_write(OUT/'manifest.json',report);terrain=read_terrain(OUT/'TerrainData.lua');terrain['continents']=scenes;legacy.write_terrain(terrain)
    finally:
        for archive in client.archives:archive.close()


def model_region(client,ground,name,map_id,label,resolution=768):
    from build_turtle_map_atlas import source_maps
    m=next(m for m in source_maps() if m['id']==map_id);b=m['bounds']
    bounds=(math.floor(32-max(b[:2])/STEP),math.floor(32-max(b[2:])/STEP),math.ceil(32-min(b[:2])/STEP),math.ceil(32-min(b[2:])/STEP))
    s=Scenery(client,skip_foliage=True);image=region(client,ground,s,name,bounds,resolution,label)
    return image,bounds,dict(id=map_id,adt_bounds=bounds,resolution=resolution,model_counts=dict(s.counts),model_errors=s.errors,sources=s.sources)


def feather(image,pixels):
    alpha=Image.new('L',image.size)
    from PIL import ImageDraw
    ImageDraw.Draw(alpha).rectangle((pixels,pixels,image.width-pixels-1,image.height-pixels-1),fill=255)
    image.putalpha(ImageChops.multiply(image.getchannel('A'),alpha.filter(ImageFilter.GaussianBlur(pixels/2))))
    return image


def build():
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'Art').mkdir(exist_ok=True);(OUT/'ground').mkdir(exist_ok=True)
    import refine_turtle_map_terrain as legacy
    legacy.OUT=OUT
    # Save helper is shared, while prefixes/reports keep the old release intact.
    client=Client(ROOT,True,True,True);g=Ground(client);terrain=read_terrain(ADDON/'TerrainData.lua')
    transforms=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.2.0*.json')).read_text(encoding='utf8'))['transforms']
    refs=minimap_index(client);written=[];scenes=[];sources=[];repairs=[];checks=[];stats=Counter()
    city_reports=[]
    try:
        for cid,name in ((1,'Kalimdor'),(0,'Azeroth')):
            old=next(c for c in terrain['continents'].values() if c['id']==cid)
            rect=[old['rect'][i] for i in range(1,5)];left,top,width,height=rect;t=transforms[str(cid)];step=STEP*t['scale']
            base=Image.new('RGBA',(width*16,height*16));repair=Image.new('RGB',base.size);mask=Image.new('L',base.size);records=[]
            for tag,p in chunks(client.read(f'World\\Maps\\{name}\\{name}.wdt')[0]):
                if tag==b'NIAM':valid=[(i%64,i//64) for i,(flags,_) in enumerate(struct.iter_unpack('<II',p)) if flags&1]
            for tx,ty in valid:
                wx=t['x']+(tx-32)*step;wy=t['y']+(ty-32)*step
                if wx+step<=left or wy+step<=top or wx>=left+width or wy>=top+height:continue
                path=f'World\\Maps\\{name}\\{name}_{tx}_{ty}.adt';data,archive=client.read(path);cells,_=parse_adt(data)
                key=(name.lower(),tx,ty);ref=refs.get(key);stats['adt_tiles_audited']+=1;stats['terrain_chunks_audited']+=len(cells)
                source=dict(continent=name,x=tx,y=ty,adt_sha256=hashlib.sha256(data).hexdigest(),adt_source=archive)
                detail=None
                if ref:
                    raw,origin=client.read('Textures\\Minimap\\'+ref);native=decode_blp(raw).convert('RGBA');stats['native_tiles']+=1
                    source.update(minimap_sha256=hashlib.sha256(raw).hexdigest(),minimap_source=origin)
                    detail,_=g.tile(data,512,native,True)
                    detail.save(OUT/'ground'/f'{cid}-{tx}-{ty}.png')
                    m,seed=flat_margin(native)
                    if seed.any():
                        # Ground materials supply fine texture, not duplicated
                        # landmarks cut out of a neighbouring map image.
                        values=np.asarray(detail.convert('RGB'),dtype=float)
                        smooth=np.asarray(detail.convert('RGB').filter(ImageFilter.GaussianBlur(4)),dtype=float)
                        grain=np.clip(values/np.maximum(smooth,12),.65,1.35)
                        pattern=Image.fromarray((grain*128).astype('uint8'))
                        repairs.append(dict(continent=name,x=tx,y=ty,seed_chunks=int(seed.sum())))
                        stats['repair_tiles']+=1;stats['seed_chunks']+=int(seed.sum())
                elif all(c['water'] and c['maximum']<=c['water_level'] for c in cells.values()):
                    native=Image.new('RGBA',(256,256),SEA);stats['verified_water_tiles']+=1
                else:
                    detail,_=g.tile(data,512,None,True);native=detail.resize((256,256),Image.Resampling.LANCZOS)
                    detail.save(OUT/'ground'/f'{cid}-{tx}-{ty}.png');stats['material_fallback_tiles']+=1
                x,y=round((wx-left)*16),round((wy-top)*16);r,b=round((wx+step-left)*16),round((wy+step-top)*16)
                base.paste(native.resize((r-x,b-y),Image.Resampling.LANCZOS),(x,y))
                if ref and seed.any():
                    mask.paste(m.resize((r-x,b-y),Image.Resampling.NEAREST),(x,y));repair.paste(pattern.resize((r-x,b-y),Image.Resampling.LANCZOS),(x,y))
                records.append((tx,ty,wx,wy,detail is not None));sources.append(source)
                if stats['adt_tiles_audited']%100==0:print('HD ground',name,stats['adt_tiles_audited'],flush=True)
            base.save(OUT/f'{name}-before.png');base,quality=blend_repairs(base,repair,mask);checks.append(dict(continent=name,**quality))
            mask.save(OUT/f'{name}-repair-mask.png');del repair,mask
            master=base.resize((width*32,height*32),Image.Resampling.LANCZOS);del base
            for tx,ty,wx,wy,has_detail in records:
                if not has_detail:continue
                x,y=round((wx-left)*32),round((wy-top)*32);r,b=round((wx+step-left)*32),round((wy+step-top)*32)
                # Clip edge ADTs before accessing a master crop; no out-of-range
                # game data can grow the committed map extent.
                detail=Image.open(OUT/'ground'/f'{cid}-{tx}-{ty}.png').convert('RGB').resize((r-x,b-y),Image.Resampling.LANCZOS)
                fine=np.asarray(detail,dtype=float);broad=np.asarray(detail.filter(ImageFilter.GaussianBlur(1.3)),dtype=float)
                ratio=np.clip(fine/np.maximum(broad,12),.78,1.28)
                original=master.crop((x,y,r,b));rgb=np.clip(np.asarray(original.convert('RGB'),dtype=float)*ratio,0,255).astype('uint8')
                piece=Image.fromarray(rgb).convert('RGBA');piece.putalpha(original.getchannel('A'));master.paste(piece,(x,y))
            # Rebuild the gate join as one coordinate-registered drawing. Preserve
            # the existing southern courtyard depiction outside this repair band.
            if cid==1:
                s=Scenery(client);aq=region(client,g,s,name,(26,43,33,53),512,'aq-join',True)
                aqrect=[t['x']+(26-32)*step,t['y']+(43-32)*step,7*step,10*step]
                patch=[150,495,45,30];box=(round((patch[0]-aqrect[0])/aqrect[2]*aq.width),round((patch[1]-aqrect[1])/aqrect[3]*aq.height),round((patch[0]+patch[2]-aqrect[0])/aqrect[2]*aq.width),round((patch[1]+patch[3]-aqrect[1])/aqrect[3]*aq.height))
                image=aq.crop(box).resize((round(patch[2]*32),round(patch[3]*32)),Image.Resampling.LANCZOS);feather(image,64)
                master.alpha_composite(image,(round((patch[0]-left)*32),round((patch[1]-top)*32)))
                city_reports.append(dict(id='silithus-aq-join',rect=patch,models=dict(s.counts),errors=s.errors,sources=s.sources,limit='Only the join band is reconstructed. The southern native courtyard depiction is retained. Static scenery, not animation or full client lighting.'))
            # Preserve the matching deep sea at the finite terrain coverage edge.
            alpha=master.getchannel('A');master.putalpha(ImageChops.darker(alpha,alpha.filter(ImageFilter.GaussianBlur(12))))
            master.save(OUT/f'{name}-terrain.png',compress_level=3)
            scene=save_pyramid(master,rect,f'v7_t{cid}',written,(1,2,4,8,16,32));scene['id']=cid;scenes.append(scene)
            preview=master.copy();preview.thumbnail((1100,1600));preview.save(OUT/f'{name}-preview.png');del master
            print('HD continent completed',name,'files',len(written),flush=True)
        # High-density surface-city geometry is drawn at 768 pixels per ADT,
        # separate from the world overview and with the original city coordinates.
        from build_turtle_map_atlas import source_maps
        cities={}
        for m in [m for m in source_maps() if m.get('city') and m['id'] not in (341,382)]:
            cid=m['map'];name='Kalimdor' if cid==1 else 'Azeroth';t=transforms[str(cid)];step=STEP*t['scale']
            image,bounds,info=model_region(client,g,name,m['id'],f'city-{m["id"]}')
            rect=m['rect'];world=[t['x']+(bounds[0]-32)*step,t['y']+(bounds[1]-32)*step,(bounds[2]-bounds[0])*step,(bounds[3]-bounds[1])*step]
            box=(round((rect[0]-world[0])/world[2]*image.width),round((rect[1]-world[1])/world[3]*image.height),round((rect[0]+rect[2]-world[0])/world[2]*image.width),round((rect[1]+rect[3]-world[1])/world[3]*image.height))
            image=image.crop(box);feather(image,40);image.save(OUT/f'city-{m["id"]}-world.png')
            cities[m['id']]=save_pyramid(image,rect,f'v7_city{m["id"]}',written,(8,16,32,64));info['rect']=rect;city_reports.append(info)
        # Reproject original room pixels directly at 96 density; do not upscale
        # the previous 64-density atlas. Native room art is ~2 pixels per yard.
        logical={}
        for line in client.read('Textures\\Minimap\\md5translate.trs')[0].decode('utf8',errors='replace').splitlines():
            p=line.split()
            if len(p)>=2:logical[p[0].lower()]=p[1]
        old_out=legacy.OUT;legacy.OUT=OUT/'native-interiors';(legacy.OUT/'Art').mkdir(parents=True,exist_ok=True)
        for mid,p in legacy.city_placements(client).items():
            ignored=[];scene,info=legacy.native_city(client,logical,mid,p['path'],p['placement'],transforms['0'],ignored)
            local=Image.open(legacy.OUT/f'city-{mid}-local.png').convert('RGBA');v=p['placement'];root=dict(chunks(client.read(p['path'])[0]));groups=list(struct.iter_unpack('<I6fi',root[b'IGOM']))
            lo=np.array([min(r[1] for r in groups),min(r[2] for r in groups)]);hi=np.array([max(r[4] for r in groups),max(r[5] for r in groups)])
            matrix=np.asarray(__import__('turtle_map_scenery').placement_matrix(v[5:8]))[:2,:2];corners=np.array([[x,y] for x in (lo[0],hi[0]) for y in (lo[1],hi[1])])@matrix.T+np.array([v[2],v[4]])
            low=corners.min(axis=0);scale=transforms['0']['scale'];inv=matrix.T;origin=(low-np.array([v[2],v[4]]))@inv.T-lo
            coef=(inv[0,0]*2/(96*scale),inv[0,1]*2/(96*scale),origin[0]*2,inv[1,0]*2/(96*scale),inv[1,1]*2/(96*scale),origin[1]*2)
            rect=scene['rect'];image=local.transform((math.ceil(rect[2]*96),math.ceil(rect[3]*96)),Image.Transform.AFFINE,coef,Image.Resampling.BICUBIC)
            image.save(OUT/f'city-{mid}-world.png');legacy.OUT=old_out
            cities[mid]=save_pyramid(image,rect,f'v7_city{mid}',written,(16,32,96));info['mode']='native indoor pixels, direct 96-density projection';city_reports.append(info)
            legacy.OUT=OUT/'native-interiors'
        legacy.OUT=old_out
        terrain['continents']=scenes;terrain['cities']=cities;terrain['revision']=7;legacy.write_terrain(terrain)
        report=dict(version='0.6.0',counts=dict(stats),repairs=repairs,checks=checks,sources=sources,material_sources=g.sources,material_fallbacks=dict(g.unavailable),ground_counts=dict(g.counts),cities=city_reports,continents=scenes,files=written,total_files=len(written),total_bytes=sum((OUT/'Art'/r['file']).stat().st_size for r in written),unresolved=[],limitations='World surface density 16 -> 32 with real material detail. Five surface cities use static model geometry at up to 64 density; two interiors use original room pixels at 96. Fine details absent from source art, animated bones/particles, translucent effects and WMO-contained doodads are not reconstructed. Missing scenery retains native background, listed separately.')
        json_write(OUT/'manifest.json',report);print('HD candidate complete',len(written),report['total_bytes'],dict(stats),flush=True)
    finally:
        for archive in client.archives:archive.close()


def deploy():
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'));art=(ADDON/'Art').resolve()
    assert art==(ROOT/'Interface/AddOns/TurtleSeamlessMap/Art').resolve()
    assert art.is_relative_to(ROOT.resolve()) and not report['unresolved']
    audit=report['quality_audit']
    assert audit['files_checked']==report['total_files']
    assert audit['courtyard_before_sha256']==audit['courtyard_after_sha256']
    assert audit['map_data_sha256']==hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest()
    expected={r['file'] for r in report['files']}
    for r in report['files']:
        assert re.fullmatch(r'v7_(?:t[01]|city(?:301|321|341|362|381|382|509))_\d+_\d+_\d+\.blp',r['file'])
        raw=(OUT/'Art'/r['file']).read_bytes();assert hashlib.sha256(raw).hexdigest()==r['sha256'];assert decode_blp(raw).size==(256,256)
    for name in expected:shutil.copyfile(OUT/'Art'/name,art/name)
    for pattern in ('v6_t*.blp','v6_city*.blp','v7_*.blp'):
        for p in art.glob(pattern):
            if p.name not in expected:
                assert p.resolve().parent==art;p.unlink()
    shutil.copyfile(OUT/'TerrainData.lua',ADDON/'TerrainData.lua')
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.6.0地形资源-20261024.json',report)
    print('Deployed HD terrain and seven city scenes',len(expected),flush=True)


def retouch_aq_boundaries():
    """Art-directed soil/rock fill around known unmodelled Silithus margins.

    This changes scenery only. Actual model pixels, road-material chunks, water
    and the existing southern courtyard are explicitly protected after feathering.
    """
    import refine_turtle_map_terrain as legacy
    legacy.OUT=OUT
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'))
    scene=next(c for c in report['continents'] if c['id']==1);left,top,width,height=scene['rect'];density=32
    client=Client(ROOT,True);texname='Tileset\\Silithis\\SilithisRock.blp'
    guides=[[146,465,10,55],[205,465,18,80],[148,449,70,15],[133,553,80,21],[188,528,20,27]]
    transforms=json.loads(next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.2.0*.json')).read_text(encoding='utf8'))['transforms'];t=transforms['1'];step=STEP*t['scale']
    try:
        raw,origin=client.read(texname);tex=np.asarray(decode_blp(raw).convert('RGB'),dtype=float)
        rasterize([OUT/'aq-join.job'])
        coverage=Image.frombytes('L',(7*512,10*512),(OUT/'aq-join.coverage').read_bytes())
        cr=[t['x']+(26-32)*step,t['y']+(43-32)*step,7*step,10*step]
        baseline=OUT/'Kalimdor-pre-retouch.png'
        if report.get('aq_boundary_retouch') and baseline.exists():master=Image.open(baseline).convert('RGBA')
        else:
            master=Image.open(OUT/'Kalimdor-terrain.png').convert('RGBA');master.save(baseline,compress_level=3)
        audit=[]
        def mean_field(a,r):
            hh,ww=a.shape;integral=np.pad(a.cumsum(axis=0).cumsum(axis=1),((1,0),(1,0)))
            xx=np.arange(ww);yy=np.arange(hh);l=np.maximum(0,xx-r);t0=np.maximum(0,yy-r);rr=np.minimum(ww,xx+r+1);bb=np.minimum(hh,yy+r+1)
            return (integral[bb[:,None],rr]-integral[t0[:,None],rr]-integral[bb[:,None],l]+integral[t0[:,None],l])/((bb-t0)[:,None]*(rr-l))
        for rect in guides:
            x,y,w,h=rect;box=(round((x-left)*density),round((y-top)*density),round((x+w-left)*density),round((y+h-top)*density));image=master.crop(box);a=np.asarray(image.convert('RGB'),dtype=float)
            gray=image.convert('L');res=ImageChops.difference(gray,gray.filter(ImageFilter.GaussianBlur(1.2))).filter(ImageFilter.BoxBlur(4))
            low=(np.asarray(res)<5)&(a[:,:,0]>a[:,:,2]*1.18)&(a[:,:,1]>a[:,:,2]*1.18)&(a.mean(axis=2)>18)&(a.mean(axis=2)<160)
            protect=Image.new('L',image.size);draw=__import__('PIL.ImageDraw',fromlist=['Draw']).Draw(protect)
            cb=((x-cr[0])/cr[2]*coverage.width,(y-cr[1])/cr[3]*coverage.height,(x+w-cr[0])/cr[2]*coverage.width,(y+h-cr[1])/cr[3]*coverage.height)
            actual=coverage.crop(cb).resize(image.size,Image.Resampling.BILINEAR).point(lambda v:255 if v>8 else 0).filter(ImageFilter.MaxFilter(3))
            protect=ImageChops.lighter(protect,actual);draw=__import__('PIL.ImageDraw',fromlist=['Draw']).Draw(protect)
            # Preserve all of the already displayed southern courtyard, not just
            # the small coloured landmarks caught by a frequency classifier.
            courtyard=[144,520,43,43]
            draw.rectangle((round((courtyard[0]-x)*density),round((courtyard[1]-y)*density),round((courtyard[0]+courtyard[2]-x)*density),round((courtyard[1]+courtyard[3]-y)*density)),fill=255)
            for ty in range(math.floor((y-t['y'])/step+32),math.ceil((y+h-t['y'])/step+32)):
                for tx in range(math.floor((x-t['x'])/step+32),math.ceil((x+w-t['x'])/step+32)):
                    try:data=client.read(f'World\\Maps\\Kalimdor\\Kalimdor_{tx}_{ty}.adt')[0]
                    except FileNotFoundError:continue
                    cells,names,_=material_cells(data)
                    for (cx,cy),cell in cells.items():
                        layers=list(struct.iter_unpack('<4I',cell['children'].get(b'YLCM',b'')))
                        if any(tid<len(names) and re.search(r'road|path|cobble|brick|street',names[tid],re.I) for tid,_,_,_ in layers):
                            wx=t['x']+(tx-32+cx/16)*step;wy=t['y']+(ty-32+cy/16)*step
                            draw.rectangle((round((wx-x)*density),round((wy-y)*density),round((wx+step/16-x)*density),round((wy+step/16-y)*density)),fill=255)
            mask=Image.fromarray(low.astype('uint8')*255)
            # A border fade prevents an art-direction rectangle becoming another
            # visible rectangular terrain patch.
            edge=Image.new('L',image.size);__import__('PIL.ImageDraw',fromlist=['Draw']).Draw(edge).rectangle((24,24,image.width-25,image.height-25),fill=255)
            mask=ImageChops.multiply(mask.filter(ImageFilter.GaussianBlur(5)),edge.filter(ImageFilter.GaussianBlur(12)))
            mask=ImageChops.multiply(mask,ImageChops.invert(protect))
            xx=x+np.arange(image.width)/density;yy=y+np.arange(image.height)/density
            ix=(np.floor(xx*64).astype(int)%tex.shape[1])[None,:];iy=(np.floor(yy*64).astype(int)%tex.shape[0])[:,None]
            # Match surrounding, textured ground rather than laying a bright
            # grey rock sheet over the native map's warmer palette.
            pad=128;context=master.crop((box[0]-pad,box[1]-pad,box[2]+pad,box[3]+pad)).convert('RGB')
            ca=np.asarray(context,dtype=float);cg=context.convert('L');ce=np.asarray(ImageChops.difference(cg,cg.filter(ImageFilter.GaussianBlur(1.2))).filter(ImageFilter.BoxBlur(4)))
            trusted=((ce>4)&(ca[:,:,0]>ca[:,:,2]*1.05)&(ca[:,:,1]>ca[:,:,2]*1.05)).astype(float)
            weight=mean_field(trusted,128);target=np.asarray(image.convert('RGB').filter(ImageFilter.GaussianBlur(16)),dtype=float)
            for channel in range(3):
                field=mean_field(ca[:,:,channel]*trusted,128)/np.maximum(weight,.001)
                colour=field[pad:pad+image.height,pad:pad+image.width];availability=np.clip(weight[pad:pad+image.height,pad:pad+image.width]*4,0,1)*.4
                target[:,:,channel]=target[:,:,channel]*(1-availability)+colour*availability
            rock=tex[iy,ix].mean(axis=2)/max(float(tex.mean()),12)
            stone=target*np.clip(rock,.65,1.35)[:,:,None]
            shade=1+.09*np.sin(xx[None,:]*.73+yy[:,None]*.41)+.055*np.sin(xx[None,:]*1.91-yy[:,None]*.87)
            fill=Image.fromarray(np.clip(stone*shade[:,:,None],0,255).astype('uint8')).convert('RGBA');fill.putalpha(image.getchannel('A'))
            result=Image.composite(fill,image,mask);master.paste(result,box[:2]);audit.append(dict(rect=rect,filled_pixels=int((np.asarray(mask)>0).sum()),protected_pixels=int((np.asarray(protect)>0).sum())))
        master.save(OUT/'Kalimdor-terrain.png',compress_level=3)
        files=[r for r in report['files'] if not r['file'].startswith('v7_t1_')]
        current=save_pyramid(master,scene['rect'],'v7_t1',files,(1,2,4,8,16,32));current['id']=1
        report['continents']=[current if c['id']==1 else c for c in report['continents']]
        report.update(files=files,total_files=len(files),total_bytes=sum((OUT/'Art'/r['file']).stat().st_size for r in files),aq_boundary_retouch=dict(guides=audit,material=texname,source=origin,sha256=hashlib.sha256(raw).hexdigest(),limit='Decorative rock/soil continuation where the source lacks detail; no new surveyed geometry, paths, buildings or markers. Raster model coverage, road materials, sea and southern courtyard are protected.'))
        json_write(OUT/'manifest.json',report);terrain=read_terrain(OUT/'TerrainData.lua');terrain['continents']=report['continents'];legacy.write_terrain(terrain)
        print('Retouched Silithus/AQ missing-detail margins',audit,flush=True)
    finally:
        for archive in client.archives:archive.close()


def audit_candidate():
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'));scene=next(c for c in report['continents'] if c['id']==1)
    left,top,_,_=scene['rect'];box=(round((144-left)*32),round((520-top)*32),round((187-left)*32),round((563-top)*32))
    hashes=[]
    for path in (OUT/'Kalimdor-pre-retouch.png',OUT/'Kalimdor-terrain.png'):
        with Image.open(path) as image:hashes.append(hashlib.sha256(image.crop(box).tobytes()).hexdigest())
    if hashes[0]!=hashes[1]:raise ValueError('Retouch changed the protected southern courtyard')
    failures=[]
    for row in report['files']:
        data=(OUT/'Art'/row['file']).read_bytes()
        if hashlib.sha256(data).hexdigest()!=row['sha256'] or decode_blp(data).size!=(256,256):failures.append(row['file'])
    if failures:raise ValueError('Incomplete HD candidate: '+repr(failures[:5]))
    report['quality_audit']=dict(protected_courtyard_rect=[144,520,43,43],courtyard_before_sha256=hashes[0],courtyard_after_sha256=hashes[1],files_checked=len(report['files']),map_data_sha256=hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest(),limit='Offline source geometry, texture and protected-pixel audit; game rendering and all landmarks still require in-game acceptance.')
    json_write(OUT/'manifest.json',report);print('Candidate audit passed:',len(report['files']),'textures; protected courtyard pixels unchanged',flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--probe',choices=('aq','stormwind'));parser.add_argument('--deploy-reviewed',action='store_true');parser.add_argument('--refine-boundaries',action='store_true');parser.add_argument('--retouch-aq-boundaries',action='store_true');parser.add_argument('--audit-candidate',action='store_true');args=parser.parse_args()
    if args.probe:probe(args.probe)
    elif args.deploy_reviewed:deploy()
    elif args.refine_boundaries:refine_boundaries()
    elif args.retouch_aq_boundaries:retouch_aq_boundaries()
    elif args.audit_candidate:audit_candidate()
    else:build();refine_boundaries();retouch_aq_boundaries();audit_candidate()
