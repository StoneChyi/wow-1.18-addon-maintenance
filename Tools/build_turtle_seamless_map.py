"""Extract the installed Turtle client maps and build independent 1.12 map data.

Raw client files and lossless previews stay in ignored local staging. Only the
addon data and derived paletted map art are deliverables. No MPQ is changed.
"""
import argparse
from collections import Counter, defaultdict
import hashlib
import io
import json
import math
from pathlib import Path
import struct
import numpy as np

from PIL import Image, ImageChops, ImageDraw, ImageFilter
from turtle_map_archive import Client, dbc, dbc_string

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'Interface/AddOns/TurtleSeamlessMap'
STAGING = ROOT / 'PluginHistory/staging/turtle-seamless-map'


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def json_write(path, data):
    write(path, (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))


def decode_blp(data):
    # Use Pillow's native DDS block decoder for the identical DXT payload. The
    # BLP plugin's Python decoder is slow and incorrectly requires a palette on
    # small DXT files. Original extraction bytes remain untouched.
    if data[:4] == b'BLP2' and data[8] == 2:
        w, h, offset = struct.unpack_from('<III', data, 12)
        size = struct.unpack_from('<I', data, 84)[0]
        code = {0: b'DXT1', 1: b'DXT3', 7: b'DXT5'}[data[10]]
        header = struct.pack('<4s31I', b'DDS ', 124, 0x81007, h, w, size, 0, 1,
                             *([0]*11), 32, 4, int.from_bytes(code, 'little'),
                             0, 0, 0, 0, 0, 0x1000, 0, 0, 0, 0)
        data = header + data[offset:offset+size]
    im = Image.open(io.BytesIO(data))
    im.load()
    return im


