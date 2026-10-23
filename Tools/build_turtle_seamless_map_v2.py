"""Build the outdoor-only atlas from the preserved, verified client extraction.

The v1 extraction evidence is immutable. This writes a separate v2 manifest.
No retail geography, generated terrain, or source archives are modified.
"""
import json
import re
import struct
import numpy as np
from collections import Counter
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from build_turtle_seamless_map import ROOT, ADDON, STAGING, decode_blp, encode_blp, lua, write, json_write
from turtle_map_archive import dbc

EXCLUDED = {500: 'GM area', 514: 'entrance', 516: 'entrance', 517: 'entrance',
            518: 'entrance', 519: 'indoor corridor', 520: 'entrance', 521: 'entrance',
            522: 'entrance', 523: 'cave', 689: 'entrance', 700: 'tunnel',
            701: 'entrance', 705: 'entrance'}
PARENTS = {301: 30, 321: 4, 341: 27, 362: 9, 381: 41, 382: 20, 509: 513}


def build():
    maps = json.loads((STAGING/'maps.json').read_text(encoding='utf-8'))
    rows, _, fields = dbc((STAGING/'dbc/WorldMapContinent.dbc').read_bytes())
    assert fields == 13
    transforms = {}
    for row in rows:
        if row[1] in (0, 1):
            ox, oy, scale = struct.unpack('<3f', struct.pack('<3I', *row[6:9]))
            # World presentation: 64 ADT widths, with the native 1002:668 aspect.
            unit = 1002/64
            transforms[row[1]] = dict(x=501+ox*unit, y=334+oy*unit,
                                      scale=scale*unit/(1600/3))
    runtime, expected = [], set()
    backings = {}
    for m in maps:
        if m['file'] in ('Kalimdor', 'Azeroth'):
            backings[m['map']] = (m, Image.new('L', (1002, 668)))

    def tiles(image, prefix):
        result = []
        for row in range(3):
            for col in range(4):
                x, y = col*256, row*256
                w, h = min(256,1002-x), min(256,668-y)
                tile = Image.new('RGBA',(256,256))
                tile.paste(image.crop((x,y,x+w,y+h)),(0,0))
                name = prefix+'_'+str(row*4+col+1)
                payload = encode_blp(tile)
                check = decode_blp(payload).getchannel('A')
                assert ImageChops.difference(check,tile.getchannel('A')).getextrema()[1] <= 9
                write(ADDON/'Art'/(name+'.blp'),payload)
                expected.add(name+'.blp')
                result.append([name,x,y,w,h])
        return result

    for m in maps:
        world = m['file']=='World'
        continent = m['file'] in ('Kalimdor','Azeroth')
        surface = m['map'] in (0,1) and m['area']>0 and m['id'] not in EXCLUDED
        if not (world or continent or surface):
            continue
        assert m['complete']
        record = {k:m[k] for k in ('id','map','area','file','name','bounds')}
        record.update(kind='world' if world else 'continent' if continent else 'surface',
                      city=m['id'] in PARENTS, parent=PARENTS.get(m['id']), tiles=[])
        image = Image.open(STAGING/'previews'/(m['file']+'.png')).convert('RGBA')
        if surface:
            # Reuse original explored-area alpha; retain all painted zone content.
            # Source previews remain complete and unchanged in local extraction.
            alpha = Image.new('L',(1024,768))
            for overlay in m['overlays']:
                cols = (overlay['width']+255)//256
                for i,path in enumerate(overlay['paths']):
                    x,y = (i%cols)*256,(i//cols)*256
                    tile = decode_blp((STAGING/'raw'/path.replace('\\','/')).read_bytes()).convert('RGBA')
                    tile = tile.crop((0,0,min(256,overlay['width']-x),min(256,overlay['height']-y)))
                    layer = Image.new('L',alpha.size)
                    layer.paste(tile.getchannel('A'),(overlay['x']+x,overlay['y']+y))
                    alpha = ImageChops.lighter(alpha,layer)
            alpha = alpha.crop((0,0,1002,668))
            if not m['overlays']:
                alpha = Image.new('L',image.size,255)
            alpha = alpha.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(2))
            edge = Image.new('L',image.size)
            draw = ImageDraw.Draw(edge)
            draw.rounded_rectangle((6,6,995,661),radius=60 if record['city'] else 12,fill=255)
            edge = edge.filter(ImageFilter.GaussianBlur(12 if record['city'] else 5))
            image.putalpha(ImageChops.multiply(alpha,edge))
            if not record['city']:
                cm,mask = backings[m['map']]
                b,c = m['bounds'],cm['bounds']
                sx,sy = 1002/(c[0]-c[1]),668/(c[2]-c[3])
                x,y = round((c[0]-b[0])*sx),round((c[2]-b[2])*sy)
                w,h = max(1,round((b[0]-b[1])*sx)),max(1,round((b[2]-b[3])*sy))
                layer = Image.new('L',mask.size)
                layer.paste(image.getchannel('A').resize((w,h)),(x,y))
                backings[m['map']] = (cm,ImageChops.lighter(mask,layer))
        record['tiles'] = tiles(image,'v2_'+str(m['id']))
        if world:
            # Use this client's sea palette with deterministic subtle grain,
            # without copying a wave/letter into an obvious repeating pattern.
            sample = np.asarray(image.crop((520,180,584,244)).convert('RGB'),dtype=float)
            palette = sample.mean(axis=(0,1))
            rng = np.random.default_rng(118)
            grain = Image.fromarray(rng.integers(0,256,(24,32),dtype=np.uint8))
            field = np.asarray(grain.resize(image.size,Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(12)),dtype=float)
            noise = (field-128)*0.035+rng.normal(0,1.2,(668,1002))
            sea = Image.fromarray(np.clip(palette+noise[:,:,None],0,255).astype('uint8')).convert('RGBA')
            record['sea'] = tiles(sea,'v2_sea_'+str(m['id']))
        runtime.append(record)

    for record in runtime:
        if record['kind']!='continent':
            continue
        cm,mask = backings[record['map']]
        # Close narrow gaps and fill enclosed unpainted land using this client's
        # own continent art. Ocean stays the native world background; no retail
        # zone is substituted for Turtle geography. Work at half size for speed.
        mask = mask.resize((501,334)).point(lambda a:255 if a>24 else 0)
        mask = mask.filter(ImageFilter.MaxFilter(17)).filter(ImageFilter.MinFilter(9))
        outside = mask.copy()
        ImageDraw.floodfill(outside,(0,0),128)
        holes = outside.point(lambda a:255 if a==0 else 0)
        mask = ImageChops.lighter(mask,holes).filter(ImageFilter.GaussianBlur(3)).resize((1002,668))
        image = Image.open(STAGING/'previews'/(record['file']+'.png')).convert('RGBA')
        rgb = np.asarray(image,dtype=np.int16)
        # The continent's warm land paint differs from its grey sea hatching.
        # This trims the expanded backing to native land instead of magnifying
        # the continent ocean's coarse labels/wave lines beneath close zone art.
        land = Image.fromarray(np.where(rgb[:,:,0]-rgb[:,:,2]>65,255,0).astype('uint8'))
        # Opening removes thin sea hatch lines and labels before expanding the
        # solid land. Closing here would join those lines into a solid ocean.
        land = land.filter(ImageFilter.MinFilter(9)).filter(ImageFilter.MaxFilter(13))
        mask = ImageChops.multiply(mask,land.filter(ImageFilter.GaussianBlur(2)))
        image.putalpha(mask)
        record['backing'] = tiles(image,'v2_back_'+str(record['id']))
        image.save(STAGING/('v2-backing-'+record['file']+'.png'))

    art = (ADDON/'Art').resolve()
    for path in art.glob('*.blp'):
        if path.name not in expected:
            assert path.resolve().parent==art and re.fullmatch(r'(?:\d+|v2_(?:(?:back|sea)_)?\d+)_\d+',path.stem)
            path.unlink()
    data = '-- Generated by Tools/build_turtle_seamless_map_v2.py; installed client data.\n'
    data += 'TurtleSeamlessMap_Layout = '+lua(transforms)+'\n'
    data += 'TurtleSeamlessMap_Data = '+lua(runtime)+'\n'
    write(ADDON/'MapData.lua',data.encode('utf-8'))
    report = dict(version='0.2.0',runtime_maps=len(runtime),kinds=dict(Counter(m['kind'] for m in runtime)),
                  outdoor=sum(m['kind']=='surface' and not m['city'] for m in runtime),
                  cities=sum(m['city'] for m in runtime),transforms=transforms,
                  projection='client WorldMapContinent offset/scale; 64 ADT world presentation, 1002:668',
                  excluded=[dict(id=m['id'],file=m['file'],reason=EXCLUDED.get(m['id'],'instance or unused page')) for m in maps if m['id'] not in {r['id'] for r in runtime}],
                  maps=[{k:v for k,v in m.items() if k not in ('tiles','backing')} for m in runtime],
                  derived_tiles=len(expected),derived_bytes=sum((art/n).stat().st_size for n in expected),
                  source_extraction_maps=len(maps),source_extraction_unchanged=True)
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json',report)
    print(json.dumps({k:v for k,v in report.items() if k not in ('maps','excluded')},ensure_ascii=False,indent=2))


if __name__=='__main__':
    build()
