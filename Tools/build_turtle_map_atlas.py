"""Bake one coordinate-locked outdoor atlas, native world paper and a tile pyramid.

Inputs are the immutable local extraction. Default output is an ignored candidate;
--deploy-reviewed explicitly installs it. Archives are never modified. Run --audit
to check the installed minimap index. Art masks are not server territory claims.
"""
import argparse
import hashlib
import json
import math
import re
import shutil
import struct
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from build_turtle_seamless_map import ROOT, ADDON, STAGING, decode_blp, encode_blp, lua, write, json_write
from build_turtle_map_presentation import city_mask
from turtle_map_archive import Client

OUT = STAGING/'v4-candidate'
SIZE, INNER, MAX_DENSITY = 256, 254, 16
DENSITIES = (1, 2, 4, 8, 16)

# Normalized land/paint extents reviewed against all 53 original source pages.
# Exploration alpha is retained as an ADDITION, never used as the only crop.
# Coast polygons deliberately retain mountain rims; water/shore strokes extend
# beyond them through a separate paint mask. The 502 page has no exploration.
OUTLINES = {
 4:[(.22,.01),(.57,.01),(.58,.50),(.62,.70),(.74,.78),(.69,.96),(.48,.94),(.39,.83),(.34,.64),(.29,.45)],
 9:[(.34,.01),(.67,.01),(.63,.23),(.64,.48),(.74,.84),(.65,.98),(.37,.98),(.29,.74),(.29,.43)],
 11:[(.30,.01),(.66,.01),(.68,.23),(.64,.45),(.65,.65),(.62,.97),(.35,.99),(.26,.79),(.27,.51),(.30,.32)],
 15:[(.29,.01),(.84,.01),(.91,.32),(.91,.77),(.75,.95),(.37,.93),(.18,.69),(.19,.43)],
 16:[(.16,.03),(.86,.01),(.98,.29),(.96,.67),(.82,.90),(.38,.92),(.15,.71),(.05,.46)],
 17:[(.02,.18),(.14,.03),(.67,.03),(.93,.18),(.98,.70),(.88,.95),(.20,.98),(.02,.76)],
 19:[(.32,.03),(.70,.03),(.77,.38),(.72,.68),(.60,.96),(.32,.96),(.23,.72),(.26,.42)],
 20:[(.16,.43),(.38,.21),(.64,.10),(.90,.13),(.98,.45),(.86,.75),(.73,.85),(.43,.96),(.16,.89),(.03,.67)],
 21:[(.45,.01),(.77,.01),(.86,.18),(.87,.39),(.77,.47),(.65,.58),(.63,.98),(.37,.98),(.37,.68),(.41,.42)],
 22:[(.15,.05),(.87,.02),(.98,.45),(.93,.98),(.38,.98),(.17,.78),(.02,.42)],
 23:[(.03,.35),(.22,.07),(.43,.01),(.71,.01),(.91,.18),(.98,.31),(.95,.61),(.91,.83),(.98,.95),(.64,.98),(.33,.91),(.14,.76),(.02,.73)],
 24:[(.08,.13),(.41,.07),(.77,.19),(.96,.34),(.89,.66),(.80,.77),(.40,.83),(.14,.71),(.01,.44)],
 26:[(.02,.06),(.66,.03),(.85,.27),(.88,.48),(.77,.79),(.56,.93),(.19,.98),(.02,.73)],
 27:[(.12,.16),(.44,.08),(.76,.13),(.89,.36),(.88,.66),(.70,.87),(.32,.92),(.12,.73),(.06,.45)],
 28:[(.09,.03),(.96,.03),(.98,.95),(.13,.98),(.02,.62)],
 29:[(.03,.13),(.84,.06),(.98,.33),(.98,.82),(.78,.95),(.07,.92)],
 30:[(.05,.04),(.69,.03),(.96,.27),(.98,.73),(.83,.96),(.25,.96),(.03,.71)],
 32:[(.36,.08),(.63,.13),(.76,.39),(.72,.67),(.62,.88),(.44,.96),(.30,.75),(.30,.43)],
 34:[(.03,.03),(.97,.03),(.98,.95),(.03,.98)],
 35:[(.28,.04),(.73,.02),(.81,.29),(.76,.66),(.68,.95),(.29,.97),(.16,.72),(.19,.34)],
 36:[(.03,.10),(.74,.03),(.98,.24),(.98,.83),(.82,.97),(.10,.97),(.02,.63)],
 37:[(.33,.02),(.72,.01),(.76,.21),(.64,.41),(.59,.58),(.56,.78),(.48,.98),(.32,.97),(.34,.76),(.31,.53),(.37,.30)],
 38:[(.11,.27),(.50,.10),(.79,.05),(.91,.24),(.91,.65),(.75,.94),(.40,.93),(.16,.79),(.03,.54)],
 39:[(.39,.02),(.72,.02),(.73,.36),(.83,.74),(.66,.94),(.38,.97),(.25,.76),(.24,.39)],
 40:[(.16,.24),(.41,.03),(.80,.02),(.97,.25),(.92,.75),(.73,.98),(.35,.96),(.10,.77),(.04,.47)],
 41:[(.15,.08),(.49,.03),(.80,.07),(.90,.37),(.84,.66),(.73,.96),(.35,.96),(.12,.80),(.06,.43)],
 42:[(.44,.01),(.75,.01),(.70,.24),(.60,.43),(.58,.67),(.61,.97),(.36,.98),(.36,.70),(.40,.46),(.40,.26)],
 43:[(.04,.19),(.36,.03),(.86,.05),(.97,.31),(.90,.69),(.73,.91),(.41,.98),(.12,.81),(.02,.50)],
 61:[(.03,.01),(.38,.01),(.60,.22),(.81,.42),(.94,.58),(.95,.91),(.78,.98),(.62,.80),(.51,.57),(.27,.37),(.05,.21)],
 81:[(.36,.03),(.77,.02),(.92,.25),(.84,.65),(.79,.95),(.35,.97),(.10,.74),(.07,.46)],
 101:[(.28,.03),(.80,.03),(.86,.28),(.83,.72),(.72,.98),(.32,.97),(.17,.76),(.20,.49),(.16,.24)],
 121:[(.49,.01),(.97,.01),(.98,.97),(.40,.98),(.27,.81),(.25,.52),(.44,.41),(.43,.22)],
 141:[(.03,.02),(.62,.02),(.82,.21),(.74,.43),(.76,.73),(.59,.94),(.18,.97),(.02,.80)],
 161:[(.04,.02),(.46,.02),(.52,.30),(.59,.49),(.65,.61),(.62,.78),(.49,.97),(.16,.98),(.03,.77)],
 181:[(.19,.02),(.76,.01),(.94,.23),(.91,.56),(.78,.91),(.47,.95),(.22,.78),(.02,.48)],
 182:[(.30,.03),(.62,.01),(.72,.17),(.66,.45),(.73,.72),(.73,.98),(.32,.98),(.25,.76),(.27,.46)],
 201:[(.09,.25),(.26,.10),(.52,.07),(.77,.14),(.91,.34),(.94,.62),(.81,.87),(.56,.96),(.31,.90),(.10,.73),(.05,.48)],
 241:[(.12,.29),(.35,.09),(.67,.08),(.85,.25),(.92,.64),(.78,.86),(.42,.94),(.15,.80),(.07,.51)],
 261:[(.16,.10),(.43,.03),(.80,.10),(.92,.38),(.86,.79),(.64,.97),(.28,.96),(.10,.72),(.08,.39)],
 281:[(.30,.01),(.69,.01),(.74,.24),(.87,.45),(.79,.68),(.64,.97),(.35,.97),(.19,.78),(.21,.42)],
 501:[(.03,.11),(.43,.02),(.86,.03),(.97,.33),(.97,.87),(.71,.97),(.25,.95),(.03,.73)],
 502:[(.30,.04),(.54,.01),(.64,.14),(.77,.27),(.75,.43),(.68,.53),(.70,.76),(.61,.94),(.47,.97),(.33,.81),(.29,.60),(.36,.35)],
 504:[(.19,.14),(.48,.03),(.72,.14),(.73,.35),(.92,.45),(.89,.67),(.73,.90),(.47,.98),(.33,.75),(.22,.48)],
 505:[(.24,.44),(.41,.31),(.61,.33),(.75,.50),(.76,.91),(.63,.97),(.49,.90),(.34,.82),(.20,.68)],
 507:[(.35,.10),(.62,.03),(.72,.14),(.66,.40),(.65,.73),(.54,.95),(.34,.95),(.29,.72),(.30,.43)],
 510:[(.07,.07),(.59,.03),(.70,.20),(.72,.51),(.82,.73),(.68,.93),(.40,.93),(.30,.75),(.16,.65),(.05,.38)],
 511:[(.23,.25),(.57,.30),(.80,.49),(.76,.78),(.66,.95),(.41,.91),(.35,.60)],
 512:[(.34,.10),(.64,.09),(.74,.28),(.76,.69),(.60,.92),(.36,.92),(.23,.70),(.24,.35)],
 513:[(.05,.60),(.27,.45),(.42,.27),(.64,.16),(.97,.18),(.98,.70),(.77,.90),(.41,.95),(.09,.88)],
 684:[(.27,.02),(.68,.02),(.76,.25),(.74,.58),(.69,.92),(.37,.98),(.21,.78),(.22,.49)],
 685:[(.29,.28),(.48,.10),(.70,.23),(.76,.56),(.80,.85),(.64,.97),(.36,.93),(.20,.77),(.14,.49)],
 686:[(.10,.08),(.70,.02),(.94,.21),(.96,.72),(.75,.97),(.32,.97),(.10,.76),(.04,.39)],
 699:[(.11,.23),(.36,.08),(.68,.03),(.91,.22),(.96,.64),(.81,.92),(.49,.98),(.18,.81),(.04,.49)],
}
def source_maps():
    report=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json').read_text(encoding='utf-8'))
    originals={m['id']:m for m in json.loads((STAGING/'maps.json').read_text(encoding='utf-8'))}
    maps=report['maps']
    for m in maps:
        m['rect']=rect(m,report['transforms'])
        m['original']=originals[m['id']]
    return maps


