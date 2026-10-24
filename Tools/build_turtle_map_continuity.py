"""0.7 candidate: continuous material coordinates, native water and typed atlases.

Client archives are read-only. Native landmarks, roads, coastlines, the AQ gate
and the southern courtyard are protected. Reconstructed margin textures describe
source terrain materials/heights, not surveyed new routes or buildings.
"""
import argparse
import hashlib
import json
import math
import re
import shutil
import struct
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter
import build_turtle_map_hd as hd
import refine_turtle_map_terrain as legacy
from build_turtle_map_atlas import source_maps
from build_turtle_seamless_map import ROOT, ADDON, STAGING, decode_blp, json_write
from turtle_map_archive import Client

OLD = STAGING/'v7-hd-candidate'
OUT = STAGING/'v8-continuity-candidate'
TRANSFORMS = next((ROOT/'PluginHistory/Research').glob('TurtleSeamlessMap-0.2.0*.json'))


class ContinuousGround(hd.Ground):
    """Shared world UVs; no small 4x4 swatch reset at every MCNK boundary."""
    def texture(self, name, size):
        if name not in self.cache:
            try:
                raw, origin = self.client.read(name)
            except FileNotFoundError:
                self.unavailable[name] += 1
                return None
            self.cache[name] = np.asarray(decode_blp(raw).convert('RGB'), dtype=np.float32)
            self.sources[name] = dict(source=origin, sha256=hashlib.sha256(raw).hexdigest())
        tex = self.cache[name]
        cx, cy = self.cell
        tx, ty = self.adt
        x = tx*16+cx+(np.arange(size, dtype=np.float32)+.5)/size
        y = ty*16+cy+(np.arange(size, dtype=np.float32)+.5)/size
        # Smooth nonperiodic-looking variation shares its phase across tiles.
        u = x[None,:]/4+.12*np.sin(y[:,None]*.37+x[None,:]*.11)
        v = y[:,None]/4+.12*np.sin(x[None,:]*.29-y[:,None]*.07)
        u = np.broadcast_to(u, (size,size))*tex.shape[1]
        v = np.broadcast_to(v, (size,size))*tex.shape[0]
        ix, iy = np.floor(u).astype(int), np.floor(v).astype(int)
        fx, fy = (u-ix)[:,:,None], (v-iy)[:,:,None]
        a = tex[iy%tex.shape[0], ix%tex.shape[1]]
        b = tex[iy%tex.shape[0], (ix+1)%tex.shape[1]]
        c = tex[(iy+1)%tex.shape[0], ix%tex.shape[1]]
        d = tex[(iy+1)%tex.shape[0], (ix+1)%tex.shape[1]]
        return Image.fromarray(np.clip((a*(1-fx)+b*fx)*(1-fy)+(c*(1-fx)+d*fx)*fy,0,255).astype('uint8'))


def colour_transfer(native, ground, mask):
    """Continuous confidence-weighted colour ratios; coarse fills have context.

    Ratios retain actual material colours and variation, unlike one uniform
    neighbour colour multiplied by a tiny repeated swatch. Work at 4/world-unit.
    """
    n, g = np.asarray(native, dtype=np.float32), np.asarray(ground, dtype=np.float32)
    trusted = (np.asarray(mask)<8).astype('float32')
    sea = (n[:,:,2]>n[:,:,0]*1.15)&(n[:,:,1]>n[:,:,0]*1.12)
    trusted[sea | (n.mean(axis=2)<12) | (g.mean(axis=2)<12)] = 0
    # Float summed areas avoid colour banding in low-confidence margins.
    def mean(a, radius):
        h,w=a.shape
        summed=np.pad(a.astype('float64').cumsum(axis=0).cumsum(axis=1),((1,0),(1,0)))
        x=np.arange(w);y=np.arange(h)
        l=np.maximum(0,x-radius);r=np.minimum(w,x+radius+1)
        t=np.maximum(0,y-radius);b=np.minimum(h,y+radius+1)
        return ((summed[b[:,None],r]-summed[t[:,None],r]-summed[b[:,None],l]+summed[t[:,None],l])/((b-t)[:,None]*(r-l)))
    ratio = np.ones_like(n)
    for radius in (192,64,16):
        weight = mean(trusted, radius)
        confidence = np.clip(weight*6,0,1)[:,:,None]
        for channel in range(3):
            wanted = mean(n[:,:,channel]*trusted, radius)
            actual = mean(g[:,:,channel]*trusted, radius)
            local = np.clip(wanted/np.maximum(actual,1),.45,1.8)
            ratio[:,:,channel] = ratio[:,:,channel]*(1-confidence[:,:,0])+local*confidence[:,:,0]
    return [Image.fromarray(ratio[:,:,c].astype('float32')) for c in range(3)]


