"""Regenerate numeric ink bounds for pfUI resource bars from controlled fonts.

Reads only pfUI's bundled fonts and this fixed list of client font names. It
does not scan user font folders or character settings. Pillow is required.
Run in the maintained game tree; --check verifies without writing anything.
"""
from pathlib import Path
import argparse
import json

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BEGIN = "-- BEGIN GENERATED RESOURCE FONT METRICS"
END = "-- END GENERATED RESOURCE FONT METRICS"
CHARACTERS = "0123456789/%.,-"
CLIENT_FONTS = (
    "ARIALN.ttf", "ARKai_C.ttf", "FRIZQT__.ttf", "FZBWJW.ttf",
    "FZJZJW.TTF", "FZLBJW.ttf", "FZXHJW.ttf", "FZXHLJW.ttf",
)


def render_metrics(root: Path) -> str:
    fonts = [root / "Fonts" / name for name in CLIENT_FONTS]
    fonts.extend(sorted((root / "Interface/AddOns/pfUI/fonts").glob("*.ttf")))
    draw = ImageDraw.Draw(Image.new("L", (1, 1)))
    lines = [BEGIN, "local metrics = {"]
    for path in fonts:
        if not path.is_file():
            continue
        font = ImageFont.truetype(str(path), 1000)
        key = path.relative_to(root).as_posix().replace("/", "\\").lower()
        lines.append(f"  [{json.dumps(key)}] = {{")
        for char in CHARACTERS:
            _, top, _, bottom = draw.textbbox((0, 0), char, font=font, anchor="mm")
            if bottom > top:
                lines.append(f"    [{json.dumps(char)}] = {{{top}, {bottom}}},")
        lines.append("  },")
    lines.extend(["}", END])
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    output = args.root / "Interface/AddOns/pfUI/api/resourcebar.lua"
    source = output.read_text(encoding="utf-8")
    first, last = source.index(BEGIN), source.index(END) + len(END)
    updated = source[:first] + render_metrics(args.root) + source[last:]
    if args.check:
        if source != updated:
            parser.exit(1, "Resource-bar font metrics differ; regenerate in the maintained client tree.\n")
        print("Resource-bar font metrics match the controlled fonts.")
    else:
        output.write_bytes(updated.replace("\r\n", "\n").replace("\n", "\r\n").encode("utf-8"))
        print("Updated Interface/AddOns/pfUI/api/resourcebar.lua")


if __name__ == "__main__":
    main()