def write_geography(maps):
    """Keep original numbers, remove the obsolete per-page texture catalog."""
    source=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json').read_text(encoding='utf-8'))
    transforms={int(k):v for k,v in source['transforms'].items()}
    keys=('id','map','area','file','name','bounds','kind','city','parent')
    geography=[{k:m.get(k) for k in keys} for m in maps]
    text='-- Original installed-client geography; art is in AtlasData/PresentationData.\n'
    text+='TurtleSeamlessMap_Layout = '+lua(transforms)+'\n'
    text+='TurtleSeamlessMap_Data = '+lua(geography)+'\n'
    write(OUT/'MapData.lua',text.encode('utf-8'))


def rect(m,transforms):
    if m['kind']=='world':return [0,0,1002,668]
    t=transforms[str(m['map'])];b=m['bounds']
    return [t['x']-b[0]*t['scale'],t['y']-b[2]*t['scale'],(b[0]-b[1])*t['scale'],(b[2]-b[3])*t['scale']]


def polygon(points,size=(1002,668)):
    im=Image.new('L',size);ImageDraw.Draw(im).polygon([(round(x*size[0]),round(y*size[1])) for x,y in points],fill=255)
    return im


def masks(m):
    land=polygon(OUTLINES[m['id']])
    explored=Image.new('L',(1024,768))
    for overlay in m['original']['overlays']:
        cols=(overlay['width']+255)//256
        for i,path in enumerate(overlay['paths']):
            x,y=(i%cols)*256,(i//cols)*256
            a=decode_blp((STAGING/'raw'/path.replace('\\','/')).read_bytes()).convert('RGBA').getchannel('A')
            a=a.crop((0,0,min(256,overlay['width']-x),min(256,overlay['height']-y)))
            layer=Image.new('L',explored.size);layer.paste(a,(overlay['x']+x,overlay['y']+y))
            explored=ImageChops.lighter(explored,layer)
    explored=explored.crop((0,0,1002,668))
    # An exploration piece can extend to the source page frame. It is NOT an
    # unconditional paint silhouette: retain it only near the reviewed terrain.
    core=ImageChops.lighter(land,ImageChops.multiply(explored,land.filter(ImageFilter.MaxFilter(21))))
    # Keep complete painting beyond the land, including shore hatch and islets.
    paint=core.filter(ImageFilter.MaxFilter(29)).filter(ImageFilter.GaussianBlur(13))
    # Paper frames extend much farther than their final dark pixel. Smoothly
    # replace that border band with adjacent atlas art rather than baking cards.
    yy,xx=np.mgrid[:668,:1002]
    distance=np.minimum.reduce((xx,yy,1001-xx,667-yy))
    weight=np.clip((distance-4)/40,0,1);weight=weight*weight*(3-2*weight)
    frame=Image.fromarray(np.round(weight*255).astype('uint8'))
    paint=ImageChops.multiply(paint,frame)
    if m['id']==699:
        # Its huge source page has a decorative compass over empty sea.
        decoration=Image.new('L',paint.size,255)
        ImageDraw.Draw(decoration).ellipse((850,45,970,225),fill=0)
        paint=ImageChops.multiply(paint,decoration.filter(ImageFilter.GaussianBlur(8)))
    return land,core,paint


def mirror_patch(image,size):
    w,h=image.size;tile=Image.new(image.mode,(w*2,h*2))
    tile.paste(image,(0,0));tile.paste(image.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(w,0))
    tile.paste(tile.crop((0,0,w*2,h)).transpose(Image.Transpose.FLIP_TOP_BOTTOM),(0,h))
    result=Image.new(image.mode,size)
    for y in range(0,size[1],h*2):
        for x in range(0,size[0],w*2):result.paste(tile,(x,y))
    return result


def background():
    world=Image.open(STAGING/'previews/World.png').convert('RGBA')
    # Remove the OLD mainland AND its coast halo, not the original open-sea art,
    # whirlpool, central island, ships, border or corner illustrations.
    old=Image.new('L',world.size);d=ImageDraw.Draw(old)
    d.polygon([(122,130),(329,97),(371,153),(359,207),(367,262),(327,302),(324,367),(307,421),(319,529),(286,576),(225,553),(180,588),(120,577),(104,533),(132,476),(105,437),(113,379),(112,301),(121,249),(168,216),(167,161)],fill=255)
    d.ellipse((119,67,204,147),fill=255)
    d.polygon([(683,143),(812,131),(855,79),(907,92),(914,146),(872,211),(850,257),(835,281),(872,311),(874,370),(848,417),(832,449),(841,483),(800,520),(747,564),(707,544),(710,505),(680,483),(669,440),(688,397),(668,365),(666,320),(680,285),(658,265),(660,240),(672,221),(655,179)],fill=255)
    old=old.filter(ImageFilter.MaxFilter(31)).filter(ImageFilter.GaussianBlur(5))
    patch=world.crop((425,172,489,244))
    fill=mirror_patch(patch,world.size)
    world=Image.composite(fill,world,old)
    world.save(OUT/'background.png')
    return world


def paste_projected(canvas,image,r,extent,density):
    x,y=round((r[0]-extent[0])*density),round((r[1]-extent[1])*density)
    w,h=round(r[2]*density),round(r[3]*density)
    stamp=image.resize((w,h),Image.Resampling.LANCZOS)
    if canvas.mode=='RGBA':canvas.alpha_composite(stamp,(x,y))
    else:
        layer=Image.new('L',canvas.size);layer.paste(stamp,(x,y));canvas.paste(ImageChops.lighter(canvas,layer))


def tile_level(image,prefix,density,written,sparse=True):
    cols,rows=math.ceil(image.width/INNER),math.ceil(image.height/INNER)
    present={};alpha=image.getchannel('A')
    for row in range(rows):
        for col in range(cols):
            x,y=col*INNER,row*INNER
            a=alpha.crop((x,y,min(x+INNER,image.width),min(y+INNER,image.height)))
            if sparse and not a.getbbox():continue
            # A one-pixel gutter uses the neighbouring atlas pixels, including
            # partial edge tiles. UVs sample only the 254-pixel logical cell.
            tile=image.crop((x-1,y-1,x+255,y+255))
            if not sparse:
                # Clamp outside the global background instead of black padding.
                if x==0:tile.paste(tile.crop((1,0,2,256)),(0,0))
                if y==0:tile.paste(tile.crop((0,1,256,2)),(0,0))
            name=f'{prefix}_{col}_{row}'
            payload=encode_blp(tile);write(OUT/'Art'/(name+'.blp'),payload)
            written.append(dict(file=name+'.blp',sha256=hashlib.sha256(payload).hexdigest()))
            present[row*cols+col+1]=True
    return dict(density=density,cols=cols,rows=rows,tiles=present)


def hit_table(mask):
    small=mask.resize((48,32),Image.Resampling.BOX)
    digits=[]
    for row in range(32):
        for col in range(0,48,4):digits.append(format(sum((1<<k) for k in range(4) if small.getpixel((col+k,row))>64),'x'))
    return [48,32,''.join(digits)]


def grade_edge(native,core):
    """Match the outer paint band, preserving native colours in the interior."""
    inner=core.filter(ImageFilter.MinFilter(45)).filter(ImageFilter.GaussianBlur(12))
    band=(1-np.asarray(inner,dtype=float)/255)*.32
    rgba=np.asarray(native,dtype=float).copy();rgb=rgba[:,:,:3]
    light=rgb.mean(axis=2,keepdims=True)
    shared=np.clip(light*np.array([1.15,.97,.70]),0,255)
    rgba[:,:,:3]=rgb*(1-band[:,:,None])+shared*band[:,:,None]
    return Image.fromarray(np.round(rgba).astype('uint8'))


def audit_minimaps():
    client=Client(ROOT);results={}
    try:
        content,trs_source=client.read('Textures\\Minimap\\md5translate.trs')
        lines=content.decode('utf-8',errors='replace').splitlines()
        for continent in ('Azeroth','Kalimdor'):
            refs={}
            for line in lines:
                match=re.match(re.escape(continent)+r'\\map(\d+)_(\d+)\.blp\s+(\S+)',line,re.I)
                if match:refs[(int(match[1]),int(match[2]))]=match[3]
            failures=[];sources=Counter();sizes=Counter();hashes={}
            preview=Image.new('RGB',(1024,1024),(37,39,38));presence=Image.new('L',preview.size)
            for (x,y),name in refs.items():
                try:
                    data,source=client.read('Textures\\Minimap\\'+name)
                    im=decode_blp(data).convert('RGB');sizes[str(im.size)]+=1;sources[source]+=1
                    hashes[f'{x},{y}']=hashlib.sha256(data).hexdigest()
                    preview.paste(im.resize((16,16)),(x*16,y*16))
                    ImageDraw.Draw(presence).rectangle((x*16,y*16,x*16+15,y*16+15),fill=255)
                except (FileNotFoundError,ValueError,OSError) as e:failures.append(dict(x=x,y=y,error=str(e)))
            preview.save(OUT/(continent+'-terrain-reference.jpg'))
            preview.save(OUT/(continent+'-terrain-reference.png'))
            rgb=np.asarray(preview,dtype=np.int16)
            water=(rgb[:,:,2]>rgb[:,:,0]*1.10+4)&(rgb[:,:,1]>rgb[:,:,0]+4)
            land=Image.fromarray(np.where(water,0,255).astype('uint8'))
            land=ImageChops.multiply(land,presence).filter(ImageFilter.MedianFilter(3))
            land.save(OUT/(continent+'-terrain-land.png'))
            payload,source=client.read('World\\Maps\\'+continent+'\\'+continent+'.wdt')
            terrain=set();off=0
            while off+8<=len(payload):
                tag=payload[off:off+4];size=struct.unpack_from('<I',payload,off+4)[0]
                if tag==b'NIAM':
                    for i,(flags,_) in enumerate(struct.iter_unpack('<II',payload[off+8:off+8+size])):
                        if flags&1:terrain.add((i%64,i//64))
                off+=size+8
            results[continent]=dict(index_source=trs_source,wdt_source=source,indexed=len(refs),decoded=len(hashes),sizes=dict(sizes),sources=dict(sources),failures=failures,wdt_terrain=len(terrain),wdt_without_index=[list(p) for p in sorted(terrain-refs.keys())],hashes=hashes)
    finally:
        for archive in client.archives:archive.close()
    json_write(OUT/'minimap-audit.json',results)
    return results


def build(audit=False):
    (OUT/'Art').mkdir(parents=True,exist_ok=True)
    if audit:audit_minimaps()
    maps=source_maps();outdoor=[m for m in maps if m['kind']=='surface' and not m['city']]
    assert {m['id'] for m in outdoor}==set(OUTLINES)
    written=[];focus={};coverage=[];continents=[]
    native_background=background()
    bg_level=tile_level(native_background.resize((2004,1336),Image.Resampling.LANCZOS),'v4_paper',2,written,False)
    overview=native_background.copy()
    for continent_id in (1,0):
        regions=[m for m in outdoor if m['map']==continent_id]
        regions.sort(key=lambda m:m['rect'][2]*m['rect'][3],reverse=True)
        left=max(0,math.floor(min(m['rect'][0] for m in regions))-28);top=max(0,math.floor(min(m['rect'][1] for m in regions))-28)
        right=min(1002,math.ceil(max(m['rect'][0]+m['rect'][2] for m in regions))+28);bottom=min(668,math.ceil(max(m['rect'][1]+m['rect'][3] for m in regions))+28)
        extent=[left,top,right-left,bottom-top]
        size=(extent[2]*MAX_DENSITY,extent[3]*MAX_DENSITY)
        master=Image.new('RGBA',size);land_union=Image.new('L',(extent[2]*2,extent[3]*2));painted=[]
        for m in regions:
            native=Image.open(STAGING/'previews'/(m['file']+'.png')).convert('RGBA')
            land,core,paint=masks(m);focus[m['id']]=hit_table(core)
            native=grade_edge(native,core);native.putalpha(paint);painted.append((m,native))
            paste_projected(land_union,land,m['rect'],extent,2)
            coverage.append(dict(id=m['id'],file=m['file'],rect=m['rect'],source_sha256=hashlib.sha256((STAGING/'previews'/(m['file']+'.png')).read_bytes()).hexdigest(),exploration_pieces=len(m['original']['overlays']),mask='native-paint-plus-reviewed-outline',land_pixels=int(np.count_nonzero(np.asarray(land))),paint_pixels=int(np.count_nonzero(np.asarray(paint))),core_pixels=int(np.count_nonzero(np.asarray(core)))))
        # Only close short breaks and enclosed holes INSIDE the collected land
        # artwork. Never use the old coarse continent's silhouette as a fallback.
        name='Azeroth' if continent_id==0 else 'Kalimdor'
        terrain_file=OUT/(name+'-terrain-land.png')
        if terrain_file.exists():
            transforms=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json').read_text(encoding='utf-8'))['transforms']
            transform=transforms[str(continent_id)];k=16/((1600/3)*transform['scale'])
            physical=Image.open(terrain_file).transform(land_union.size,Image.Transform.AFFINE,(k/2,0,512+(left-transform['x'])*k,0,k/2,512+(top-transform['y'])*k),Image.Resampling.NEAREST)
            # Old/developer mini tiles can share this continent. Limit the
            # reference to a 25-world-unit band around retained playable maps.
            vicinity=land_union.filter(ImageFilter.MaxFilter(101))
            physical=ImageChops.multiply(physical,vicinity)
            land_union=ImageChops.lighter(land_union,physical)
        # A wide closing would join Teldrassil to Darkshore across real water.
        # Close at most one world unit, preserving every actual island channel.
        target=land_union.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
        outside=target.point(lambda p:255 if p>32 else 0)
        ImageDraw.floodfill(outside,(0,0),128)
        target=ImageChops.lighter(target,outside.point(lambda p:255 if p==0 else 0))
        target=target.filter(ImageFilter.GaussianBlur(1))
        paper=Image.open(STAGING/'previews/Silithus.png').convert('RGB').crop((850,230,946,318))
        grain=np.asarray(paper,dtype=float)
        grain=np.clip(grain-grain.mean(axis=(0,1))+np.array([175,146,99]),0,255).astype('uint8')
        paper=Image.fromarray(grain).filter(ImageFilter.GaussianBlur(.5)).convert('RGBA')
        mountains=Image.open(STAGING/'previews/Silithus.png').convert('RGB').crop((720,435,800,515)).resize(paper.size,Image.Resampling.LANCZOS)
        ridge=np.asarray(mountains,dtype=float)
        ridge=np.clip(ridge-ridge.mean(axis=(0,1))+np.array([175,146,99]),0,255).astype('uint8')
        # Hand-drawn mountain strokes only decorate otherwise unpainted land;
        # they do not define new playable terrain or introduce map landmarks.
        paper=Image.blend(paper,Image.fromarray(ridge).convert('RGBA'),.18)
        # This is map paper in unpainted seam bands, not invented terrain/roads.
        fill=mirror_patch(paper.resize((256,256),Image.Resampling.BICUBIC),size)
        fill.putalpha(target.resize(size,Image.Resampling.BILINEAR));master=Image.alpha_composite(master,fill);del fill
        for m,native in painted:paste_projected(master,native,m['rect'],extent,MAX_DENSITY)
        del painted
        master.save(OUT/f'continent-{continent_id}-master.png')
        levels=[]
        for density in DENSITIES:
            scaled=master if density==MAX_DENSITY else master.resize((extent[2]*density,extent[3]*density),Image.Resampling.LANCZOS)
            levels.append(tile_level(scaled,f'v4_c{continent_id}_{density}',density,written))
        thumb=master.resize((extent[2],extent[3]),Image.Resampling.LANCZOS)
        overview.alpha_composite(thumb,(left,top))
        continents.append(dict(id=continent_id,rect=extent,levels=levels))
        print('Built continent',continent_id,size,'tiles',sum(len(l['tiles']) for l in levels),flush=True)
        del master
    cities={}
    for m in maps:
        if not m['city']:continue
        native=Image.open(STAGING/'previews'/(m['file']+'.png')).convert('RGBA');mask=city_mask(m['id']);native.putalpha(mask)
        focus[m['id']]=hit_table(mask)
        tiles=[]
        for row in range(3):
            for col in range(4):
                x,y=col*256,row*256;w,h=min(256,1002-x),min(256,668-y)
                tile=Image.new('RGBA',(256,256));tile.paste(native.crop((x,y,x+w,y+h)),(0,0))
                name=f'v4_city_{m["id"]}_{row*4+col+1}';payload=encode_blp(tile);write(OUT/'Art'/(name+'.blp'),payload)
                written.append(dict(file=name+'.blp',sha256=hashlib.sha256(payload).hexdigest()));tiles.append([name,x,y,w,h])
        cities[m['id']]=dict(width=1002,height=668,x=0,y=0,tiles=tiles)
    atlas=dict(version=4,inner=INNER,gutter=1,tileSize=256,background=dict(rect=[0,0,1002,668],level=bg_level),continents=continents)
    write_geography(maps)
    write(OUT/'AtlasData.lua',('-- Generated coordinate-locked tile pyramid; Tools/build_turtle_map_atlas.py.\nTurtleSeamlessMap_Atlas = '+lua(atlas)+'\n').encode('utf-8'))
    write(OUT/'PresentationData.lua',('-- Native city cutouts over the continuous atlas; coordinates unchanged.\nTurtleSeamlessMap_Presentation = '+lua(dict(cities=cities))+'\n').encode('utf-8'))
    write(OUT/'FocusData.lua',('-- Geographic/paint hit approximations, separate from atlas tile coverage.\nTurtleSeamlessMap_Focus = '+lua(focus)+'\n').encode('utf-8'))
    overview.convert('RGB').save(OUT/'world-preview.jpg')
    report=dict(version='0.3.0',density_levels=list(DENSITIES),tile_size=SIZE,inner=INNER,gutter=1,outdoor_maps=len(outdoor),cities=len(cities),coordinates_unchanged=True,regions=coverage,continents=continents,files=written,total_files=len(written),total_bytes=sum((OUT/'Art'/r['file']).stat().st_size for r in written),background='original world paper, whirlpool and ornaments; old mainlands removed; native sea patch extension',seam_fill='native parchment and faint mountain strokes in unpainted land bands; no added roads or settlements; minimap colour land estimate constrained near retained geography, not server territory')
    if (OUT/'minimap-audit.json').exists():
        report['minimap_audit']=json.loads((OUT/'minimap-audit.json').read_text(encoding='utf-8'))
    expected={r['file'] for r in written}
    art=(OUT/'Art').resolve()
    assert art.is_relative_to(STAGING.resolve())
    for path in art.glob('v4_*.blp'):
        if path.name not in expected:
            assert path.resolve().parent==art
            path.unlink()
    json_write(OUT/'manifest.json',report)
    print('Candidate complete',report['total_files'],report['total_bytes'],flush=True)


def deploy():
    """Install only a fully hashed, reviewed candidate; raw extraction stays put."""
    report=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
    expected={r['file'] for r in report['files']}
    assert expected=={p.name for p in (OUT/'Art').glob('*.blp')}
    for r in report['files']:
        assert re.fullmatch(r'v4_(?:paper|city_\d+|c[01]_\d+)_\d+(?:_\d+)?\.blp',r['file']),r['file']
        payload=(OUT/'Art'/r['file']).read_bytes()
        assert hashlib.sha256(payload).hexdigest()==r['sha256']
        assert decode_blp(payload).size==(256,256)
    art=(ADDON/'Art').resolve()
    assert art.is_relative_to((ROOT/'Interface/AddOns/TurtleSeamlessMap').resolve())
    obsolete=[p for p in art.glob('*.blp') if p.name not in expected]
    for p in obsolete:
        assert p.resolve().parent==art
        assert p.name=='SeaPaper.blp' or re.fullmatch(r'v[234]_(?:(?:back|sea|city)_)?[\d_]+\.blp',p.name),p.name
    for name in expected:shutil.copyfile(OUT/'Art'/name,art/name)
    for name in ('MapData.lua','AtlasData.lua','PresentationData.lua','FocusData.lua'):shutil.copyfile(OUT/name,ADDON/name)
    for p in obsolete:p.unlink()
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.3.0资源-20261024.json',report)
    print('Installed reviewed candidate:',len(expected),'art files;',len(obsolete),'obsolete derived files removed')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--audit',action='store_true')
    parser.add_argument('--deploy-reviewed',action='store_true',help='Install the already generated and visually reviewed candidate instead of rebuilding')
    args=parser.parse_args()
    if args.deploy_reviewed:deploy()
    else:build(args.audit)
