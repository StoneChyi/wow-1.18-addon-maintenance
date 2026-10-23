"""Bake city cutouts with local outdoor context and a tiled parchment sea.

Uses the preserved Turtle extraction and existing outdoor atlas only. City
coordinates stay unchanged; only the art extends past the original page.
"""
import hashlib
import json
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter
from build_turtle_seamless_map import ROOT, ADDON, STAGING, decode_blp, encode_blp, lua, write, json_write

# Normalized outlines follow this client's city art, excluding page frames,
# corner emblems, blank margins and title ribbons. These are not retail shapes.
CITY_OUTLINES = {
    301: [(.20,.07),(.39,.08),(.41,.22),(.53,.24),(.60,.31),(.68,.24),(.79,.23),(.88,.33),(.82,.44),(.88,.58),(.86,.73),(.81,.92),(.71,.96),(.57,.89),(.47,.95),(.33,.88),(.30,.76),(.27,.64),(.20,.53),(.20,.35),(.17,.21)],
    321: [(.70,.015),(.83,.035),(.88,.15),(.82,.33),(.74,.39),(.62,.44),(.59,.57),(.60,.72),(.63,.84),(.61,.98),(.49,.98),(.47,.87),(.34,.94),(.30,.83),(.35,.67),(.26,.60),(.17,.65),(.12,.53),(.17,.47),(.29,.52),(.39,.64),(.43,.54),(.37,.42),(.32,.34),(.32,.27),(.49,.27),(.59,.30),(.62,.18),(.62,.08)],
    341: [(.26,.01),(.57,.01),(.78,.12),(.79,.29),(.75,.43),(.90,.47),(.90,.59),(.76,.61),(.75,.80),(.80,.94),(.68,.99),(.48,.97),(.32,.95),(.17,.91),(.12,.78),(.19,.63),(.14,.46),(.18,.24)],
    362: [(.22,.07),(.38,.08),(.43,.20),(.54,.29),(.69,.25),(.76,.16),(.84,.16),(.85,.29),(.76,.36),(.67,.39),(.64,.50),(.62,.65),(.65,.87),(.58,.98),(.48,.94),(.47,.82),(.44,.72),(.34,.71),(.29,.63),(.32,.46),(.30,.33),(.20,.28),(.16,.17)],
    381: [(.35,.01),(.64,.01),(.75,.10),(.75,.30),(.73,.39),(.89,.31),(.94,.31),(.94,.43),(.78,.43),(.72,.46),(.75,.65),(.73,.78),(.67,.94),(.61,.99),(.36,.99),(.26,.91),(.23,.74),(.24,.54),(.18,.45),(.08,.47),(.05,.38),(.19,.37),(.28,.29),(.29,.17)],
    382: [(.14,.29),(.29,.27),(.38,.24),(.43,.22),(.43,.16),(.49,.10),(.58,.11),(.61,.01),(.70,.01),(.72,.13),(.83,.03),(.91,.06),(.92,.22),(.94,.31),(.91,.47),(.91,.77),(.85,.87),(.65,.89),(.49,.93),(.43,.82),(.41,.65),(.38,.43),(.25,.43),(.14,.38)],
    509: [(.54,.04),(.64,.05),(.65,.17),(.60,.26),(.64,.37),(.77,.39),(.88,.44),(.91,.56),(.85,.66),(.75,.72),(.78,.86),(.69,.93),(.52,.94),(.39,.88),(.25,.87),(.20,.78),(.25,.66),(.28,.55),(.36,.52),(.38,.43),(.35,.34),(.38,.29),(.49,.30),(.51,.20)],
}
CITY_RIBBONS = {301:(.37,.02,.70,.14),321:(.20,.20,.62,.31),341:(.28,.89,.69,.99),
                362:(.37,.015,.65,.14),381:(.31,.90,.76,.99),382:(.45,.79,.87,.94),509:(.30,.88,.74,.98)}
WIDTH,HEIGHT,OFFSET_X,OFFSET_Y = 1504,1004,-251,-168


def city_mask(map_id):
    mask=Image.new('L',(1002,668))
    draw=ImageDraw.Draw(mask)
    draw.polygon([(round(x*1002),round(y*668)) for x,y in CITY_OUTLINES[map_id]],fill=255)
    if map_id==301:
        # The port label lies over painted water, outside the district outline.
        draw.rectangle((94,216,263,258),fill=255)
    r=CITY_RIBBONS[map_id]
    draw.rectangle((round(r[0]*1002),round(r[1]*668),round(r[2]*1002),round(r[3]*668)),fill=0)
    # Keep visible streets/docks fully opaque; soften outside the outline.
    return mask.filter(ImageFilter.MaxFilter(13)).filter(ImageFilter.GaussianBlur(7))


