"""Render the original diminfo line glyphs as transparent WoW 1.12 TGA files.

Run with Python + Pillow; --check verifies the committed assets byte for byte.
SVG sources and game textures share the same path definitions below.
"""
from io import BytesIO
from pathlib import Path
import argparse

from PIL import Image, ImageDraw, ImageFont

MEDIA = Path(__file__).resolve().parents[1] / 'Media' / 'Teleport'
SIZE, SCALE, STROKE = 32, 8, 2.4
PATHS = {
    'hearth': [
        [('M', 8, 25), ('C', 2, 19, 5, 7, 14, 5),
         ('C', 23, 3, 29, 10, 25, 19), ('C', 22, 26, 12, 27, 10, 20),
         ('C', 8, 14, 12, 10, 17, 12), ('C', 22, 14, 20, 21, 15, 19)],
    ],
    'verdant': [
        [('M', 7, 24), ('C', 1, 12, 13, 7, 26, 5),
         ('C', 25, 18, 22, 29, 10, 25)],
        [('M', 5, 28), ('L', 21, 11)],
    ],
    'time': [
        [('M', 7, 5), ('L', 25, 5)],
        [('M', 7, 27), ('L', 25, 27)],
        [('M', 9, 5), ('C', 9, 12, 12, 13, 16, 16),
         ('C', 20, 19, 23, 20, 23, 27)],
        [('M', 23, 5), ('C', 23, 12, 20, 13, 16, 16),
         ('C', 12, 19, 9, 20, 9, 27)],
    ],
    'guild': [
        [('M', 7, 28), ('L', 7, 5)],
        [('M', 8, 6), ('C', 14, 3, 19, 11, 25, 6),
         ('L', 25, 21), ('C', 19, 26, 14, 18, 8, 21)],
    ],
}


def points(commands):
    """Flatten cubic vector paths at a resolution above the output pixel grid."""
    result = []
    for command in commands:
        op, *values = command
        if op in ('M', 'L'):
            result.append(tuple(values))
        elif op == 'C':
            x0, y0 = result[-1]
            x1, y1, x2, y2, x3, y3 = values
            for step in range(1, 65):
                t = step / 64
                u = 1 - t
                result.append((u**3*x0 + 3*u*u*t*x1 + 3*u*t*t*x2 + t**3*x3,
                               u**3*y0 + 3*u*u*t*y1 + 3*u*t*t*y2 + t**3*y3))
        else:
            raise ValueError(op)
    return [(round(x*SCALE), round(y*SCALE)) for x, y in result]


def normalize(paths):
    """Give every glyph the same ink center and maximum visible extent."""
    cloud = [point for commands in paths for point in points(commands)]
    left, right = min(p[0] for p in cloud)/SCALE, max(p[0] for p in cloud)/SCALE
    top, bottom = min(p[1] for p in cloud)/SCALE, max(p[1] for p in cloud)/SCALE
    cx, cy = (left+right)/2, (top+bottom)/2
    factor = (24-STROKE)/max(right-left, bottom-top)
    return [[(command[0], *(round(16+(v-(cx if i%2==0 else cy))*factor, 6)
                            for i, v in enumerate(command[1:])))
             for command in commands] for commands in paths]


def render(paths):
    image = Image.new('RGBA', (SIZE*SCALE, SIZE*SCALE))
    draw = ImageDraw.Draw(image)
    width = round(STROKE*SCALE)
    for commands in paths:
        line = points(commands)
        draw.line(line, fill='white', width=width, joint='curve')
        for x, y in (line[0], line[-1]):
            radius = width/2
            draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill='white')
    image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    # Keep transparent texels white too, preventing dark fringes when tinted.
    alpha = image.getchannel('A')
    image = Image.new('RGBA', image.size, 'white')
    image.putalpha(alpha)
    return image


def svg(paths):
    lines = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"',
             ' fill="none" stroke="white" stroke-width="2.4"',
             ' stroke-linecap="round" stroke-linejoin="round">']
    for commands in paths:
        path = ' '.join(c[0]+' '.join(str(n) for n in c[1:]) for c in commands)
        lines.append(f'  <path d="{path}"/>')
    return ('\n'.join(lines)+'\n</svg>\n').encode()


def preview(images, destination):
    canvas = Image.new('RGB', (800, 180), '#141b1c')
    draw = ImageDraw.Draw(canvas)
    font_path = Path('C:/Windows/Fonts/msyh.ttc')
    font = ImageFont.truetype(str(font_path), 18)
    small = ImageFont.truetype(str(font_path), 13)
    draw.text((20, 12), 'DimInfo · 统一线条图标（下行接近实际显示尺寸）', font=small, fill='#a3b7b0')
    names = ['炉石', '翠绿符文', '时光符文', '公会战袍']
    for i, (key, image) in enumerate(images.items()):
        x = 24+i*196
        for y, size, color in [(47, 32, (77, 255, 153)), (108, 16, (77, 255, 153)),
                               (142, 16, (179, 179, 179))]:
            alpha = image.getchannel('A').resize((size, size), Image.Resampling.LANCZOS)
            tinted = Image.new('RGB', (size, size), color)
            canvas.paste(tinted, (x, y), alpha)
            text = names[i] + (' 就绪' if y == 108 else ' 冷却' if y == 142 else '')
            draw.text((x+size+8, y-3), text, font=font if size==32 else small, fill=color)
    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--preview', type=Path)
    args = parser.parse_args()
    images = {}
    for key, source in PATHS.items():
        paths = normalize(source)
        image = render(paths)
        images[key] = image
        buffer = BytesIO()
        image.save(buffer, format='TGA', compression=None)
        data = buffer.getvalue()
        assert data[2] == 2 and data[16] == 32 and data[17] & 15 == 8
        alpha = image.getchannel('A')
        assert alpha.getextrema() == (0, 255) and image.getpixel((0, 0))[3] == 0
        box = alpha.point(lambda v: 255 if v >= 128 else 0).getbbox()
        cx, cy = (box[0]+box[2])/2, (box[1]+box[3])/2
        assert abs(cx-16) <= .5 and abs(cy-16) <= .5, (key, box)
        assert 23 <= max(box[2]-box[0], box[3]-box[1]) <= 25, (key, box)
        for suffix, content in [('svg', svg(paths)), ('tga', data)]:
            path = MEDIA / (key+'.'+suffix)
            if args.check:
                assert path.read_bytes() == content, f'Asset differs: {path}'
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
    if args.preview:
        preview(images, args.preview)
    print('4 original line icons: transparent 32-bit uncompressed TGA + SVG verified')


if __name__ == '__main__':
    main()
