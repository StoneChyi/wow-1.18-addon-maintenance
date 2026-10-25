"""0.8 landscape candidate, built from source rather than previous retouches.

Archives are read-only. Semantic road/liquid/model masks replace old rectangular
protection. Native landmarks stay registered; unsupported margins are explicitly
decorative continuations, not newly surveyed geometry. Build, review and deploy
are separate operations. Every LOD is derived from one continent master.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
import inspect
import functools
import re
import shutil
import struct

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

import build_turtle_map_hd as hd
import refine_turtle_map_terrain as atlas
from build_turtle_map_atlas import source_maps
from build_turtle_map_continuity import box_for
from build_turtle_seamless_map import ADDON, ROOT, STAGING, decode_blp, encode_blp, json_write
from turtle_map_archive import Client

OLD = STAGING/'v7-hd-candidate'
PREVIOUS = STAGING/'v8-continuity-candidate'
OUT = STAGING/'v9-landscape-candidate'
FIELD = 4
DENSITY = 32
TRANSFORMS = ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.2.0资源-20261024.json'
PLAN = ROOT/'Tools/turtle_map_landscape_review.json'
SEA = (0, 29, 43, 255)


def floating(image):
    return np.asarray(image, dtype=np.float32)


def blur_float(a, radius):
    # Pillow GaussianBlur has no F-mode implementation. Box-filter integral
    # sums retain fractional confidence and avoid 8-bit bands in empty margins.
    radius = max(1, round(radius))
    h, w = a.shape
    sums = np.pad(a.astype(np.float64).cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    x = np.arange(w); y = np.arange(h)
    l = np.maximum(0, x-radius); r = np.minimum(w, x+radius+1)
    t = np.maximum(0, y-radius); b = np.minimum(h, y+radius+1)
    return ((sums[b[:, None], r]-sums[t[:, None], r]-sums[b[:, None], l]+sums[t[:, None], l]) /
            ((b-t)[:, None]*(r-l))).astype(np.float32)


def context_field(rgb, trusted, fallback):
    """Continuous normalized convolution, from broad support to local support."""
    result = np.empty_like(rgb, dtype=np.float32); result[:] = fallback
    for radius in (128, 48, 16, 3):
        weight = blur_float(trusted, radius*FIELD)
        confidence = np.clip(weight/.12, 0, 1)
        for c in range(rgb.shape[2]):
            value = blur_float(rgb[:, :, c]*trusted, radius*FIELD)/np.maximum(weight, 1e-5)
            result[:, :, c] = result[:, :, c]*(1-confidence)+value*confidence
    return result


def liquid_field(cell, size):
    """Legacy MCLQ enabled quads and vertex heights, not one wet MCNK square.

    The final 64 bytes contain disabled (low-nibble 15) tiles. Using only the
    header's maximum level used to paint entire chunks as water.
    """
    raw = cell['children'].get(b'QLCM', b'')
    if not cell['water'] or len(raw) < 720:
        return np.zeros((size, size), bool), np.zeros((size, size), np.float32)
    heights = np.frombuffer(raw[8:656], dtype=np.dtype([('flow', '<u4'), ('z', '<f4')]))['z'].reshape(9, 9)
    if not np.isfinite(heights).all():
        raise ValueError('Nonfinite legacy liquid heights')
    enabled = (np.frombuffer(raw[656:720], dtype='u1').reshape(8, 8)&15) != 15
    wet = np.asarray(Image.fromarray(enabled.astype('uint8')*255).resize((size, size), Image.Resampling.NEAREST)) > 0
    level = floating(Image.fromarray(heights.copy()).resize((size, size), Image.Resampling.BILINEAR))
    terrain = floating(Image.fromarray(cell['heights'].astype('float32')).resize((size, size), Image.Resampling.BILINEAR))
    return wet & (terrain <= level+.08), np.maximum(0, level-terrain)


def road_field(cell, textures, size):
    weight = np.zeros((64, 64), np.float32)
    for i, (tid, flags, offset, _) in enumerate(struct.iter_unpack('<4I', cell['children'].get(b'YLCM', b''))):
        if tid >= len(textures):
            raise ValueError('Invalid semantic material index')
        isroad = bool(re.search(r'road|path|cobble|brick|street', textures[tid], re.I))
        if i == 0:
            weight[:] = float(isroad); continue
        raw = cell['children'].get(b'LACM', b'')[offset:offset+2048]
        if len(raw) != 2048 or flags&0x200:
            raise ValueError('Unsupported semantic layer alpha')
        values = np.frombuffer(raw, dtype='u1'); alpha = np.empty(4096, np.float32)
        alpha[::2] = (values&15)/15; alpha[1::2] = (values >> 4)/15
        alpha = alpha.reshape(64, 64); alpha[-1] = alpha[-2]; alpha[:, -1] = alpha[:, -2]
        weight = weight*(1-alpha)+float(isroad)*alpha
    return Image.fromarray(np.uint8(np.clip(weight*255, 0, 255))).resize((size, size), Image.Resampling.BILINEAR)


def palette_borders(native, land, allowed):
    """Long straight biome-tone boundaries, excluding individual rock edges."""
    rgb = floating(native.convert('RGB').filter(ImageFilter.GaussianBlur(6)))
    valid = floating(land) > 200
    samples = rgb[valid][::16]
    rng = np.random.default_rng(112)
    centres = samples[rng.choice(len(samples), 8, replace=False)].copy()
    # A continent-level palette keeps window overlaps consistent.
    for _ in range(12):
        groups = np.square(samples[:, None]-centres[None]).sum(2).argmin(1)
        for k in range(len(centres)):
            if np.any(groups == k): centres[k] = samples[groups == k].mean(0)
    labels = np.empty(valid.shape, np.uint8)
    for y in range(0, rgb.shape[0], 64):
        labels[y:y+64] = np.square(rgb[y:y+64, :, None]-centres[None, None]).sum(3).argmin(2)
    result = np.zeros(valid.shape, np.uint8)
    for axis in (0, 1):
        edge = np.diff(labels.astype('int16'), axis=axis) != 0
        edge = edge if axis == 0 else edge.T
        dest = result if axis == 0 else result.T
        for row, on in enumerate(edge):
            starts = np.flatnonzero(on & ~np.r_[False, on[:-1]])
            ends = np.flatnonzero(on & ~np.r_[on[1:], False])+1
            for start, end in zip(starts, ends):
                if end-start >= 8: dest[row:row+2, start:end] = 255
    return ImageChops.multiply(Image.fromarray(result), allowed)


def put_field(canvas, piece, rect, extent, density=FIELD, resample=Image.Resampling.BILINEAR):
    b = box_for(rect, extent, density)
    canvas.paste(piece.resize((b[2]-b[0], b[3]-b[1]), resample), b[:2])


def crop_field(image, box, size, divisor=8, nearest=False):
    bounds = tuple(v/divisor for v in box)
    sample = Image.Resampling.NEAREST if nearest else Image.Resampling.BILINEAR
    if bounds[0] >= 0 and bounds[1] >= 0 and bounds[2] <= image.width and bounds[3] <= image.height:
        return image.resize(size, sample, box=bounds)
    # Boundary ADTs cross the finite canvas. Preserve their source alignment;
    # Pillow's resize(box=...) rejects out-of-bounds rectangles.
    return image.transform(size, Image.Transform.AFFINE,
                           ((bounds[2]-bounds[0])/size[0], 0, bounds[0],
                            0, (bounds[3]-bounds[1])/size[1], bounds[1]), sample)


def prepare(cid):
    """Read and classify every ADT, independently from previous processed art."""
    OUT.mkdir(parents=True, exist_ok=True)
    info = json.loads((OLD/'manifest.json').read_text(encoding='utf8'))
    scene = next(c for c in info['continents'] if c['id'] == cid); extent = scene['rect']
    name = 'Kalimdor' if cid == 1 else 'Azeroth'
    t = json.loads(TRANSFORMS.read_text(encoding='utf8'))['transforms'][str(cid)]; step = hd.STEP*t['scale']
    size = (extent[2]*FIELD, extent[3]*FIELD)
    native = Image.open(OLD/f'{name}-before.png').convert('RGBA').resize(size, Image.Resampling.BOX)
    height = Image.new('F', size); wet = Image.new('L', size); depth = Image.new('F', size)
    roads = Image.new('L', size); coverage = Image.new('L', size)
    client = Client(ROOT, True); refs = hd.minimap_index(client); sources = []; counts = Counter()
    try:
        for source in (s for s in info['sources'] if s['continent'] == name):
            tx, ty = source['x'], source['y']
            r = [t['x']+(tx-32)*step, t['y']+(ty-32)*step, step, step]
            path = f'World\\Maps\\{name}\\{name}_{tx}_{ty}.adt'; raw, origin = client.read(path)
            # Effective source hashes are checked even if a preceding build left
            # a cached artifact. A changed source cannot silently reuse it.
            if hashlib.sha256(raw).hexdigest() != source['adt_sha256']:
                raise ValueError('ADT differs from the audited source: '+path)
            cells, textures, _ = atlas.material_cells(raw)
            hs = Image.new('F', (256, 256)); ds = Image.new('F', (256, 256)); ws = Image.new('L', (256, 256))
            rs = Image.new('L', (256, 256))
            for (cx, cy), cell in cells.items():
                xy = (cx*16, cy*16)
                hs.paste(Image.fromarray(cell['heights'].astype('float32')).resize((16, 16), Image.Resampling.BILINEAR), xy)
                water, distance = liquid_field(cell, 16)
                ws.paste(Image.fromarray(water.astype('uint8')*255), xy)
                ds.paste(Image.fromarray(distance), xy)
                rs.paste(road_field(cell, textures, 16), xy)
                counts['liquid_cells'] += int(water.any()); counts['chunks'] += 1
            ref = refs.get((name.lower(), tx, ty))
            if ref:
                data, _ = client.read('Textures\\Minimap\\'+ref)
                if hashlib.sha256(data).hexdigest() != source['minimap_sha256']:
                    raise ValueError('Native minimap differs from audit')
            put_field(height, hs, r, extent); put_field(depth, ds, r, extent)
            put_field(wet, ws, r, extent, resample=Image.Resampling.NEAREST)
            put_field(roads, rs, r, extent)
            put_field(coverage, Image.new('L', (16, 16), 255), r, extent)
            sources.append(dict(**source, path=path, world_rect=r)); counts['adts'] += 1
            if counts['adts'] % 200 == 0:
                print('Semantic sources', name, counts['adts'], flush=True)
    finally:
        for archive in client.archives: archive.close()
    alpha = floating(native.getchannel('A'))/255
    wet_values = floating(wet)/255
    # Only source-enabled liquid connected to open water is recoloured as sea.
    # Inland ponds and city canals are not selected by their colour or AreaID.
    sea_candidate = ((wet_values > .5) | (alpha < .05)).astype('uint8')*255
    connected = Image.fromarray(sea_candidate)
    padded = Image.new('L', (size[0]+2, size[1]+2), 255); padded.paste(connected, (1, 1))
    ImageDraw.floodfill(padded, (0, 0), 128)
    ocean = padded.crop((1, 1, size[0]+1, size[1]+1)).point(lambda a: 255 if a == 128 else 0)
    for label, field in (('roads', roads), ('wet', wet), ('ocean', ocean), ('coverage', coverage)):
        field.save(OUT/f'{name}-{label}.png')
    height.save(OUT/f'{name}-height.tif'); depth.save(OUT/f'{name}-depth.tif')
    json_write(OUT/f'{name}-sources.json', dict(id=cid, rect=extent, transform=t, step=step,
               counts=dict(counts), sources=sources,
               limitations='Source heights retained. Reconstructed surface colours are inferred from adjacent trusted terrain, never surveyed new geography.'))
    print('Prepared semantic fields', name, counts['adts'], flush=True)
    classify(cid)


def classify(cid):
    """Regenerate appearance confidence without re-reading geometry layers."""
    name = 'Kalimdor' if cid == 1 else 'Azeroth'
    report = json.loads((OUT/f'{name}-sources.json').read_text(encoding='utf8'))
    extent = report['rect']; size = (extent[2]*FIELD, extent[3]*FIELD)
    native = Image.open(OLD/f'{name}-before.png').convert('RGBA').resize(size, Image.Resampling.BOX)
    roads = Image.open(OUT/f'{name}-roads.png'); wet = Image.open(OUT/f'{name}-wet.png')
    ocean = Image.open(OUT/f'{name}-ocean.png'); quality = Image.new('L', size)
    owner = Image.new('I', size)
    territory = atlas.read_terrain(ADDON/'TerrainData.lua')['territory'][cid]
    client = Client(ROOT, True); refs = hd.minimap_index(client)
    try:
        for source in report['sources']:
            code = territory['tiles'].get(source['y']*64+source['x']+1)
            if code:
                values = []; start = 0
                for offset in range(0, len(code), 6):
                    end = int(code[offset:offset+3], 16); area = int(code[offset+3:offset+6], 16)
                    values.extend([area]*(end-start)); start = end
                assert len(values) == 256
                put_field(owner, Image.fromarray(np.asarray(values, dtype='int32').reshape(16, 16)), source['world_rect'], extent,
                          resample=Image.Resampling.NEAREST)
            ref = refs.get((name.lower(), source['x'], source['y']))
            if not ref: continue
            raw = client.read('Textures\\Minimap\\'+ref)[0]
            assert hashlib.sha256(raw).hexdigest() == source['minimap_sha256']
            gray = decode_blp(raw).convert('L')
            residual = floating(ImageChops.difference(gray, gray.filter(ImageFilter.GaussianBlur(1.2))))
            energy = residual.reshape(16, 16, 16, 16).transpose(0, 2, 1, 3).mean((2, 3))
            # Once an unsupported source cell is identified, scattered DXT
            # pixels inside it must not re-enter the colour reference pool.
            q = Image.fromarray(np.uint8(energy < 1.4)*255).resize((256, 256), Image.Resampling.NEAREST)
            put_field(quality, q, source['world_rect'], extent)
    finally:
        for archive in client.archives: archive.close()
    review = Image.new('L', size); draw = ImageDraw.Draw(review)
    for issue in json.loads(PLAN.read_text(encoding='utf8'))['findings']:
        if issue['continent'] == cid and issue['severity'] != 'V':
            draw.rectangle(box_for(issue['world_rect'], extent, FIELD), fill=255)
    rgb = floating(native.convert('RGB')); alpha = floating(native.getchannel('A'))/255
    # Explicitly reviewed unsupported appearance patches. These are editorial
    # exclusions, never a replacement AreaID/coast/road/landmark boundary.
    editorial = Image.new('L', size); editorial_draw = ImageDraw.Draw(editorial)
    for patch in json.loads(PLAN.read_text(encoding='utf8')).get('appearance_exclusions', []):
        if patch['continent'] == cid:
            editorial_draw.polygon([(round((x-extent[0])*FIELD), round((y-extent[1])*FIELD)) for x, y in patch['polygon']], fill=255)
    quality = ImageChops.lighter(quality, editorial)
    # Preserve existing native blue surfaces even if legacy liquid information
    # is missing. This is a preservation mask, not evidence for new ocean.
    native_water = Image.fromarray(np.uint8((rgb[:, :, 2] > rgb[:, :, 0]*1.2) &
                                            (rgb[:, :, 1] > rgb[:, :, 0]*1.12))*255)
    safe = ImageChops.lighter(ImageChops.lighter(roads.filter(ImageFilter.MaxFilter(3)), wet), native_water)
    allowed = ImageChops.multiply(review, ImageChops.invert(safe))
    # Real AreaID ownership identifies zone transitions. Generic RGB edge
    # detection also selected every mountain/forest edge and erased good art.
    ownership = np.asarray(owner); boundary = np.zeros(ownership.shape, np.uint8)
    boundary[1:] |= np.uint8(ownership[1:] != ownership[:-1])*255
    boundary[:, 1:] |= np.uint8(ownership[:, 1:] != ownership[:, :-1])*255
    land = Image.fromarray(np.uint8((alpha > .5) & (floating(ocean) < 100))*255)
    lines = ImageChops.lighter(ImageChops.multiply(Image.fromarray(boundary), allowed), palette_borders(native, land, allowed))
    observed = floating(Image.open(OUT/f'{name}-height.tif'))
    # Exact-height placeholder plateaus are source-incomplete surfaces. Colour
    # / detail confidence alone misses their pre-baked noise and straight bands.
    flat = np.ones(observed.shape, bool)
    for dy, dx in ((-4, 0), (4, 0), (0, -4), (0, 4)):
        flat &= np.abs(observed-np.roll(observed, (dy, dx), (0, 1))) < .05
    flat &= (floating(land) > 200) & (floating(safe) < 32) & (floating(review) > 200)
    missing_height = Image.fromarray(np.uint8(flat)*255)
    quality = ImageChops.lighter(quality, missing_height)
    # Repair a whole transition corridor, not a translucent one-pixel scar.
    corridors = lines.filter(ImageFilter.MaxFilter(33))
    uncertain = ImageChops.lighter(quality.filter(ImageFilter.MaxFilter(5)), corridors)
    uncertain = ImageChops.multiply(uncertain, land)
    mask = uncertain.filter(ImageFilter.GaussianBlur(3.0))
    mask = ImageChops.multiply(mask, ImageChops.invert(safe))
    # Detail confidence is not colour confidence. Flat orange desert and white
    # snow remain colour anchors; only untextured placeholder colours are left
    # out. Transition colours use valid samples from both sides of the border.
    confidence = (1-floating(quality)/255)*(floating(land)/255)
    biome_colour = ((rgb.max(2)-rgb.min(2) > 35) & (rgb.mean(2) > 90)) | (rgb.mean(2) > 170)
    confidence[biome_colour & (alpha > .9) & (floating(land) > 200)] = 1
    target = context_field(rgb, confidence, (90, 85, 65))
    hconf = np.uint8(~flat)*(floating(land)/255)
    continuation = context_field(observed[:, :, None], hconf, (0,))[:, :, 0]
    hm = floating(missing_height.filter(ImageFilter.GaussianBlur(3)))/255
    # This is only a smooth continuation between observed boundary heights;
    # it introduces no hand-drawn peak, road, pass, entrance or coast change.
    relief = observed*(1-hm)+continuation*hm
    smooth = blur_float(blur_float(relief, FIELD), FIELD)
    gy, gx = np.gradient(smooth, 1/FIELD/report['transform']['scale'])
    length = np.sqrt(gx*gx+gy*gy+1)
    shade = np.clip((.68+(-.55*gx-.45*gy+.70)/length*.4)/.96, .78, 1.18)
    # A source-frame height discontinuity is not a surveyed cliff. Suppress
    # artificial shadow strips on the audited axial reconstruction corridors.
    shade = 1+(shade-1)*(.55+.35*hm)
    for c in range(3): Image.fromarray(target[:, :, c]).save(OUT/f'{name}-colour-{c}.tif')
    Image.fromarray(shade.astype('float32')).save(OUT/f'{name}-shade.tif')
    for label, field in (('mask', mask), ('uncertain', uncertain), ('lines', lines), ('quality', quality),
                         ('missing-height', missing_height), ('land', land)):
        field.save(OUT/f'{name}-{label}.png')
    report['classified_pixels'] = int((floating(mask) > 8).sum())
    report['inferred_height_field_pixels'] = int(flat.sum())
    json_write(OUT/f'{name}-sources.json', report)
    print('Reclassified', name, report['classified_pixels'], flush=True)


def material_weights(cell, textures):
    """Exact mean contribution after compositing all actual MCAL layers."""
    weights = []
    for i, (tid, flags, offset, _) in enumerate(struct.iter_unpack('<4I', cell['children'].get(b'YLCM', b''))):
        if tid >= len(textures): raise ValueError('Bad material index')
        if i == 0:
            weights.append((textures[tid], np.ones((64, 64), np.float32))); continue
        raw = cell['children'].get(b'LACM', b'')[offset:offset+2048]
        if len(raw) != 2048 or flags&0x200: raise ValueError('Unsupported material weights')
        values = np.frombuffer(raw, dtype='u1'); alpha = np.empty(4096, np.float32)
        alpha[::2] = (values&15)/15; alpha[1::2] = (values >> 4)/15
        alpha = alpha.reshape(64, 64); alpha[-1] = alpha[-2]; alpha[:, -1] = alpha[:, -2]
        weights = [(name, weight*(1-alpha)) for name, weight in weights]
        weights.append((textures[tid], alpha))
    result = Counter()
    for name, weight in weights: result[name] += float(weight.mean())
    return result


def material_fields(cid):
    """Continuous world-space material mixtures, including both biome sides.

    Fine pattern never resets or hard-switches at an MCNK/ADT boundary. Invalid
    flat margins borrow a spatial mixture of neighbouring valid materials, not
    one rock swatch or a mirrored strip of a landmark-bearing map.
    """
    name = 'Kalimdor' if cid == 1 else 'Azeroth'
    report = json.loads((OUT/f'{name}-sources.json').read_text(encoding='utf8'))
    records = report['sources']; tx0 = min(s['x'] for s in records); ty0 = min(s['y'] for s in records)
    tx1 = max(s['x'] for s in records)+1; ty1 = max(s['y'] for s in records)+1
    size = ((tx1-tx0)*16, (ty1-ty0)*16); planes = {}; known = np.zeros(size[::-1], np.float32)
    missing = Image.open(OUT/f'{name}-missing-height.png'); land = Image.open(OUT/f'{name}-land.png')
    directory = OUT/f'materials-{cid}'; directory.mkdir(exist_ok=True)
    client = Client(ROOT, True); sources = {}
    try:
        for i, source in enumerate(records):
            raw = client.read(source['path'])[0]
            assert hashlib.sha256(raw).hexdigest() == source['adt_sha256']
            cells, textures, _ = atlas.material_cells(raw)
            b = box_for(source['world_rect'], report['rect'], 32)
            confidence = (1-floating(crop_field(missing, b, (16, 16)))/255)*(floating(crop_field(land, b, (16, 16)))/255)
            for (cx, cy), cell in cells.items():
                x = (source['x']-tx0)*16+cx; y = (source['y']-ty0)*16+cy
                known[y, x] = confidence[cy, cx]
                for texture, amount in material_weights(cell, textures).items():
                    if re.search(r'road|path|cobble|brick|street', texture, re.I): continue
                    if texture not in planes: planes[texture] = np.zeros(size[::-1], np.float32)
                    planes[texture][y, x] += amount
            if (i+1) % 300 == 0: print('Material coverage', name, i+1, len(planes), flush=True)
        weights = [blur_float(known, r) for r in (96, 32, 8)]
        fields = []; missing_array = (known < .25)
        for texture, plane in planes.items():
            try: raw, origin = client.read(texture)
            except FileNotFoundError:
                sources[texture] = dict(missing=True); continue
            sources[texture] = dict(source=origin, sha256=hashlib.sha256(raw).hexdigest())
            # Keep original ownership where it is observed, smoothly blend all
            # layer contributions over ~3 world units at authored hard borders.
            inferred = np.zeros_like(plane)
            for radius, support in zip((96, 32, 8), weights):
                confidence = np.clip(support/.12, 0, 1)
                local = blur_float(plane*known, radius)/np.maximum(support, 1e-6)
                inferred = inferred*(1-confidence)+local*confidence
            filled = np.where(missing_array, inferred, plane)
            smooth = blur_float(blur_float(filled, 2), 2)
            if smooth.max() < .001: continue
            key = hashlib.sha256(texture.lower().encode('ascii')).hexdigest()[:20]+'.npz'
            np.savez_compressed(directory/key, weight=smooth)
            fields.append(dict(texture=texture, file=key, sha256=hashlib.sha256((directory/key).read_bytes()).hexdigest()))
        json_write(directory/'manifest.json', dict(bounds=[tx0, ty0, tx1, ty1], fields=fields, sources=sources,
                   inferred_cells=int(missing_array.sum()), source_mask_sha256=hashlib.sha256((OUT/f'{name}-missing-height.png').read_bytes()).hexdigest()))
    finally:
        for archive in client.archives: archive.close()
    print('Continuous material fields ready', name, len(fields), flush=True)


class MaterialSurface:
    def __init__(self, cid, client):
        self.client = client; self.cache = {}; self.weights = {}
        self.directory = OUT/f'materials-{cid}'
        self.manifest = json.loads((self.directory/'manifest.json').read_text(encoding='utf8'))
        name = 'Kalimdor' if cid == 1 else 'Azeroth'
        assert self.manifest['source_mask_sha256'] == hashlib.sha256((OUT/f'{name}-missing-height.png').read_bytes()).hexdigest()
        self.fingerprint = hashlib.sha256((self.directory/'manifest.json').read_bytes()+
                                          inspect.getsource(type(self).sample).encode('utf8')+
                                          inspect.getsource(type(self).tile).encode('utf8')).hexdigest()[:12]
        for row in self.manifest['fields']:
            path = self.directory/row['file']
            assert hashlib.sha256(path.read_bytes()).hexdigest() == row['sha256']
            self.weights[row['texture']] = Image.fromarray(np.load(path)['weight'])
        total = np.zeros(next(iter(self.weights.values())).size[::-1], np.float32)
        mean_colour = np.zeros(total.shape+(3,), np.float32)
        for texture, field in self.weights.items():
            raw = self.client.read(texture)[0]
            assert hashlib.sha256(raw).hexdigest() == self.manifest['sources'][texture]['sha256']
            mean = floating(decode_blp(raw).convert('RGB')).mean((0, 1))
            weight = floating(field); total += weight; mean_colour += weight[:, :, None]*mean
        mean_colour /= np.maximum(total[:, :, None], .001)
        self.mean_fields = [Image.fromarray(mean_colour[:, :, c]) for c in range(3)]

    def mean_tile(self, tx, ty, size=512, halo=48):
        tx0, ty0 = self.manifest['bounds'][:2]; pad = halo*16/size; side = size+2*halo
        box = ((tx-tx0)*16-pad, (ty-ty0)*16-pad, (tx-tx0+1)*16+pad, (ty-ty0+1)*16+pad)
        return np.stack([floating(crop_field(field, box, (side, side), divisor=1)) for field in self.mean_fields], 2)

    def sample(self, name, tx, ty, size, halo=0):
        if name not in self.cache:
            raw = self.client.read(name)[0]
            assert hashlib.sha256(raw).hexdigest() == self.manifest['sources'][name]['sha256']
            self.cache[name] = floating(decode_blp(raw).convert('RGB'))
        texture = self.cache[name]
        resolution = size-2*halo
        x = tx*16+(np.arange(size, dtype=np.float32)-halo+.5)*16/resolution
        y = ty*16+(np.arange(size, dtype=np.float32)-halo+.5)*16/resolution
        u = (x[None, :]/4+.12*np.sin(y[:, None]*.37+x[None, :]*.11))*texture.shape[1]
        v = (y[:, None]/4+.12*np.sin(x[None, :]*.29-y[:, None]*.07))*texture.shape[0]
        ix = np.floor(u).astype(int); iy = np.floor(v).astype(int)
        fx = (u-ix)[:, :, None]; fy = (v-iy)[:, :, None]
        a = texture[iy % texture.shape[0], ix % texture.shape[1]]
        b = texture[iy % texture.shape[0], (ix+1) % texture.shape[1]]
        c = texture[(iy+1) % texture.shape[0], ix % texture.shape[1]]
        d = texture[(iy+1) % texture.shape[0], (ix+1) % texture.shape[1]]
        return (a*(1-fx)+b*fx)*(1-fy)+(c*(1-fx)+d*fx)*fy

    def tile(self, tx, ty, size=512, halo=48):
        tx0, ty0 = self.manifest['bounds'][:2]
        pad = halo*16/size; side = size+2*halo
        box = ((tx-tx0)*16-pad, (ty-ty0)*16-pad, (tx-tx0+1)*16+pad, (ty-ty0+1)*16+pad)
        pixels = np.zeros((side, side, 3), np.float32); total = np.zeros((side, side), np.float32)
        for name, field in self.weights.items():
            local = field.crop((math.floor(box[0]), math.floor(box[1]), math.ceil(box[2]), math.ceil(box[3])))
            if local.getextrema()[1] < .001: continue
            weight = floating(crop_field(field, box, (side, side), divisor=1))
            pixels += self.sample(name, tx, ty, side, halo)*weight[:, :, None]; total += weight
        pixels /= np.maximum(total[:, :, None], .001)
        return Image.fromarray(np.uint8(np.clip(pixels, 0, 255)))


def source_detail(native, box, size, halo=160):
    """Registered native high-frequency features with a continent-wide halo.

    Material blending may replace background appearance; it must not erase
    existing mountains, cliffs or small source landmarks over a wide corridor.
    """
    bounds = tuple((v+offset)/2 for v, offset in zip(box, (-halo, -halo, halo, halo)))
    expanded = (size[0]+2*halo, size[1]+2*halo)
    if min(bounds[:2]) >= 0 and bounds[2] <= native.width and bounds[3] <= native.height:
        local = native.resize(expanded, Image.Resampling.LANCZOS, box=bounds).convert('RGB')
    else:
        local = crop_field(native, tuple(v*2 for v in bounds), expanded, divisor=2).convert('RGB')
    pixels = floating(local); broad = floating(local.filter(ImageFilter.GaussianBlur(40)))
    return np.clip(pixels/np.maximum(broad, 12), .50, 1.65)[halo:-halo, halo:-halo]


def rebuild(cid):
    name = 'Kalimdor' if cid == 1 else 'Azeroth'
    report = json.loads((OUT/f'{name}-sources.json').read_text(encoding='utf8'))
    extent = report['rect']; width, height = extent[2:]
    # No previously retouched continent is read in this phase.
    native = Image.open(OLD/f'{name}-before.png').convert('RGBA')
    master = native.resize((width*DENSITY, height*DENSITY), Image.Resampling.LANCZOS)
    mask = Image.open(OUT/f'{name}-mask.png').convert('L')
    fields = [Image.open(OUT/f'{name}-colour-{c}.tif') for c in range(3)]
    shade = Image.open(OUT/f'{name}-shade.tif')
    quality = Image.open(OUT/f'{name}-quality.png')
    lines = Image.open(OUT/f'{name}-lines.png')
    # Only the narrow actual seam and unsupported source pixels lose native
    # detail. Broad colour/material transitions retain valid landforms.
    detail_confidence = ImageChops.invert(ImageChops.lighter(quality, lines.filter(ImageFilter.MaxFilter(9))))
    detail_confidence = detail_confidence.filter(ImageFilter.GaussianBlur(1))
    client = Client(ROOT, True)
    surface = MaterialSurface(cid, client)
    cache = OUT/'ground'; cache.mkdir(exist_ok=True); records = []
    try:
        for i, source in enumerate(report['sources']):
            tx, ty = source['x'], source['y']; r = source['world_rect']; b = box_for(r, extent, DENSITY)
            size = (b[2]-b[0], b[3]-b[1]); base = master.crop(b)
            m = crop_field(mask, b, size)
            if not m.getbbox(): continue
            unlit = cache/f'blend-{surface.fingerprint}-{cid}-{tx}-{ty}.png'
            if not unlit.exists():
                surface.tile(tx, ty).save(unlit)
            piece = Image.open(unlit).convert('RGB')
            pixels = floating(piece)
            # Real local MTEX/MCAL grain; no repeated continent-wide rock swatch.
            # Normalize against the continuous weighted mean of the actual
            # materials, retaining broad source rock/soil features. A tiny
            # local high-pass left unsupported margins looking like flat noise.
            broad = surface.mean_tile(tx, ty)
            grain = np.clip(pixels/np.maximum(broad, 12), .50, 1.65)[48:-48, 48:-48]
            # Halo samples remove per-ADT normalization seams. Resize floating
            # channels independently so the gain never becomes an 8-bit band.
            grain = np.stack([floating(Image.fromarray(grain[:, :, c]).resize(size, Image.Resampling.BILINEAR)) for c in range(3)], axis=2)
            lighting = floating(crop_field(shade, b, size))
            rgb = np.stack([floating(crop_field(f, b, size)) for f in fields], axis=2)
            confidence = floating(crop_field(detail_confidence, b, size))/255
            detail = source_detail(native, b, size)
            gain = grain*(1-confidence[:, :, None])+detail*confidence[:, :, None]
            rgb *= gain*(lighting*(1-confidence)+confidence)[:, :, None]
            fill = Image.fromarray(np.uint8(np.clip(rgb, 0, 255))).convert('RGBA'); fill.putalpha(base.getchannel('A'))
            master.paste(Image.composite(fill, base, m), b[:2])
            records.append(dict(x=tx, y=ty, file=unlit.name, albedo_sha256=hashlib.sha256(unlit.read_bytes()).hexdigest()))
            if (i+1) % 100 == 0: print('Reconstructed', name, i+1, flush=True)
        master.save(OUT/f'{name}-terrain.png', compress_level=3)
        report['material_cache'] = records; report['continuous_materials'] = surface.manifest
        report.pop('materials', None); report.pop('missing_materials', None)
        report['limitations'] = 'Observed terrain and source material mixtures retained; reviewed unsupported flat margins use decorative continuation of boundary heights/materials, never surveyed new geography.'
        json_write(OUT/f'{name}-sources.json', report)
    finally:
        for archive in client.archives: archive.close()
    print('Master ready', name, flush=True)


def registered_model(label, directory, cid, bounds):
    """Model pixels only. An image rectangle is never a protection mask."""
    image = Image.open(directory/(label+'.png')).convert('RGBA')
    coverage = Image.frombytes('L', image.size, (directory/(label+'.coverage')).read_bytes())
    image.putalpha(coverage)
    t = json.loads(TRANSFORMS.read_text(encoding='utf8'))['transforms'][str(cid)]
    step = hd.STEP*t['scale']
    world = [t['x']+(bounds[0]-32)*step, t['y']+(bounds[1]-32)*step,
             (bounds[2]-bounds[0])*step, (bounds[3]-bounds[1])*step]
    return image, world


def closed_cutaway(image, density):
    """Dark enclosing rock silhouette separates underground from the surface.

    A connected footprint, not the whole bounding box, closes the cutaway.
    Original room/entrance pixels and geographic projection stay unchanged.
    """
    alpha = image.getchannel('A')
    pad = round(density*.8)
    padded = Image.new('L', (image.width+2*pad, image.height+2*pad))
    padded.paste(alpha.point(lambda a: 255 if a > 16 else 0), (pad, pad))
    radius = max(3, round(density*.65)//2*2+1)
    closed = padded.filter(ImageFilter.MaxFilter(radius)).filter(ImageFilter.MinFilter(radius))
    flood = closed.copy(); ImageDraw.floodfill(flood, (0, 0), 128)
    solid = flood.point(lambda a: 0 if a == 128 else 255).crop((pad, pad, pad+image.width, pad+image.height))
    rim = solid.filter(ImageFilter.MaxFilter(max(3, round(density*.18)//2*2+1)))
    rgb = floating(image.convert('RGB')); valid = floating(alpha) > 200
    base = tuple(int(v) for v in np.quantile(rgb[valid], .2, axis=0)*.36)
    result = Image.new('RGBA', image.size, base+(0,)); result.putalpha(rim)
    # Restrained contact edge; no roads, rooms or other traversable features.
    edge = ImageChops.subtract(rim, solid).filter(ImageFilter.GaussianBlur(2))
    shadow = Image.new('RGBA', image.size, tuple(max(4, v//2) for v in base)+(0,)); shadow.putalpha(edge)
    result.alpha_composite(shadow); result.alpha_composite(image)
    return result


def composite_model(master, image, position):
    """Small contact occlusion outside the real footprint; model pixels stay.

    This is a restrained static contact edge, not a simulated sun shadow.
    Padding prevents the rendering canvas from becoming a rectangular shadow.
    """
    pad = 12
    mask = Image.new('L', (image.width+2*pad, image.height+2*pad))
    mask.paste(image.getchannel('A'), (pad, pad))
    mask = mask.filter(ImageFilter.GaussianBlur(2)).point(lambda a: round(a*.24))
    shadow = Image.new('RGBA', mask.size, (0, 0, 0, 0)); shadow.putalpha(mask)
    master.alpha_composite(shadow, (position[0]-pad, position[1]-pad))
    master.alpha_composite(image, position)


def compose():
    """One stable surface scene, real-geometry cities and coherent open sea."""
    report = json.loads((OLD/'manifest.json').read_text(encoding='utf8'))
    cities = []
    for scene in report['continents']:
        cid = scene['id']; name = 'Kalimdor' if cid == 1 else 'Azeroth'; extent = scene['rect']
        master = Image.open(OUT/f'{name}-terrain.png').convert('RGBA')
        ocean = Image.open(OUT/f'{name}-ocean.png').convert('L')
        depths = Image.open(OUT/f'{name}-depth.tif')
        # Finite coverage is irrelevant to the ocean's continuous colour field.
        shore = ImageChops.invert(ocean).filter(ImageFilter.GaussianBlur(3*FIELD))
        for y in range(0, master.height, 128):
            b = (0, y, master.width, min(master.height, y+128)); size = (b[2], b[3]-b[1])
            wet = floating(crop_field(ocean, b, size))/255
            shallow = floating(crop_field(shore, b, size))/255
            depth = floating(crop_field(depths, b, size))
            amount = np.clip(shallow*1.6, 0, 1)*np.clip(1-depth/90, .15, 1)
            pixels = floating(master.crop(b)); original_alpha = pixels[:, :, 3].copy()
            sea = np.empty_like(pixels); sea[:] = SEA
            for c, near in enumerate((15, 57, 64)):
                sea[:, :, c] = SEA[c]+(near-SEA[c])*amount
            pixels = pixels*(1-wet[:, :, None])+sea*wet[:, :, None]
            # Empty open-ocean coverage already uses the shared sea background.
            # Do not allocate thousands of opaque, detail-free ocean tiles.
            pixels[:, :, 3] = original_alpha
            master.paste(Image.fromarray(np.uint8(np.clip(pixels, 0, 255))), b[:2])
        # Replace former gate / courtyard rectangle with actual placed objects.
        if cid == 1:
            for label, directory, bounds in (
                ('aq-join', OLD, (26, 43, 33, 53)),
                ('diremaul', PREVIOUS, None),
            ):
                if bounds is None:
                    land = json.loads((PREVIOUS/'landscape-audit.json').read_text(encoding='utf8'))
                    world = land['diremaul_world_rect']
                    im = Image.open(directory/(label+'.png')).convert('RGBA')
                    im.putalpha(Image.frombytes('L', im.size, (directory/(label+'.coverage')).read_bytes()))
                else:
                    im, world = registered_model(label, directory, cid, bounds)
                b = box_for(world, extent, DENSITY)
                im = im.resize((b[2]-b[0], b[3]-b[1]), Image.Resampling.LANCZOS)
                composite_model(master, im, b[:2])
        models = []
        for m in source_maps():
            if not m.get('city') or m['map'] != cid or m['id'] in (341, 382): continue
            mid = m['id']; directory = PREVIOUS if mid == 301 else OLD
            info = json.loads((directory/f'city-{mid}-sources.json').read_text(encoding='utf8'))
            t = json.loads(TRANSFORMS.read_text(encoding='utf8'))['transforms'][str(cid)]; step = hd.STEP*t['scale']
            bounds = (math.floor((m['rect'][0]-t['x'])/step+32),
                      math.floor((m['rect'][1]-t['y'])/step+32),
                      math.ceil((m['rect'][0]+m['rect'][2]-t['x'])/step+32),
                      math.ceil((m['rect'][1]+m['rect'][3]-t['y'])/step+32))
            im, world = registered_model('city-'+str(mid), directory, cid, bounds)
            # Surface-model coverage joins the landscape at all zoom levels.
            b = box_for(world, extent, DENSITY)
            composite_model(master, im.resize((b[2]-b[0], b[3]-b[1]), Image.Resampling.LANCZOS), b[:2])
            models.append((m, im, world)); cities.append(dict(id=mid, rect=m['rect'], model_sources=info,
                          model_coverage_pixels=int((floating(im.getchannel('A')) > 0).sum()),
                          mode='Source model coverage over shared continent; no rectangular native background'))
        master.save(OUT/f'{name}-packed.png', compress_level=3)
        # Near-city scenes use the identical background, adding only finer
        # source model samples. Camera and mouse do not change the geography.
        for m, im, world in models:
            r = m['rect']; b = box_for(r, extent, DENSITY)
            city = master.crop(b).resize((round(r[2]*64), round(r[3]*64)), Image.Resampling.LANCZOS)
            mb = box_for(world, r, 64)
            city.alpha_composite(im.resize((mb[2]-mb[0], mb[3]-mb[1]), Image.Resampling.LANCZOS), mb[:2])
            hd.feather(city, 32).save(OUT/f'city-{m["id"]}-world.png')
        preview = Image.new('RGBA', master.size, SEA); preview.alpha_composite(master)
        preview.thumbnail((1300, 1900)); preview.convert('RGB').save(OUT/f'{name}-preview.jpg', quality=94)
        del master
        print('Composed continuous surface', name, flush=True)
    for mid in (341, 382):
        image = Image.open(OLD/f'city-{mid}-world.png').convert('RGBA')
        result = closed_cutaway(image, 96); result.save(OUT/f'city-{mid}-world.png')
        cities.append(dict(id=mid, mode='Original projected underground rooms, enclosing rock cutaway; source rooms unchanged',
                           source_sha256=hashlib.sha256((OLD/f'city-{mid}-world.png').read_bytes()).hexdigest()))
    json_write(OUT/'cities.json', cities)


def save_pyramid(image, rect, prefix, files, densities):
    """Four-pixel gutters share identical BC2 blocks across every neighbour.

    248 interior pixels keep the 4x4 compression grid aligned. One-pixel gutters
    can encode the same geographic sample with two different endpoint palettes.
    """
    inner = 248; gutter = 4; levels = []
    for density in densities:
        size = (round(rect[2]*density), round(rect[3]*density))
        im = image if image.size == size else image.resize(size, Image.Resampling.LANCZOS)
        cols = math.ceil(im.width/inner); rows = math.ceil(im.height/inner); present = {}; alpha = im.getchannel('A')
        for row in range(rows):
            for col in range(cols):
                x, y = col*inner, row*inner
                if not alpha.crop((x, y, x+inner, y+inner)).getbbox(): continue
                name = f'{prefix}_{density}_{col}_{row}.blp'
                payload = encode_blp(im.crop((x-gutter, y-gutter, x+inner+gutter, y+inner+gutter)))
                (OUT/'Art'/name).write_bytes(payload)
                files.append(dict(file=name, sha256=hashlib.sha256(payload).hexdigest()))
                present[row*cols+col+1] = True
        levels.append(dict(density=density, cols=cols, rows=rows, tiles=present, prefix=f'{prefix}_{density}'))
    return dict(rect=rect, levels=levels, inner=inner, gutter=gutter)


def pack():
    (OUT/'Art').mkdir(exist_ok=True); atlas.OUT = OUT
    terrain = atlas.read_terrain(ADDON/'TerrainData.lua'); previous = json.loads((OLD/'manifest.json').read_text(encoding='utf8'))
    files = []; continents = []; cities = {}
    for scene in previous['continents']:
        cid = scene['id']; name = 'Kalimdor' if cid == 1 else 'Azeroth'
        current = save_pyramid(Image.open(OUT/f'{name}-packed.png').convert('RGBA'), scene['rect'], f'v9_t{cid}', files, (1, 2, 4, 8, 16, 32))
        current['id'] = cid; continents.append(current); print('Packed', name, len(files), flush=True)
    for mid in (301, 321, 341, 362, 381, 382, 509):
        old = terrain['cities'][mid]; r = [old['rect'][i] for i in range(1, 5)]
        levels = (16, 32, 96) if mid in (341, 382) else (8, 16, 32, 64)
        cities[mid] = save_pyramid(Image.open(OUT/f'city-{mid}-world.png').convert('RGBA'), r, f'v9_city{mid}', files, levels)
        if mid in (341, 382): cities[mid]['indoor'] = True
    terrain.update(continents=continents, cities=cities, revision=9); atlas.write_terrain(terrain)
    manifest = dict(version='0.8.0', files=files, continents=continents, total_files=len(files),
                    total_bytes=sum((OUT/'Art'/f['file']).stat().st_size for f in files),
                    cities=json.loads((OUT/'cities.json').read_text(encoding='utf8')),
                    sources=[json.loads((OUT/f'{name}-sources.json').read_text(encoding='utf8')) for name in ('Kalimdor', 'Azeroth')],
                    review_plan_sha256=hashlib.sha256(PLAN.read_bytes()).hexdigest(),
                    map_data_sha256=hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest(),
                    limits='Offline terrain/material reconstruction; uncertain margins are decorative. No actual game acceptance or recovered absent native landmarks is claimed.')
    json_write(OUT/'manifest.json', manifest)


def audit():
    report = json.loads((OUT/'manifest.json').read_text(encoding='utf8'))
    terrain = atlas.read_terrain(OUT/'TerrainData.lua'); expected = {f['file'] for f in report['files']}
    references = set(); pairs = 0; largest = 0
    @functools.lru_cache(maxsize=128)
    def tile(filename): return np.asarray(decode_blp((OUT/'Art'/filename).read_bytes()).convert('RGBA'))
    for row in report['files']:
        payload = (OUT/'Art'/row['file']).read_bytes()
        assert hashlib.sha256(payload).hexdigest() == row['sha256']
        assert decode_blp(payload).size == (256, 256)
    for scene in list(terrain['continents'].values())+list(terrain['cities'].values()):
        assert scene['inner'] == 248 and scene['gutter'] == 4
        for level in scene['levels'].values():
            assert all(type(index) is int for index in level['tiles'])
            for index in level['tiles']:
                row, col = divmod(index-1, level['cols']); filename = f'{level["prefix"]}_{col}_{row}.blp'
                references.add(filename)
                for dc, dr in ((1, 0), (0, 1)):
                    neighbour = f'{level["prefix"]}_{col+dc}_{row+dr}.blp'
                    if neighbour not in expected: continue
                    a = tile(filename); b = tile(neighbour)
                    # Check both halves of the shared eight geographic pixels,
                    # including corners and all four RGBA channels after BC2.
                    comparisons = ((a[:, 252:256], b[:, 4:8]), (a[:, 248:252], b[:, :4])) if dc else ((a[252:256], b[4:8]), (a[248:252], b[:4]))
                    for left, right in comparisons:
                        delta = int(np.abs(left.astype('int16')-right.astype('int16')).max())
                        largest = max(largest, delta); assert delta == 0, (filename, neighbour, delta)
                    pairs += 1
    assert references == expected
    assert {p.name for p in (OUT/'Art').glob('*.blp')} == expected
    assert hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest() == report['map_data_sha256']
    room_pixels = {}; roads = {}; model_pixels = {}
    for mid in (341, 382):
        before = np.asarray(Image.open(OLD/f'city-{mid}-world.png').convert('RGBA'))
        after = np.asarray(Image.open(OUT/f'city-{mid}-world.png').convert('RGBA'))
        opaque = before[:, :, 3] == 255
        assert np.array_equal(before[opaque], after[opaque])
        assert terrain['cities'][mid]['indoor'] is True
        room_pixels[str(mid)] = int(opaque.sum())
    for scene in report['continents']:
        cid = scene['id']; name = 'Kalimdor' if cid == 1 else 'Azeroth'; extent = scene['rect']
        native = Image.open(OLD/f'{name}-before.png').convert('RGBA').resize((extent[2]*32, extent[3]*32), Image.Resampling.LANCZOS)
        rebuilt = Image.open(OUT/f'{name}-terrain.png').convert('RGBA')
        road = Image.open(OUT/f'{name}-roads.png'); count = 0
        for y in range(0, rebuilt.height, 128):
            b = (0, y, rebuilt.width, min(rebuilt.height, y+128)); size = (b[2], b[3]-b[1])
            protected = floating(crop_field(road, b, size)) > 254.99
            if not protected.any(): continue
            old = np.asarray(native.crop(b)); new = np.asarray(rebuilt.crop(b))
            assert np.array_equal(old[protected], new[protected]), ('Road protection', name, y)
            count += int(protected.sum())
        roads[name] = count; del native, rebuilt
        master = Image.open(OUT/f'{name}-packed.png').convert('RGBA')
        objects = []
        for m in source_maps():
            if not m.get('city') or m['map'] != cid or m['id'] in (341, 382): continue
            directory = PREVIOUS if m['id'] == 301 else OLD
            info = json.loads((directory/f'city-{m["id"]}-sources.json').read_text(encoding='utf8'))
            xy = [tuple(map(int, re.search(r'_(\d+)_(\d+)\.adt$', source['path']).groups())) for source in info['adt']]
            bounds = (min(x for x, y in xy), min(y for x, y in xy), max(x for x, y in xy)+1, max(y for x, y in xy)+1)
            image, world = registered_model(f'city-{m["id"]}', directory, cid, bounds)
            objects.append((str(m['id']), image, world))
        if cid == 1:
            image, world = registered_model('aq-join', OLD, cid, (26, 43, 33, 53)); objects.append(('aq', image, world))
            info = json.loads((PREVIOUS/'landscape-audit.json').read_text(encoding='utf8'))
            image = Image.open(PREVIOUS/'diremaul.png').convert('RGBA')
            image.putalpha(Image.frombytes('L', image.size, (PREVIOUS/'diremaul.coverage').read_bytes()))
            objects.append(('diremaul', image, info['diremaul_world_rect']))
        for label, image, world in objects:
            b = box_for(world, extent, 32); image = image.resize((b[2]-b[0], b[3]-b[1]), Image.Resampling.LANCZOS)
            left, top = max(0, b[0]), max(0, b[1]); right, bottom = min(master.width, b[2]), min(master.height, b[3])
            source = np.asarray(image.crop((left-b[0], top-b[1], right-b[0], bottom-b[1])))
            actual = np.asarray(master.crop((left, top, right, bottom))); solid = source[:, :, 3] == 255
            assert np.array_equal(actual[solid], source[solid]), ('Model footprint', label)
            model_pixels[label] = int(solid.sum())
        del master, objects
    report['quality_audit'] = dict(files_checked=len(expected), numeric_references_checked=len(references),
        terrain_lua_sha256=hashlib.sha256((OUT/'TerrainData.lua').read_bytes()).hexdigest(),
        block_aligned_neighbour_pairs=pairs, maximum_shared_rgba_delta=largest,
        opaque_source_room_pixels_unchanged=room_pixels, protected_road_pixels_unchanged=roads,
        opaque_source_model_pixels_unchanged=model_pixels,
        map_data_sha256=report['map_data_sha256'],
        replaces='Whole city/AQ rectangle and old coast-alpha locks are deliberately retired; actual source coordinates, roads, enabled liquid and model/room footprints are checked instead.',
        game_verified=False)
    json_write(OUT/'manifest.json', report)
    print('Technical candidate audit', report['quality_audit'], flush=True)


def deploy():
    report = json.loads((OUT/'manifest.json').read_text(encoding='utf8'))
    quality = report['quality_audit']; review = report['visual_review']
    assert quality['files_checked'] == report['total_files'] and quality['maximum_shared_rgba_delta'] == 0
    assert review['findings_reviewed'] == 51 and review['regions_reviewed'] == 60 and review['geographic_windows_reviewed'] == 98
    assert review['blocking_regressions'] == 0
    assert quality['terrain_lua_sha256'] == hashlib.sha256((OUT/'TerrainData.lua').read_bytes()).hexdigest()
    assert report['map_data_sha256'] == hashlib.sha256((ADDON/'MapData.lua').read_bytes()).hexdigest()
    art = (ADDON/'Art').resolve(); assert art.is_relative_to(ROOT.resolve())
    expected = {f['file'] for f in report['files']}
    for row in report['files']:
        assert re.fullmatch(r'v9_(?:t[01]|city(?:301|321|341|362|381|382|509))_\d+_\d+_\d+\.blp', row['file'])
        assert hashlib.sha256((OUT/'Art'/row['file']).read_bytes()).hexdigest() == row['sha256']
    for row in report['files']: shutil.copyfile(OUT/'Art'/row['file'], art/row['file'])
    # Delete only obsolete plugin atlas families, never source archives or
    # another addon's resources. Exact expected assets were verified above.
    for path in art.glob('*.blp'):
        if re.fullmatch(r'v[789]_(?:t[01]|city\d+)_\d+_\d+_\d+\.blp', path.name) and path.name not in expected:
            assert path.resolve().parent == art; path.unlink()
    shutil.copyfile(OUT/'TerrainData.lua', ADDON/'TerrainData.lua')
    json_write(ROOT/'PluginHistory/Research/TurtleSeamlessMap-0.8.0地形资源-20261025.json', report)
    print('Deployed reviewed landscape', report['total_files'], flush=True)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('step', choices=('prepare', 'classify', 'materials', 'world', 'compose', 'pack', 'audit', 'deploy'))
    p.add_argument('--continent', type=int, choices=(0, 1))
    args = p.parse_args()
    if args.step in ('prepare', 'classify', 'materials', 'world') and args.continent is None: p.error('--continent is required')
    if args.step == 'prepare': prepare(args.continent)
    if args.step == 'classify': classify(args.continent)
    if args.step == 'materials': material_fields(args.continent)
    if args.step == 'world': rebuild(args.continent)
    if args.step == 'compose': compose()
    if args.step == 'pack': pack()
    if args.step == 'audit': audit()
    if args.step == 'deploy': deploy()


if __name__ == '__main__': main()
