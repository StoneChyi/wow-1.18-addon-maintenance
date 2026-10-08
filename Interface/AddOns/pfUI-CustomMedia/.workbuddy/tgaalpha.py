import sys, struct

def alpha_stats(path):
    data = open(path, 'rb').read()
    itype = data[2]
    w, h = struct.unpack('<H', data[12:14])[0], struct.unpack('<H', data[14:16])[0]
    depth, desc = data[16], data[17]
    bpp = depth // 8
    pixels = []
    pos = 18 + data[0]
    if itype == 10:
        while len(pixels) < w * h:
            pkt = data[pos]; pos += 1
            cnt = (pkt & 0x7F) + 1
            if pkt & 0x80:
                px = data[pos:pos+bpp]; pos += bpp
                pixels.extend([px] * cnt)
            else:
                for _ in range(cnt):
                    pixels.append(data[pos:pos+bpp]); pos += bpp
    else:
        body = data[18:]
        for i in range(w * h):
            pixels.append(body[i*bpp:(i+1)*bpp])
    if bpp == 4:
        alphas = [p[3] for p in pixels if len(p) == 4]
        zeros = sum(1 for a in alphas if a == 0)
        full = sum(1 for a in alphas if a == 255)
        print(f"{path}: {w}x{h} bpp={bpp} desc={desc:#04x} alpha: min={min(alphas)} max={max(alphas)} zeros={zeros}/{len(alphas)} full255={full}")
    else:
        print(f"{path}: {w}x{h} bpp={bpp} (no alpha channel)")

for p in sys.argv[1:]:
    alpha_stats(p)
