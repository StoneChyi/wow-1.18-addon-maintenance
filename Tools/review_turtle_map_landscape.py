"""Read-only visual review of a candidate or installed landscape release.

Produces region, geographic-grid and finding contact sheets outside the addon.
Lua UI simulation is explicitly not a running-game rendering/performance test.
"""
import argparse
import html
import json
import math
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent/'tests'))
from test_turtle_seamless_map import runtime
from build_turtle_map_atlas import source_maps
from rebuild_turtle_map_landscape import OUT as CANDIDATE, OLD, PREVIOUS, PLAN, ADDON, box_for, decode_blp

FONT = ImageFont.truetype('C:/Windows/Fonts/msyh.ttc', 18)


def paint(lua):
    m = lua.globals().M; canvas = Image.new('RGBA', (int(m.canvas.width), int(m.canvas.height)))
    entries = [(i, m.tiles[i]) for i in range(1, int(m.tileUsed)+1)]
    entries.sort(key=lambda pair: (pair[1].parent.level, 0 if pair[1].layer == 'BACKGROUND' else 1, pair[0]))
    for _, tile in entries:
        filename = tile.texture.split('\\')[-1]+'.blp'
        path = CANDIDATE/'Art'/filename
        if not path.exists(): path = ADDON/'Art'/filename
        image = decode_blp(path.read_bytes()).convert('RGBA'); uv = tile.uv
        image = image.crop((uv[1]*image.width, uv[3]*image.height, uv[2]*image.width, uv[4]*image.height))
        x, y = round(tile.point[4]), round(-tile.point[5])
        w = max(1, round(tile.point[4]+tile.width)-x); h = max(1, round(-tile.point[5]+tile.height)-y)
        image = image.resize((w, h), Image.Resampling.BILINEAR)
        if tile.alpha != 1: image.putalpha(image.getchannel('A').point(lambda a: round(a*tile.alpha)))
        canvas.alpha_composite(image, (x, y))
    return canvas.convert('RGB')