def sea_paper():
    rng=np.random.default_rng(112022)
    patch=Image.fromarray(rng.integers(0,256,(16,16),dtype=np.uint8)).resize((128,128),Image.Resampling.BICUBIC)
    patch=patch.filter(ImageFilter.GaussianBlur(7))
    # Mirror the low-frequency paper so opposite texture edges join exactly.
    field=Image.new('L',(256,256))
    field.paste(patch,(0,0));field.paste(patch.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(128,0))
    field.paste(field.crop((0,0,256,128)).transpose(Image.Transpose.FLIP_TOP_BOTTOM),(0,128))
    noise=(np.asarray(field,dtype=float)-128)*.14+rng.normal(0,1.5,(256,256))
    rgb=np.clip(np.array([123,151,146])+noise[:,:,None],0,255).astype('uint8')
    image=Image.fromarray(rgb).convert('RGBA')
    waves=Image.new('RGBA',image.size)
    draw=ImageDraw.Draw(waves)
    for row in range(0,256,16):
        for col in range(-48,256,64):
            x=col+(row//16%2)*27
            draw.arc((x,row-3,x+39,row+4),5,165,fill=(65,98,92,80),width=1)
            draw.line((x+6,row+5,x+29,row+5),fill=(190,201,175,40),width=1)
    image=Image.alpha_composite(image,waves);image.putalpha(255)
    return image


def atlas(record):
    canvas=Image.new('RGBA',(1002,668))
    for i in range(12):
        tile=decode_blp((ADDON/'Art'/f"v2_{record['id']}_{i+1}.blp").read_bytes()).convert('RGBA')
        canvas.paste(tile,((i%4)*256,(i//4)*256))
    return canvas


def build():
    source=json.loads((ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json').read_text(encoding='utf-8'))
    records=source['maps'];by_id={m['id']:m for m in records}
    outdoor=[m for m in records if m['kind']=='surface' and not m['city']]
    outdoor.sort(key=lambda m:(m['bounds'][0]-m['bounds'][1])*(m['bounds'][2]-m['bounds'][3]),reverse=True)
    cache={};metadata={};written=[]
    art=(ADDON/'Art').resolve()
    def save(image,name):
        payload=encode_blp(image)
        decoded=decode_blp(payload).convert('RGBA')
        assert ImageChops.difference(image.getchannel('A'),decoded.getchannel('A')).getextrema()[1]<=9
        write(art/(name+'.blp'),payload);written.append(dict(file=name+'.blp',sha256=hashlib.sha256(payload).hexdigest()))
    save(sea_paper(),'SeaPaper')
    for city_id in CITY_OUTLINES:
        city=by_id[city_id];b=city['bounds']
        context=Image.new('RGBA',(WIDTH,HEIGHT))
        # An offline crop of nearby outdoor art is part of this ONE city atlas;
        # no adjacent detail layer or quest table is loaded at runtime.
        for region in outdoor:
            if region['map']!=city['map']:continue
            c=region['bounds']
            a=(b[0]-b[1])/(c[0]-c[1])
            d=(b[2]-b[3])/(c[2]-c[3])
            tx=(c[0]-b[0])/(c[0]-c[1])*1002+OFFSET_X*a
            ty=(c[2]-b[2])/(c[2]-c[3])*668+OFFSET_Y*d
            if tx>=1002 or ty>=668 or tx+WIDTH*a<=0 or ty+HEIGHT*d<=0:continue
            if region['id'] not in cache:
                native=atlas(region)
                # Do not enlarge the parent's city sketch/title round the
                # detailed street map. Use its smooth terrain colour field;
                # its original alpha still keeps land, coasts and sea separate.
                smooth=native.convert('RGB').filter(ImageFilter.GaussianBlur(18)).convert('RGBA')
                smooth.putalpha(native.getchannel('A'));cache[region['id']]=smooth
            stamp=cache[region['id']].transform((WIDTH,HEIGHT),Image.Transform.AFFINE,(a,0,tx,0,d,ty),Image.Resampling.BICUBIC)
            context=Image.alpha_composite(context,stamp)
        # Context fades away on a broad, softly rounded perimeter, well beyond
        # the city page. It never creates another visible rectangular page.
        yy,xx=np.mgrid[:HEIGHT,:WIDTH]
        radius=((xx-WIDTH/2)/(WIDTH*.49))**4+((yy-HEIGHT/2)/(HEIGHT*.49))**4
        edge=Image.fromarray(np.clip((1-radius)*255*2,0,255).astype('uint8')).filter(ImageFilter.GaussianBlur(18))
        context.putalpha(ImageChops.multiply(context.getchannel('A'),edge))
        native=Image.open(STAGING/'previews'/(city['file']+'.png')).convert('RGBA')
        native.putalpha(city_mask(city_id))
        context.alpha_composite(native,(-OFFSET_X,-OFFSET_Y))
        context.save(STAGING/f"v3-city-{city['file']}.png")
        tiles=[]
        for y in range(0,HEIGHT,256):
            for x in range(0,WIDTH,256):
                w,h=min(256,WIDTH-x),min(256,HEIGHT-y)
                tile=Image.new('RGBA',(256,256));tile.paste(context.crop((x,y,x+w,y+h)),(0,0))
                name=f"v3_city_{city_id}_{len(tiles)+1}";save(tile,name)
                tiles.append([name,x,y,w,h])
        metadata[city_id]=dict(width=WIDTH,height=HEIGHT,x=OFFSET_X,y=OFFSET_Y,tiles=tiles)
    # Delete only the explicitly superseded generated city/flat-sea files.
    # Original lossless previews and all source art remain untouched.
    for prefix in [f'v2_{i}_' for i in CITY_OUTLINES]+['v2_sea_694_']:
        for index in range(1,13):
            path=art/(prefix+str(index)+'.blp')
            assert path.resolve().parent==art
            if path.exists():path.unlink()
    data='-- Generated by Tools/build_turtle_map_presentation.py from Turtle client art.\n'
    data+='TurtleSeamlessMap_Presentation = '+lua(dict(cities=metadata,sea='SeaPaper',seaTile=128))+'\n'
    write(ADDON/'PresentationData.lua',data.encode('utf-8'))
    report=dict(version='0.2.2',city_pages=7,city_tiles=sum(len(c['tiles']) for c in metadata.values()),
                sea_tiles=1,city_extent=[OFFSET_X,OFFSET_Y,WIDTH,HEIGHT],written=written,
                total_art_files=len(list(art.glob('*.blp'))),total_art_bytes=sum(p.stat().st_size for p in art.glob('*.blp')))
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.2资源-20261024.json',report)
    print({k:v for k,v in report.items() if k!='written'})


if __name__=='__main__':build()