def encode_blp(image):
    """BLP2 DXT3, the format already used by this installed client's overlays."""
    image = image.convert('RGBA')
    stream = io.BytesIO()
    image.save(stream, format='DDS', pixel_format='DXT3')
    payload = bytearray(stream.getvalue()[128:])
    # Encode BC2's explicit alpha directly. Pillow's color compressor may
    # approximate alpha more aggressively than the four-bit format requires.
    a = np.asarray(image.getchannel('A'), dtype=np.uint64)
    a = a.reshape(image.height//4,4,image.width//4,4).transpose(0,2,1,3).reshape(-1,16)
    packed = np.sum(((a+8)//17) << (np.arange(16,dtype=np.uint64)*4), axis=1, dtype=np.uint64)
    blocks = np.frombuffer(payload, dtype=np.uint8).reshape(-1,16)
    blocks[:,:8] = packed.astype('<u8').view(np.uint8).reshape(-1,8)
    header = struct.pack('<4sI4BII', b'BLP2', 1, 2, 8, 1, 0, image.width, image.height)
    header += struct.pack('<16I', 148, *([0] * 15))
    header += struct.pack('<16I', len(payload), *([0] * 15))
    return header + bytes(payload)


def lua(value):
    if isinstance(value, str):
        return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return format(value, '.10g')
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'


def build():
    client = Client(ROOT)
    inventory = []
    names = client.listed()
    names = {n.lower(): n for n in names if n.lower().startswith('interface\\worldmap\\') and n.lower().endswith('.blp')}
    tables = {}
    sources = {}
    for name in ['WorldMapArea', 'WorldMapOverlay', 'WorldMapContinent', 'AreaTable', 'Map']:
        data, origin = client.read('DBFilesClient\\' + name + '.dbc')
        tables[name] = dbc(data)
        sources[name] = {'archive': origin, 'sha256': hashlib.sha256(data).hexdigest(), 'rows': len(tables[name][0]), 'fields': tables[name][2]}
        write(STAGING / 'dbc' / (name + '.dbc'), data)
    # Save actual client FrameXML for API/signature verification, local only.
    for file in ['WorldMapFrame.lua', 'WorldMapFrame.xml']:
        try:
            data, origin = client.read('Interface\\FrameXML\\' + file)
            write(STAGING / 'FrameXML' / file, data)
        except FileNotFoundError:
            pass
    areas, area_strings, area_fields = tables['AreaTable']
    if area_fields != 25 or tables['WorldMapArea'][2] != 8 or tables['WorldMapOverlay'][2] != 17:
        raise ValueError('Unexpected client DBC schemas')
    labels = {}
    for row in areas:
        labels[row[0]] = dbc_string(area_strings, row[15]) or dbc_string(area_strings, row[11])
    maps = []
    by_id = {}
    rows, strings, fields = tables['WorldMapArea']
    for row in rows:
        filename = dbc_string(strings, row[3])
        if not filename:
            continue
        left, right, top, bottom = struct.unpack('<4f', struct.pack('<4I', *row[4:8]))
        label = labels.get(row[2]) or {'Kalimdor': '卡利姆多', 'Azeroth': '东部王国', 'World': '世界'}.get(filename, filename)
        record = dict(id=row[0], map=row[1], area=row[2], file=filename, name=label,
                      bounds=[left, right, top, bottom], overlays=[], base=[], complete=False)
        maps.append(record)
        by_id[row[0]] = record
        for i in range(1, 13):
            name = 'Interface\\WorldMap\\' + filename + '\\' + filename + str(i) + '.blp'
            names.setdefault(name.lower(), name)
            record['base'].append(name)
    overlay_rows, overlay_strings, _ = tables['WorldMapOverlay']
    for row in overlay_rows:
        owner = by_id.get(row[1])
        if not owner:
            continue
        tex = dbc_string(overlay_strings, row[8])
        if not tex:
            continue
        width, height, x, y = row[9:13]
        prefix = 'Interface\\WorldMap\\' + owner['file'] + '\\' + tex
        if width == 0 or height == 0:
            raise ValueError('Empty map overlay')
        count = math.ceil(width / 256) * math.ceil(height / 256)
        paths = [prefix + str(i) + '.blp' for i in range(1, count + 1)]
        for name in paths:
            names.setdefault(name.lower(), name)
        owner['overlays'].append(dict(id=row[0], width=width, height=height, x=x, y=y, paths=paths))
    # Capture map folders with complete map art absent from WorldMapArea too.
    folders = defaultdict(set)
    for name in names.values():
        parts = name.split('\\')
        if len(parts) == 4:
            folders[parts[2]].add(parts[3].lower())
    known = {m['file'].lower() for m in maps}
    orphan_id = 10000
    for folder, files in sorted(folders.items()):
        if folder.lower() in known:
            continue
        base = ['Interface\\WorldMap\\' + folder + '\\' + folder + str(i) + '.blp' for i in range(1, 13)]
        if all(p.split('\\')[-1].lower() in files for p in base):
            maps.append(dict(id=orphan_id, map=-1, area=0, file=folder, name=folder + '（附加地图）', bounds=[0, 1002, 0, 668], overlays=[], base=base, complete=False, unplaced=True))
            orphan_id += 1
    missing = []
    images = {}
    for index, name in enumerate(sorted(names.values(), key=str.lower)):
        try:
            data, origin = client.read(name)
        except FileNotFoundError:
            missing.append(name)
            continue
        try:
            im = decode_blp(data)  # Decode every file, not just its header.
        except Exception as exc:
            raise ValueError('Cannot decode ' + name + ' from ' + origin + ' (' + str(len(data)) + ' bytes): ' + repr(data[:28])) from exc
        images[name.lower()] = im.convert('RGBA')
        write(STAGING / 'raw' / name.replace('\\', '/'), data)
        inventory.append(dict(path=name, archive=origin, bytes=len(data), width=im.width, height=im.height, sha256=hashlib.sha256(data).hexdigest()))
        if index % 600 == 0:
            print('Extracted', index, 'of', len(names), flush=True)
    runtime = []
    contact = []
    for m in maps:
        absent = [p for p in m['base'] if p.lower() not in images]
        absent += [p for o in m['overlays'] for p in o['paths'] if p.lower() not in images]
        m['missing'] = absent
        m['complete'] = not absent
        if absent:
            continue
        canvas = Image.new('RGBA', (1024, 768))
        for index, path in enumerate(m['base']):
            canvas.alpha_composite(images[path.lower()], ((index % 4) * 256, (index // 4) * 256))
        coverage = Image.new('L', canvas.size)
        for o in m['overlays']:
            columns = math.ceil(o['width'] / 256)
            for index, path in enumerate(o['paths']):
                col, row = index % columns, index // columns
                w = min(256, o['width'] - col * 256)
                h = min(256, o['height'] - row * 256)
                tile = images[path.lower()].crop((0, 0, w, h))
                x, y = o['x'] + col * 256, o['y'] + row * 256
                canvas.alpha_composite(tile, (x, y))
                a = Image.new('L', canvas.size)
                a.paste(tile.getchannel('A'), (x, y))
                coverage = ImageChops.lighter(coverage, a)
        full = canvas.crop((0, 0, 1002, 668))
        # Keep full, lossless source preview for every map, including unplaced ones.
        (STAGING / 'previews').mkdir(parents=True, exist_ok=True)
        full.save(STAGING / ('previews/' + m['file'] + '.png'))
        thumb = full.convert('RGB').resize((200, 134))
        contact.append((m['name'], thumb))
        continuous = full.copy()
        is_city = m['area'] in (1519,1537,1637,1638,1657,1497,2040)
        if m['overlays']:
            # Client overlay alpha defines explored land. Grow it under soft edges
            # so no actual painted overlay pixel is removed by the backing mask.
            alpha = coverage.crop((0, 0, 1002, 668)).filter(ImageFilter.MaxFilter(9))
            alpha = alpha.filter(ImageFilter.GaussianBlur(2))
        else:
            # Cities / instance maps remain complete in the full-area view.
            # Their rectangular border gets a small feather only in world view.
            alpha = Image.new('L', full.size, 255)
            draw = ImageDraw.Draw(alpha)
            for band in range(10):
                draw.rectangle((band, band, 1001-band, 667-band), outline=round(255 * band/10))
        # The old maps paint rectangular parchment frames. Their source images
        # stay lossless; only the stitched presentation crossfades the edges.
        edge = Image.new('L', full.size, 0)
        draw = ImageDraw.Draw(edge)
        if is_city:
            draw.rounded_rectangle((12,12,989,655), radius=85, fill=255)
            edge=edge.filter(ImageFilter.GaussianBlur(18))
        else:
            draw.rectangle((16,16,985,651),fill=255)
            edge=edge.filter(ImageFilter.GaussianBlur(9))
        continuous.putalpha(ImageChops.multiply(alpha,edge))
        left, right, top, bottom = m['bounds']
        surface = m['map'] in (0, 1) and m['area'] != 0
        kind = 'surface' if surface else 'continent' if m['file'] in ('Kalimdor', 'Azeroth') else 'instance'
        if m['file'] == 'World':
            kind = 'world'
        record = dict(id=m['id'], map=m['map'], area=m['area'], file=m['file'], name=m['name'], bounds=m['bounds'], kind=kind, city=is_city, tiles=[], overlays=m['overlays'])
        # Explicit complete-area art always uses original client files; nothing
        # from the full extraction is replaced by the stitched alpha derivative.
        for row in range(3):
            for col in range(4):
                w, h = min(256, 1002-col*256), min(256, 668-row*256)
                tile = Image.new('RGBA', (256, 256))
                tile.paste(continuous.crop((col*256, row*256, col*256+w, row*256+h)), (0, 0))
                name = str(m['id']) + '_' + str(row*4+col+1)
                if kind in ('surface', 'continent'):
                    data = encode_blp(tile)
                    check = decode_blp(data).convert('RGBA')
                    if max(ImageChops.difference(check.getchannel('A'), tile.getchannel('A')).getextrema()) > 9:
                        raise ValueError('BLP alpha round-trip failed: ' + m['file'] + '/' + name)
                    write(ADDON / 'Art' / (name + '.blp'), data)
                record['tiles'].append([name, col*256, row*256, w, h])
        runtime.append(record)
    # Only unused aliases may be missing; any DBC-declared map is a hard failure.
    incomplete = [dict(id=m['id'], file=m['file'], missing=m['missing']) for m in maps if not m['complete']]
    # Remove only this generator's earlier unused derived tiles, inside Art.
    expected_art = {tile[0]+'.blp' for m in runtime if m['kind'] in ('surface','continent') for tile in m['tiles']}
    art_root = (ADDON / 'Art').resolve()
    for path in art_root.glob('*.blp'):
        if path.name not in expected_art:
            if path.resolve().parent != art_root or not path.stem.replace('_','').isdigit():
                raise ValueError('Unexpected generated-art cleanup path')
            path.unlink()
    report = dict(version=1, client='Turtle WoW installed 1.18 client', built_on='2026-10-24',
                  archive_order=[a.path.name for a in client.archives], excluded_archives=['backup.MPQ', '_Patch-Y.mpq'],
                  tables=sources, extracted_files=len(inventory), extracted_bytes=sum(i['bytes'] for i in inventory),
                  map_count=len(maps), complete_maps=sum(m['complete'] for m in maps),
                  runtime_maps=len(runtime), kinds=dict(Counter(m['kind'] for m in runtime)),
                  derived_tiles=len(expected_art), derived_bytes=sum((art_root/n).stat().st_size for n in expected_art),
                  missing_listed_files=missing, incomplete_maps=incomplete,
                  maps=[{k:v for k,v in m.items() if k not in ('base', 'overlays')} | {'overlay_count':len(m['overlays'])} for m in maps])
    json_write(STAGING / 'inventory.json', inventory)
    json_write(STAGING / 'maps.json', maps)
    json_write(ROOT / 'PluginHistory/Research/TurtleSeamlessMap-地图提取-20261024.json', report)
    # A source manifest is reproducible evidence, not a copy of game data.
    json_write(ROOT / 'PluginHistory/Research/TurtleSeamlessMap-地图资源清单-20261024.json', inventory)
    write(ADDON / 'MapData.lua', ('-- Generated by Tools/build_turtle_seamless_map.py; installed client DBCs.\nTurtleSeamlessMap_Data = ' + lua(runtime) + '\n').encode('utf-8'))
    cols, cellw, cellh = 7, 208, 158
    sheet = Image.new('RGB', (cols*cellw, math.ceil(len(contact)/cols)*cellh), '#242424')
    draw = ImageDraw.Draw(sheet)
    for i, (name, thumb) in enumerate(contact):
        x, y = i%cols*cellw, i//cols*cellh
        sheet.paste(thumb,(x,y))
        # Filename labels are available on systems without CJK drawing fonts.
        draw.text((x+2,y+136), runtime[i]['file'][:29], fill='white')
    sheet.save(STAGING / 'all-maps-contact.jpg')
    print(json.dumps({k:v for k,v in report.items() if k not in ('maps','tables','archive_order')},ensure_ascii=False,indent=2))
    if incomplete:
        raise SystemExit('Incomplete map extraction: inspect report; no completeness claim allowed')


if __name__ == '__main__':
    argparse.ArgumentParser(description=__doc__).parse_args()
    build()