def board(items, output, size=(560, 430), cols=3):
    canvas = Image.new('RGB', (cols*size[0], math.ceil(len(items)/cols)*(size[1]+38)), (23, 28, 30))
    draw = ImageDraw.Draw(canvas)
    for i, (image, title) in enumerate(items):
        image = image.copy().convert('RGB'); image.thumbnail(size, Image.Resampling.LANCZOS)
        x, y = i % cols*size[0], i//cols*(size[1]+38)
        canvas.paste(image, (x+(size[0]-image.width)//2, y+(size[1]-image.height)//2))
        draw.text((x+6, y+size[1]+4), title[:30], font=FONT, fill='white')
    canvas.save(output, quality=95)


def review(output, baseline=None):
    output.mkdir(parents=True, exist_ok=True)
    for sub in ('details', 'regions', 'grid', 'boards'): (output/sub).mkdir(exist_ok=True)
    plan = json.loads(PLAN.read_text(encoding='utf8'))
    manifest = json.loads((CANDIDATE/'manifest.json').read_text(encoding='utf8'))
    findings = plan['findings']; scenes = {s['id']: s for s in manifest['continents']}
    items = []; html_rows = []
    for cid in (1, 0):
        name = 'Kalimdor' if cid == 1 else 'Azeroth'; rect = scenes[cid]['rect']
        current = Image.open(CANDIDATE/f'{name}-packed.png').convert('RGBA')
        previous = Image.open(PREVIOUS/f'{name}-packed.png').convert('RGBA')
        for finding in (f for f in findings if f['continent'] == cid):
            b = box_for(finding['world_rect'], rect, 32)
            image = current.crop(b); image.thumbnail((1800, 1800)); path = output/'details'/f'{finding["id"]}.jpg'
            image.convert('RGB').save(path, quality=95)
            before = previous.crop(b); before.thumbnail((1800, 1800))
            before.convert('RGB').save(output/'details'/f'{finding["id"]}-before.jpg', quality=95)
            items.append((image, finding['id']+' '+finding['place']))
            finding['after_image'] = path.relative_to(output).as_posix()
            finding['before_image'] = 'details/'+finding['id']+'-before.jpg'
        preview = Image.new('RGBA', current.size, (0, 29, 43, 255)); preview.alpha_composite(current)
        preview.thumbnail((1300, 1900)); preview.convert('RGB').save(output/f'continent-{cid}.jpg', quality=95)
        # Reuse the exact audited 98 windows where available; no unnamed strip
        # disappears from review just because it is not a selectable zone.
        if baseline:
            inventory = json.loads((baseline/'inventory.json').read_text(encoding='utf8'))
            grid = [r for r in inventory['grid'] if r['continent'] == cid]
        else:
            grid = []
            for y in range(rect[1], rect[1]+rect[3], 50):
                for x in range(rect[0], rect[0]+rect[2], 50):
                    r = [x, y, min(50, rect[0]+rect[2]-x), min(50, rect[1]+rect[3]-y)]
                    grid.append(dict(id=f'{cid}-{x}-{y}', rect=r))
        grids = []
        for row in grid:
            tile = current.crop(box_for(row['rect'], rect, 32)); tile.thumbnail((1000, 1000))
            bg = Image.new('RGBA', tile.size, (0, 29, 43, 255)); bg.alpha_composite(tile)
            bg.convert('RGB').save(output/'grid'/f'{row["id"]}.jpg', quality=94)
            grids.append((bg, row['id']))
        for start in range(0, len(grids), 9): board(grids[start:start+9], output/'boards'/f'grid-{cid}-{start//9+1:02d}.jpg', (540, 540))
        print('Geographic review', name, len(grids), flush=True)
    for start in range(0, len(items), 9): board(items[start:start+9], output/'boards'/f'findings-{start//9+1:02d}.jpg')
    lua = runtime(defaults=True)
    lua.execute((CANDIDATE/'TerrainData.lua').read_text(encoding='utf8'))
    lua.execute('M.frame:Show();M.Cursor=function() return -10,-10 end')
    regions = []; cities = []
    for m in source_maps():
        if m['kind'] != 'surface': continue
        lua.execute(f'M:FocusMap({m["id"]});M:Render()')
        image = paint(lua); image.save(output/'regions'/f'{m["id"]}.jpg', quality=95)
        regions.append((image, str(m['id'])+' '+m['name']))
        if m.get('city'):
            lua.execute('M.view.scale=M.view.scale*.55;M:RenderArt()')
            image = paint(lua); image.save(output/'details'/f'city-{m["id"]}.jpg', quality=95)
            cities.append((image, str(m['id'])+' '+m['name']))
    for start in range(0, len(regions), 9): board(regions[start:start+9], output/'boards'/f'regions-{start//9+1:02d}.jpg')
    board(cities, output/'boards/cities.jpg')
    for finding in findings:
        ident = finding['id']; place = html.escape(finding['place']); before = finding['before_image']; after = finding['after_image']
        city = ''
        if ident.startswith('C'):
            mid = finding['related_maps'][0]
            city = f'<p>新版本主城近景／较宽视野：</p><div><a href="regions/{mid}.jpg"><img src="regions/{mid}.jpg"></a><a href="details/city-{mid}.jpg"><img src="details/city-{mid}.jpg"></a></div>'
        html_rows.append(f'<article id="{ident}"><h2>{ident} {place}</h2><p>{html.escape(finding["description"])}</p><div><a href="{before}"><img src="{before}"></a><a href="{after}"><img src="{after}"></a></div><p>左：0.7.0；右：候选版本。点击查看大图。</p>{city}</article>')
    index = '<!doctype html><meta charset="utf-8"><title>地图修复对照</title><style>body{background:#171d20;color:#ddd;font:16px sans-serif;max-width:1800px;margin:24px auto}article{margin:40px 0;padding:20px;background:#242c30}article div{display:flex;gap:12px}a{color:#8bd}img{width:100%}article a{width:50%}</style><h1>0.8.0 地图修复候选对照</h1><p>51 处原检查记录，60 个区域／城市预览，以及完整地理窗口巡检。此页是静态素材和 Lua 模拟预览，不代表游戏验收。</p>'+''.join(html_rows)
    (output/'index.html').write_text(index, encoding='utf8')
    (output/'findings.json').write_text(json.dumps(findings, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
    (output/'scope.json').write_text(json.dumps(dict(findings=len(findings), regions=len(regions), cities=len(cities), baseline=str(baseline) if baseline else None), ensure_ascii=False, indent=2), encoding='utf8')
    print('Visual review generated', len(findings), len(regions), len(cities), str(output), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument('--output', type=Path, required=True); parser.add_argument('--baseline', type=Path)
    args = parser.parse_args(); review(args.output, args.baseline)