def box_for(rect, extent, density):
    return tuple(round(v*density) for v in (rect[0]-extent[0],rect[1]-extent[1],rect[0]+rect[2]-extent[0],rect[1]+rect[3]-extent[1]))


def quilt_rock(image, size=768, seed=112):
    """Overlap-matched terrain-only patches, with minimum-error seam cuts.

    Unlike mirrored repetition this never creates paired/symmetric boulders.
    The fixed seed and source pixels make offline production reproducible.
    """
    rng=np.random.default_rng(seed);source=np.asarray(image.convert('RGB'),dtype=np.float32)
    patch=min(48,min(image.size)//2);overlap=patch//4;step=patch-overlap
    out=np.zeros((size+patch,size+patch,3),dtype=np.float32)
    def cut(cost):
        h,w=cost.shape;score=cost[0].copy();trace=np.zeros((h,w),dtype=int)
        for row in range(1,h):
            before=np.pad(score,(1,1),constant_values=np.inf)
            choices=np.stack((before[:-2],before[1:-1],before[2:]))
            move=choices.argmin(axis=0)-1;trace[row]=np.arange(w)+move
            score=cost[row]+choices.min(axis=0)
        path=np.empty(h,dtype=int);path[-1]=score.argmin()
        for row in range(h-1,0,-1):path[row-1]=trace[row,path[row]]
        return path
    for y in range(0,size,step):
        for x in range(0,size,step):
            candidates=[];errors=[];old=out[y:y+patch,x:x+patch]
            for _ in range(16):
                sx=int(rng.integers(0,source.shape[1]-patch+1));sy=int(rng.integers(0,source.shape[0]-patch+1))
                piece=np.rot90(source[sy:sy+patch,sx:sx+patch],int(rng.integers(0,4)))
                error=0
                if x:error+=float(((old[:,:overlap]-piece[:,:overlap])**2).mean())
                if y:error+=float(((old[:overlap]-piece[:overlap])**2).mean())
                candidates.append(piece);errors.append(error)
            scores=np.asarray(errors);pool=np.flatnonzero(scores<=scores.min()*1.08+1)
            piece=candidates[int(rng.choice(pool))];keep=np.zeros((patch,patch),dtype=bool)
            if x:
                path=cut(((old[:,:overlap]-piece[:,:overlap])**2).mean(axis=2))
                keep[:,:overlap]|=np.arange(overlap)[None,:]<path[:,None]
            if y:
                path=cut(((old[:overlap]-piece[:overlap])**2).mean(axis=2).T)
                keep[:overlap]|=np.arange(overlap)[:,None]<path[None,:]
            out[y:y+patch,x:x+patch]=np.where(keep[:,:,None],old,piece)
    out=out[:size,:size].copy()
    # Equal endpoint values, without mirroring or a geometric repeat motif.
    edge=24;fade=np.linspace(1,0,edge,dtype=np.float32)
    delta=(out[:,-1]-out[:,0])/2
    out[:,:edge]+=delta[:,None,:]*fade[None,:,None]
    out[:,-edge:]-=delta[:,None,:]*fade[::-1][None,:,None]
    delta=(out[-1]-out[0])/2
    out[:edge]+=delta[None,:,:]*fade[:,None,None]
    out[-edge:]-=delta[None,:,:]*fade[::-1][:,None,None]
    return Image.fromarray(np.clip(out,0,255).astype('uint8'))


def build_world():
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'ground').mkdir(exist_ok=True)
    report=json.loads((OLD/'manifest.json').read_text(encoding='utf8'))
    transforms=json.loads(TRANSFORMS.read_text(encoding='utf8'))['transforms']
    client=Client(ROOT,True);ground=ContinuousGround(client);refs=hd.minimap_index(client)
    audit=[]
    try:
        for scene in report['continents']:
            cid=scene['id'];name='Kalimdor' if cid==1 else 'Azeroth';rect=scene['rect']
            left,top,width,height=rect;t=transforms[str(cid)];step=hd.STEP*t['scale']
            native=Image.open(OLD/f'{name}-before.png').convert('RGBA')
            mask=Image.new('L',native.size);protected=Image.new('L',native.size)
            materials=Image.new('RGB',(width*4,height*4));todo=[];all_tiles=[];road_count=0
            for source in (s for s in report['sources'] if s['continent']==name):
                tx,ty=source['x'],source['y'];wx=t['x']+(tx-32)*step;wy=t['y']+(ty-32)*step
                r=[wx,wy,step,step];smallbox=box_for(r,rect,4)
                all_tiles.append((tx,ty,r))
                cached=OLD/'ground'/f'{cid}-{tx}-{ty}.png'
                if cached.exists():materials.paste(Image.open(cached).convert('RGB').resize((smallbox[2]-smallbox[0],smallbox[3]-smallbox[1]),Image.Resampling.LANCZOS),smallbox[:2])
                ref=refs.get((name.lower(),tx,ty))
                if not ref:continue
                raw=client.read('Textures\\Minimap\\'+ref)[0];image=decode_blp(raw).convert('RGBA')
                seed=hd.spectral_margin(image)|hd.flat_margin(image)[1]
                data=client.read(f'World\\Maps\\{name}\\{name}_{tx}_{ty}.adt')[0]
                cells,textures,_=legacy.material_cells(data)
                safe=Image.new('L',(256,256));draw=ImageDraw.Draw(safe)
                for (x,y),cell in cells.items():
                    layers=list(struct.iter_unpack('<4I',cell['children'].get(b'YLCM',b'')))
                    road=any(tid<len(textures) and re.search(r'road|path|cobble|brick|street',textures[tid],re.I) for tid,_,_,_ in layers)
                    if cell['water'] and cell['maximum']<=cell['water_level']:
                        seed[y,x]=False;draw.rectangle((x*16,y*16,x*16+15,y*16+15),fill=255)
                    if road:
                        # Protect the road's actual layer weights, not the
                        # rectangular chunk which merely mentions its texture.
                        weight=np.zeros((64,64),dtype=np.float32)
                        for i,(tid,flags,offset,_) in enumerate(layers):
                            isroad=bool(tid<len(textures) and re.search(r'road|path|cobble|brick|street',textures[tid],re.I))
                            if i==0:weight[:]=float(isroad);continue
                            raw=cell['children'].get(b'LACM',b'')[offset:offset+2048]
                            if len(raw)!=2048:raise ValueError('Invalid road layer alpha')
                            values=np.frombuffer(raw,dtype='u1');alpha=np.empty(4096,dtype='float32')
                            alpha[::2]=(values&15)/15;alpha[1::2]=(values>>4)/15;alpha=alpha.reshape(64,64)
                            alpha[-1]=alpha[-2];alpha[:,-1]=alpha[:,-2]
                            weight=weight*(1-alpha)+float(isroad)*alpha
                        roadmask=Image.fromarray(np.clip(weight*255,0,255).astype('uint8')).resize((16,16),Image.Resampling.BILINEAR)
                        safe.paste(ImageChops.lighter(safe.crop((x*16,y*16,x*16+16,y*16+16)),roadmask),(x*16,y*16));road_count+=1
                b=box_for(r,rect,16);size=(b[2]-b[0],b[3]-b[1])
                protected.paste(safe.resize(size,Image.Resampling.NEAREST),b[:2])
                if not seed.any():continue
                local=legacy.repair_mask(image,seed)
                mask.paste(local.resize(size,Image.Resampling.NEAREST),b[:2])
            draw=ImageDraw.Draw(protected)
            keep=[m['rect'] for m in source_maps() if m.get('city') and m['map']==cid]
            if cid==1:keep += [[150,495,45,30],[144,520,43,43]]
            for r in keep:draw.rectangle(box_for(r,rect,16),fill=255)
            protected.save(OUT/f'{name}-protected.png')
            # One continent-wide feather crosses both ADT and chunk boundaries.
            soft=mask.filter(ImageFilter.MaxFilter(33)).filter(ImageFilter.GaussianBlur(24))
            soft=ImageChops.multiply(soft,ImageChops.invert(protected))
            soft=ImageChops.multiply(soft,native.getchannel('A'))
            fields=colour_transfer(native.convert('RGB').resize(materials.size,Image.Resampling.LANCZOS),materials,soft.resize(materials.size,Image.Resampling.BILINEAR))
            del materials,mask,protected,native
            # Feather tails must also be rendered on neighbouring ADTs. Ending
            # reconstruction at the seed tile recreated a straight tile seam.
            for tx,ty,r in all_tiles:
                if not soft.crop(box_for(r,rect,16)).getbbox():continue
                path=OUT/'ground'/f'{cid}-{tx}-{ty}.png'
                if not path.exists():
                    data=client.read(f'World\\Maps\\{name}\\{name}_{tx}_{ty}.adt')[0]
                    ref=refs.get((name.lower(),tx,ty))
                    reference=decode_blp(client.read('Textures\\Minimap\\'+ref)[0]) if ref else None
                    ground.adt=(tx,ty);piece,_=ground.tile(data,768,reference,True);piece.save(path)
                todo.append((tx,ty,r,path))
                if len(todo)%100==0:print('Continuous materials',name,len(todo),flush=True)
            master=Image.open(OLD/f'{name}-terrain.png').convert('RGBA');changed=0
            exact=[(box_for(r,rect,32),master.crop(box_for(r,rect,32))) for r in keep]
            for tx,ty,r,path in todo:
                b=box_for(r,rect,32);w,h=b[2]-b[0],b[3]-b[1]
                old=master.crop(b);pixels=np.asarray(Image.open(path).convert('RGB').resize((w,h),Image.Resampling.LANCZOS),dtype=np.float32)
                context=(b[0]/8,b[1]/8,b[2]/8,b[3]/8)
                for channel,field in enumerate(fields):pixels[:,:,channel]*=np.asarray(field.resize((w,h),Image.Resampling.BILINEAR,box=context))
                fill=Image.fromarray(np.clip(pixels,0,255).astype('uint8')).convert('RGBA');fill.putalpha(old.getchannel('A'))
                alpha=soft.resize((w,h),Image.Resampling.BILINEAR,box=(b[0]/2,b[1]/2,b[2]/2,b[3]/2))
                changed+=int((np.asarray(alpha)>0).sum());master.paste(Image.composite(fill,old,alpha),b[:2])
            # Resampling a mask can bleed into its first protected edge pixel.
            # Restore the explicitly protected rectangles after all filtering.
            for b,pixels in exact:master.paste(pixels,b[:2])
            master.save(OUT/f'{name}-terrain.png',compress_level=3);soft.save(OUT/f'{name}-mask.png')
            preview=master.copy();preview.thumbnail((1000,1500));preview.save(OUT/f'{name}-preview.png')
            audit.append(dict(id=cid,name=name,material_tiles=len(todo),affected_pixels=changed,protected_road_chunks=road_count,protected_rects=keep))
            del master,soft,fields
            print('Continuous continent ready',name,changed,flush=True)
        materials=dict(report['material_sources']);materials.update(ground.sources)
        cached=[dict(file=p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in sorted((OUT/'ground').glob('*.png'))]
        json_write(OUT/'boundary-audit.json',dict(continents=audit,material_sources=materials,missing_materials_loaded_this_run=dict(ground.unavailable),source_material_fallbacks=report['material_fallbacks'],source_manifest_sha256=hashlib.sha256((OLD/'manifest.json').read_bytes()).hexdigest(),material_cache=cached))
    finally:
        for archive in client.archives:archive.close()


def build_city():
    OUT.mkdir(parents=True,exist_ok=True)
    previous=hd.OUT;hd.OUT=OUT
    client=Client(ROOT,True,True,True)
    try:
        image,bounds,info=hd.model_region(client,hd.Ground(client),'Azeroth',301,'city-301')
        transforms=json.loads(TRANSFORMS.read_text(encoding='utf8'))['transforms'];t=transforms['0'];step=hd.STEP*t['scale']
        rect=next(m['rect'] for m in source_maps() if m['id']==301)
        world=[t['x']+(bounds[0]-32)*step,t['y']+(bounds[1]-32)*step,(bounds[2]-bounds[0])*step,(bounds[3]-bounds[1])*step]
        b=tuple(round(v) for v in ((rect[0]-world[0])/world[2]*image.width,(rect[1]-world[1])/world[3]*image.height,(rect[0]+rect[2]-world[0])/world[2]*image.width,(rect[1]+rect[3]-world[1])/world[3]*image.height))
        image=hd.feather(image.crop(b),40);image.save(OUT/'city-301-world.png')
        info['rect']=rect;json_write(OUT/'city-audit.json',info)
    finally:
        hd.OUT=previous
        for archive in client.archives:archive.close()


def finish_gaps():
    """Landscape-only continuation in named unfinished margins.

    Small reviewed rock/brush exemplars contain no roads/buildings/POIs. Their
    overlap-matched borders and shared world UVs remove rectangular repeats.
    They are decorative texture, not a claim about inaccessible game geometry.
    """
    report=json.loads((OLD/'manifest.json').read_text(encoding='utf8'))
    scene=next(c for c in report['continents'] if c['id']==1);extent=scene['rect']
    transforms=json.loads(TRANSFORMS.read_text(encoding='utf8'))['transforms'];t=transforms['1'];step=hd.STEP*t['scale']
    # Draw only scenery actually placed on Kalimdor; no Dire Maul instance map.
    hd.OUT=OUT;client=Client(ROOT,True,True,True)
    region_rect=[163,392,52,43]
    bounds=(math.floor((region_rect[0]-t['x'])/step+32),math.floor((region_rect[1]-t['y'])/step+32),math.ceil((region_rect[0]+region_rect[2]-t['x'])/step+32),math.ceil((region_rect[1]+region_rect[3]-t['y'])/step+32))
    try:
        if not (OUT/'diremaul.png').exists():
            scenery=hd.Scenery(client,skip_foliage=True)
            hd.region(client,hd.Ground(client),scenery,'Kalimdor',bounds,768,'diremaul')
    finally:
        for archive in client.archives:archive.close()
    world=[t['x']+(bounds[0]-32)*step,t['y']+(bounds[1]-32)*step,(bounds[2]-bounds[0])*step,(bounds[3]-bounds[1])*step]
    maul=Image.open(OUT/'diremaul.png').convert('RGBA')
    coverage=Image.frombytes('L',maul.size,(OUT/'diremaul.coverage').read_bytes())
    master=Image.open(OUT/'Kalimdor-terrain.png').convert('RGBA')
    native=Image.open(OLD/'Kalimdor-terrain.png').convert('RGBA')
    # Explicitly retire the previous hand-filled rectangles. Retaining their
    # unclassified fringe underneath the new mask recreated visible straight
    # lines, even with a smooth new texture over the centre.
    baseline=Image.open(OLD/'Kalimdor-pre-retouch.png').convert('RGBA')
    soft=Image.open(OUT/'Kalimdor-mask.png').convert('L')
    protected=Image.open(OUT/'Kalimdor-protected.png').convert('L')
    for y in range(0,master.height,256):
        b=(0,y,master.width,min(master.height,y+256));old=np.asarray(native.crop(b),dtype=np.int16);pre=np.asarray(baseline.crop(b),dtype=np.int16)
        a=np.asarray(soft.resize((b[2],b[3]-b[1]),Image.Resampling.BILINEAR,box=(0,b[1]/2,soft.width,b[3]/2)),dtype=np.float32)/255
        keep=np.asarray(protected.resize((b[2],b[3]-b[1]),Image.Resampling.NEAREST,box=(0,b[1]/2,protected.width,b[3]/2)),dtype=np.float32)/255
        a=np.maximum(a,keep)
        pixels=np.asarray(master.crop(b),dtype=np.float32)-(old-pre)*(1-a[:,:,None])
        master.paste(Image.fromarray(np.clip(pixels,0,255).astype('uint8')),b[:2])
    del baseline
    # Low-resolution trusted colour context is continuous over the continent.
    small=native.convert('RGB').resize((extent[2]*4,extent[3]*4),Image.Resampling.LANCZOS)
    smallmask=soft.resize(small.size,Image.Resampling.BILINEAR)
    guides=[
        ('south-ungoro',[187,499,65,52],[221,508,3,3]),
        ('west-silithus',[130,456,31,109],[155,487,3,3]),
        ('diremaul-feralas',[113,381,105,89],[181,433,3,3]),
        ('feralas-needles',[210,409,40,61],[181,433,3,3]),
        ('ashenvale-hyjal',[210,229,111,44],[240,240,3,3]),
        ('winter-moonglade',[225,155,64,59],[258,169,3,3]),
    ]
    changed=[]
    original=Image.open(OLD/'Kalimdor-before.png').convert('RGB')
    rock_reference=[240,240,3,3]
    rock=native.crop(box_for(rock_reference,extent,32)).convert('RGB')
    quilt=quilt_rock(rock);quilt.save(OUT/'rock-quilt.png')
    for label,r,reference in guides:
        b=box_for(r,extent,32);old=master.crop(b);w,h=old.size
        mask=soft.resize((w,h),Image.Resampling.BILINEAR,box=(b[0]/2,b[1]/2,b[2]/2,b[3]/2))
        # Follow low-detail pixels connected to the known unfinished margins.
        # This removes unclassified narrow square bands without selecting an
        # isolated flat building floor elsewhere in the region.
        source=original.crop(box_for(r,extent,16)).convert('L')
        detail=ImageChops.difference(source,source.filter(ImageFilter.GaussianBlur(3))).filter(ImageFilter.BoxBlur(3))
        quality=np.asarray(detail.resize((r[2]*4,r[3]*4),Image.Resampling.BOX))<4
        candidate=Image.fromarray(np.uint8(quality)*255)
        grown=mask.resize(candidate.size,Image.Resampling.BILINEAR).point(lambda x:255 if x>100 else 0)
        for _ in range(12):
            next_mask=ImageChops.darker(grown.filter(ImageFilter.MaxFilter(3)),candidate)
            next_mask=ImageChops.lighter(next_mask,grown)
            if next_mask.tobytes()==grown.tobytes():break
            grown=next_mask
        expanded=grown.resize((w,h),Image.Resampling.BILINEAR).filter(ImageFilter.GaussianBlur(24))
        mask=ImageChops.lighter(mask,expanded)
        safe=protected.resize((w,h),Image.Resampling.BILINEAR,box=(b[0]/2,b[1]/2,b[2]/2,b[3]/2))
        mask=ImageChops.multiply(mask,ImageChops.invert(safe))
        pixels=np.asarray(old.convert('RGB'))
        water=(pixels[:,:,2]>pixels[:,:,0]*1.15)&(pixels[:,:,1]>pixels[:,:,0]*1.12)
        mask=ImageChops.multiply(mask,Image.fromarray(np.uint8(~water)*255))
        # Ease the review rectangle itself; only the quality mask paints land.
        edge=Image.new('L',(w,h));ImageDraw.Draw(edge).rectangle((96,96,w-97,h-97),fill=255)
        mask=ImageChops.multiply(mask,edge.filter(ImageFilter.GaussianBlur(48)))
        protect=Image.new('L',(w,h));draw=ImageDraw.Draw(protect)
        for p in ([150,495,45,30],[144,520,43,43]):draw.rectangle(box_for(p,r,32),fill=255)
        mb=box_for(world,r,32)
        local_model=coverage.resize((mb[2]-mb[0],mb[3]-mb[1]),Image.Resampling.BILINEAR)
        protect.paste(ImageChops.lighter(protect.crop(mb),local_model),mb[:2])
        mask=ImageChops.multiply(mask,ImageChops.invert(protect))
        sample=native.crop(box_for(reference,extent,32)).convert('RGB')
        texture=np.asarray(quilt,dtype=np.float32)
        xx=r[0]+(np.arange(w,dtype=np.float32)+.5)/32
        yy=r[1]+(np.arange(h,dtype=np.float32)+.5)/32
        u=(xx[None,:]/24+.012*np.sin(yy[:,None]*.53)+.006*np.sin(xx[None,:]*.31+yy[:,None]*.19))*texture.shape[1]
        v=(yy[:,None]/24+.012*np.sin(xx[None,:]*.47)+.006*np.sin(xx[None,:]*.17-yy[:,None]*.29))*texture.shape[0]
        ix,iy=np.floor(u).astype(int),np.floor(v).astype(int);fx=(u-ix)[:,:,None];fy=(v-iy)[:,:,None]
        a=texture[iy%texture.shape[0],ix%texture.shape[1]];c=texture[(iy+1)%texture.shape[0],ix%texture.shape[1]]
        bb=texture[iy%texture.shape[0],(ix+1)%texture.shape[1]];d=texture[(iy+1)%texture.shape[0],(ix+1)%texture.shape[1]]
        pattern=(a*(1-fx)+bb*fx)*(1-fy)+(c*(1-fx)+d*fx)*fy
        # Context is estimated only from outside the missing-detail mask.
        context=small.crop(box_for([r[0]-20,r[1]-20,r[2]+40,r[3]+40],extent,4))
        missing=smallmask.crop(box_for([r[0]-20,r[1]-20,r[2]+40,r[3]+40],extent,4))
        rgb=np.asarray(context,dtype=np.float32);trusted=(np.asarray(missing)<8).astype('float32')
        sea=(rgb[:,:,2]>rgb[:,:,0]*1.15)&(rgb[:,:,1]>rgb[:,:,0]*1.12);trusted[sea| (rgb.mean(axis=2)<15)]=0
        weight=Image.fromarray(np.uint8(trusted*255)).filter(ImageFilter.GaussianBlur(32))
        weight=np.asarray(weight,dtype=np.float32)/255
        tint=np.empty((context.height,context.width,3),dtype=np.float32)
        fallback=np.asarray(sample,dtype=np.float32).mean(axis=(0,1))
        for channel in range(3):
            weighted=Image.fromarray(np.uint8(np.clip(rgb[:,:,channel]*trusted,0,255))).filter(ImageFilter.GaussianBlur(32))
            tint[:,:,channel]=np.where(weight>.04,np.asarray(weighted,dtype=np.float32)/np.maximum(weight,.04),fallback[channel])
        tint_image=Image.fromarray(np.clip(tint,0,255).astype('uint8')).crop((80,80,80+r[2]*4,80+r[3]*4)).resize((w,h),Image.Resampling.BILINEAR)
        target=np.asarray(tint_image,dtype=np.float32)*.65+fallback*.35
        rock_mean=np.asarray(rock,dtype=np.float32).mean(axis=(0,1))
        ratio=np.clip(.4+.6*pattern/np.maximum(rock_mean,15),.55,1.5)
        fill=Image.fromarray(np.clip(target*ratio,0,255).astype('uint8')).convert('RGBA');fill.putalpha(old.getchannel('A'))
        master.paste(Image.composite(fill,old,mask),b[:2])
        changed.append(dict(name=label,rect=r,colour_reference=reference,terrain_only_exemplar=rock_reference,exemplar_sha256=hashlib.sha256(rock.tobytes()).hexdigest(),changed_pixels=int((np.asarray(mask)>0).sum())))
        print('Landscape continuation',label,changed[-1]['changed_pixels'],flush=True)
    # Physical model coverage protects the exterior architecture during fills.
    b=box_for(world,extent,32);size=(b[2]-b[0],b[3]-b[1]);layer=maul.resize(size,Image.Resampling.LANCZOS)
    alpha=coverage.resize(size,Image.Resampling.BILINEAR).filter(ImageFilter.GaussianBlur(.65))
    layer.putalpha(alpha);master.alpha_composite(layer,b[:2])
    for r in ([150,495,45,30],[144,520,43,43]):
        b=box_for(r,extent,32);master.paste(native.crop(b),b[:2])
    master.save(OUT/'Kalimdor-finished.png',compress_level=3)
    json_write(OUT/'landscape-audit.json',dict(guides=changed,diremaul_world_rect=world,diremaul=json.loads((OUT/'diremaul-sources.json').read_text(encoding='utf8')),limit='Reviewed rock/brush textures extend only missing-detail margins. No copied roads, buildings, POIs or surveyed new landforms. Actual exterior Dire Maul WMO/M2 coverage replaces the static exterior at its real placement.'))


def pack():
    (OUT/'Art').mkdir(exist_ok=True);legacy.OUT=OUT
    old=json.loads((OLD/'manifest.json').read_text(encoding='utf8'));terrain=legacy.read_terrain(ADDON/'TerrainData.lua')
    files=[];scenes=[];cities=terrain['cities']
    for item in old['files']:
        if item['file'].startswith('v7_city') and not item['file'].startswith('v7_city301_'):
            shutil.copyfile(OLD/'Art'/item['file'],OUT/'Art'/item['file']);files.append(item)
    cities[301]=legacy.save_pyramid(Image.open(OUT/'city-301-world.png').convert('RGBA'),next(m['rect'] for m in source_maps() if m['id']==301),'v8_city301',files,(8,16,32,64))
    for scene in old['continents']:
        cid=scene['id'];name='Kalimdor' if cid==1 else 'Azeroth';rect=scene['rect']
        source=OUT/f'{name}-finished.png'
        master=Image.open(source if source.exists() else OUT/f'{name}-terrain.png').convert('RGBA')
        # The same surface-city picture now belongs to the continent at every
        # level. A near overlay adds source pixels without swapping geography.
        for m in source_maps():
            if not m.get('city') or m['map']!=cid or m['id'] in (341,382):continue
            source=(OUT if m['id']==301 else OLD)/f'city-{m["id"]}-world.png'
            city=Image.open(source).convert('RGBA');b=box_for(m['rect'],rect,32)
            city=city.resize((b[2]-b[0],b[3]-b[1]),Image.Resampling.LANCZOS);master.alpha_composite(city,b[:2])
        master.save(OUT/f'{name}-packed.png',compress_level=3)
        current=legacy.save_pyramid(master,rect,f'v8_t{cid}',files,(1,2,4,8,16,32));current['id']=cid;scenes.append(current)
        print('Packed',name,len(files),flush=True)
    terrain.update(continents=scenes,cities=cities,revision=8);legacy.write_terrain(terrain)
    # Read the written Lua, not only the Python manifest: JSON key conversion
    # previously made an intact Eastern Kingdoms atlas invisible in-game.
    typed=legacy.read_terrain(OUT/'TerrainData.lua');tile_count=0
    for scene in list(typed['continents'].values())+list(typed['cities'].values()):
        for level in scene['levels'].values():
            assert all(type(k)==int for k in level['tiles']), 'Nonnumeric atlas keys'
            tile_count+=len(level['tiles'])
    assert tile_count==len(files)
    for f in files:
        payload=(OUT/'Art'/f['file']).read_bytes()
        assert hashlib.sha256(payload).hexdigest()==f['sha256']
        assert decode_blp(payload).size==(256,256)
    report=dict(version='0.7.0',continents=scenes,files=files,total_files=len(files),total_bytes=sum((OUT/'Art'/f['file']).stat().st_size for f in files),boundaries=json.loads((OUT/'boundary-audit.json').read_text(encoding='utf8')),landscape=json.loads((OUT/'landscape-audit.json').read_text(encoding='utf8')),stormwind=json.loads((OUT/'city-audit.json').read_text(encoding='utf8')),numeric_lua_tiles_checked=tile_count,map_data_sha256=hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest(),limitations='Material/height continuation is decorative in unsurveyed margins. Native landmarks, roads, coast and AQ courtyard retained. Static Stormwind liquid shader approximates source waves; real grid heights preserve bridges. No claim of new surveyed geometry or in-game acceptance.')
    json_write(OUT/'manifest.json',report)


def deploy():
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'));art=(ADDON/'Art').resolve()
    assert report['map_data_sha256']==hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest()
    assert report['quality_audit']['terrain_lua_sha256']==hashlib.sha256((OUT/'TerrainData.lua').read_bytes()).hexdigest()
    assert all(report['quality_audit']['protected_pixels_equal'].values())
    expected={f['file'] for f in report['files']}
    for f in report['files']:
        assert re.fullmatch(r'v[78]_(?:t[01]|city\d+)_\d+_\d+_\d+\.blp',f['file'])
        payload=(OUT/'Art'/f['file']).read_bytes();assert hashlib.sha256(payload).hexdigest()==f['sha256']
        assert decode_blp(payload).size==(256,256)
    for f in report['files']:shutil.copyfile(OUT/'Art'/f['file'],art/f['file'])
    for pattern in ('v7_t*.blp','v7_city301_*.blp','v8_*.blp'):
        for p in art.glob(pattern):
            if p.name not in expected:
                assert p.resolve().parent==art;p.unlink()
    shutil.copyfile(OUT/'TerrainData.lua',ADDON/'TerrainData.lua')
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.7.0地形资源-20261024.json',report)
    print('Deployed continuity candidate',len(expected),flush=True)


def audit():
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf8'))
    typed=legacy.read_terrain(OUT/'TerrainData.lua');references=set()
    for scene in list(typed['continents'].values())+list(typed['cities'].values()):
        for level in scene['levels'].values():
            for index in level['tiles']:
                assert type(index)==int
                row,col=divmod(index-1,level['cols'])
                references.add(f'{level["prefix"]}_{col}_{row}.blp')
    assert references=={f['file'] for f in report['files']}
    protected={};coasts={}
    for scene in report['continents']:
        name='Kalimdor' if scene['id']==1 else 'Azeroth'
        old=Image.open(OLD/f'{name}-terrain.png');new=Image.open(OUT/f'{name}-terrain.png')
        coasts[name]=hashlib.sha256(old.getchannel('A').tobytes()).hexdigest()==hashlib.sha256(new.getchannel('A').tobytes()).hexdigest()
        assert coasts[name]
        if scene['id']==1:
            final=Image.open(OUT/'Kalimdor-packed.png')
            for label,rect in (('aq-gate',[150,495,45,30]),('aq-courtyard',[144,520,43,43])):
                b=box_for(rect,scene['rect'],32);protected[label]=old.crop(b).tobytes()==final.crop(b).tobytes()
                assert protected[label],label
    report['quality_audit']=dict(terrain_lua_sha256=hashlib.sha256((OUT/'TerrainData.lua').read_bytes()).hexdigest(),numeric_references_checked=len(references),protected_pixels_equal=protected,source_coast_alpha_equal=coasts)
    json_write(OUT/'manifest.json',report);print('Candidate audit',report['quality_audit'],flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('step',choices=('world','city','finish','pack','audit','deploy','all'));args=parser.parse_args()
    if args.step in ('world','all'):build_world()
    if args.step in ('city','all'):build_city()
    if args.step in ('finish','all'):finish_gaps()
    if args.step in ('pack','all'):pack()
    if args.step in ('audit','all'):audit()
    if args.step=='deploy':deploy()
