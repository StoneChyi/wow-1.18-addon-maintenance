import sys, struct

def check(path):
    data = open(path, 'rb').read()
    itype = data[2]
    w, h = struct.unpack('<H', data[12:14])[0], struct.unpack('<H', data[14:16])[0]
    depth, desc = data[16], data[17]
    print(f"{path}: type={itype} {w}x{h} depth={depth} desc={desc:#04x} size={len(data)}")
    if itype != 10:
        expected = w * h * (depth // 8)
        print(f"  raw, expect {expected} bytes payload, have {len(data)-18}")
        return
    bpp = depth // 8
    pos = 18 + data[0]
    pixels = 0
    past_end = False
    while pixels < w * h:
        if pos >= len(data):
            break
        pkt = data[pos]; pos += 1
        cnt = (pkt & 0x7F) + 1
        if pkt & 0x80:
            pos += bpp
        else:
            pos += cnt * bpp
        if pos > len(data):
            past_end = True
            break
        pixels += cnt
    print(f"  decoded pixels={pixels}/{w*h}, bytes consumed={pos-18}/{len(data)-18}, past_end={past_end}")
    if past_end:
        print("  !! RLE stream reads PAST end of file (corrupt)")

for p in sys.argv[1:]:
    check(p)
