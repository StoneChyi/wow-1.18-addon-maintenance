"""Independent, local-font raster oracle for resource-number optical alignment.

The source is rendered at 1000px to separate font ink geometry from platform
small-font hinting, then projected onto physical UI pixels. This checks the
real TTF silhouettes rather than trusting the Lua metric table. It does not
claim that Pillow is the game's renderer. No screenshots or WTF are read.
"""
from functools import lru_cache
import math
from pathlib import Path
import sys
import unittest

from PIL import Image, ImageDraw, ImageFont
from test_pfui_energybar import MOCK, ROOT, ARGS, REMAINING

sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime


@lru_cache(maxsize=None)
def raster_1000(font_path, value):
    """Return actual alpha ink plus its vertical coordinates about mm anchor."""
    font = ImageFont.truetype(str(font_path), 1000)
    # Font bbox is only used to allocate the canvas; the oracle measures alpha.
    bounds = font.getbbox(value, anchor="mm")
    pad = 64
    width = max(1, bounds[2] - bounds[0]) + 2 * pad
    height = max(1, bounds[3] - bounds[1]) + 2 * pad
    image = Image.new("L", (width, height))
    anchor = (pad - bounds[0], pad - bounds[1])
    ImageDraw.Draw(image).text(anchor, value, font=font, fill=255, anchor="mm")
    ink = image.getbbox()
    if ink is None:
        return None
    return image.crop(ink), ink[1] - anchor[1], ink[3] - anchor[1]


def render_ink_error(font_path, value, size, scale, offset, track_height=9):
    """Rasterize the corrected label against a full physical strip, in memory."""
    source, top, bottom = raster_1000(str(font_path), value)
    factor = size * scale / 1000
    width = max(1, round(source.width * factor))
    height = max(1, round((bottom - top) * factor))
    glyph = source.resize((width, height), Image.Resampling.LANCZOS)
    track_pixels = max(1, round(track_height * scale))
    center = 32 + track_pixels / 2
    glyph_y = round(center + top * factor - offset * scale)
    canvas = Image.new("L", (width + 32, max(128, glyph_y + height + 32)))
    canvas.paste(glyph, (16, glyph_y))
    ink = canvas.getbbox()
    assert ink is not None, "visible resource glyphs unexpectedly disappeared"
    return (ink[1] + ink[3]) / 2 - center


class FontHarness:
    def __init__(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        install = self.lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))
        install(self.lua.globals().methods, self.lua.globals().object)
        self.lua.execute("pfUI.api={};track=object('Frame',nil,UIParent);track.width=250;track.height=9")
        self.lua.execute((ARGS.addons / "pfUI/api/resourcebar.lua").read_text(encoding="utf-8-sig"))
        self.lua.execute("label=track:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')")

    def align(self, file, size, value, align="CENTER"):
        label = self.lua.globals().label
        label.SetFont(label, file, size, "OUTLINE")
        label.SetText(label, value)
        return self.lua.globals().pfUI.api.AlignResourceBarText(label, self.lua.globals().track, align, size)


class ResourceFontRender(unittest.TestCase):
    def assert_label_ink_centered(self, label, track, scale=1.4):
        self.assertIsNotNone(label.font)
        file, size = label.font[1], label.font[2]
        value = label.GetText(label)
        self.assertTrue(value)
        error = render_ink_error(ROOT / file.replace("\\", "/"), value, size, scale,
                                 label.point[5], track.GetHeight(track))
        self.assertLessEqual(abs(error), 1, (file, value, size, scale, error))
        self.assertEqual(label.point[4], 0)
        self.assertEqual(label.GetWidth(label), track.GetWidth(track))

    def test_screenshot_configuration_reproduces_old_downward_ink_bias(self):
        path = ROOT / "Fonts/FZXHLJW.ttf"
        _, top, bottom = raster_1000(str(path), "6000 / 6000")
        old_bias = (top + bottom) / 2000 * 15 * 1.4
        self.assertAlmostEqual(old_bias, 2.499, delta=.03)
        self.assertGreater(render_ink_error(path, "6000 / 6000", 15, 1.4, 0), 1.5)
        harness = FontHarness()
        correction = harness.align("Fonts\\FZXHLJW.ttf", 15, "6000 / 6000")
        self.assertLessEqual(abs(render_ink_error(path, "6000 / 6000", 15, 1.4, correction)), 1)

    def test_real_fonts_values_sizes_and_scales_center_the_visible_ink(self):
        paths = [ROOT / "Fonts/FRIZQT__.ttf", ROOT / "Fonts/FZXHLJW.ttf", ROOT / "Fonts/FZJZJW.TTF"]
        paths.extend(path for path in sorted((ARGS.addons / "pfUI/fonts").glob("*.ttf"))
                     if path.name.lower() != "adobeblank.ttf")
        harness = FontHarness()
        values = ("0", "1", "100", "6178", "88%", "100%", "6000 / 6000", "100% 6000 / 6000")
        for path in paths:
            relative = ("Fonts\\" + path.name if path.parent == ROOT / "Fonts"
                        else "Interface\\AddOns\\pfUI\\fonts\\" + path.name)
            for value in values:
                for size in (8, 12, 15, 20, 24):
                    correction = harness.align(relative, size, value)
                    self.assertTrue(math.isfinite(correction), (path, value, size))
                    for scale in (.75, 1, 1.4, 2):
                        error = render_ink_error(path, value, size, scale, correction)
                        self.assertLessEqual(abs(error), 1, (path.name, value, size, scale, correction, error))

    def test_actual_loaded_font_and_size_win_over_requested_defaults(self):
        harness = FontHarness()
        harness.align("Fonts\\FZJZJW.TTF", 15, "6000 / 6000")
        label = harness.lua.globals().label
        expected = harness.lua.globals().pfUI.api.AlignResourceBarText(label, harness.lua.globals().track, "CENTER", 80)
        _, top, bottom = raster_1000(str(ROOT / "Fonts/FZJZJW.TTF"), "6000 / 6000")
        self.assertAlmostEqual(expected, (top + bottom) * 15 / 2000, places=6)

    def test_unknown_fonts_characters_and_empty_values_have_zero_compensation(self):
        harness = FontHarness()
        for file, value in (("UnknownFont.ttf", "100"), ("Fonts\\FZXHLJW.ttf", "未知"),
                            ("Fonts\\FZXHLJW.ttf", ""), ("Fonts\\FZXHLJW.ttf", " ")):
            self.assertEqual(harness.align(file, 15, value), 0)

    def test_font_failure_uses_template_and_relayout_is_stable(self):
        harness = FontHarness()
        harness.lua.execute("failedFontPaths['Missing.ttf']=true;assert(not label:SetFont('Missing.ttf',15,'OUTLINE'));label:SetText('100%')")
        label = harness.lua.globals().label
        api = harness.lua.globals().pfUI.api
        api.AlignResourceBarText(label, harness.lua.globals().track, "RIGHT", 15)
        self.assertIsNotNone(label.font)
        point_writes = label.calls.point
        api.AlignResourceBarText(label, harness.lua.globals().track, "RIGHT", 15)
        self.assertEqual(label.calls.point, point_writes)
        self.assertEqual(label.point[4], 0)
        self.assertEqual(label.GetWidth(label), 250)
        self.assertEqual(label.justifyV, "MIDDLE")

    def test_real_energybar_and_druid_mana_center_ink_on_unchanging_full_tracks(self):
        from test_pfui_energybar import Harness as EnergyHarness
        harness = EnergyHarness(enabled=True, druid=True, config={
            "comboenergydruidmana": "1", "comboenergywidth": "250", "comboenergyheight": "9",
            "comboenergyfontsize": "15", "comboenergydruidmanaheight": "9", "comboenergysmooth": "0"})
        harness.execute(r"pfUI.font_default='Fonts\\FZXHLJW.ttf'")
        same = harness.lua.eval("function(a,b) return a==b end")
        widths = []
        for alignment in ("left", "center", "right"):
            for format in (0, 1, 2):
                harness.update(comboenergytextformat=str(format), comboenergytextalign=alignment)
                for value in (1, 11, 88, 100):
                    harness.execute(f"resource={value};baseMana={1000+value}")
                    harness.advance(.15)
                    for owner in (harness.frame, harness.mana_frame()):
                        track, label = owner.track, owner.text
                        self.assertTrue(same(label.point[2], track))
                        self.assertTrue(same(track.point[2], owner))
                        self.assertEqual(track.GetWidth(track), 250)
                        self.assertEqual(track.GetHeight(track), 9)
                        self.assertEqual(track.point[4], 0)
                        self.assertEqual(track.point[5], 0)
                        self.assert_label_ink_centered(label, track)
                    widths.append(harness.fill().GetWidth(harness.fill()))
        self.assertGreater(max(widths) - min(widths), 200)
        harness.unchanged()

    def test_real_compatibility_bars_center_ink_on_full_inset_tracks(self):
        from test_pfui_resourcebars import Harness as CompatibilityHarness
        harness = CompatibilityHarness()
        harness.start()
        harness.execute(r"""
        for _,key in ipairs({'erb_hp','erb_pp'}) do
          local option=C.resourcebars.data[key]
          option.width=250;option.height=14;option.border=3;option.fontSize=15
          option.font='Fonts\\FZJZJW.TTF'
        end
        """)
        same = harness.lua.eval("function(a,b) return a==b end")
        for alignment in ("LEFT", "CENTER", "RIGHT"):
            for format in (1, 2, 3, 4):
                harness.execute(f"""
                for _,key in ipairs({{'erb_hp','erb_pp'}}) do
                  C.resourcebars.data[key].barResize='{alignment}'
                  C.resourcebars.data[key].textAlign='{alignment}'
                  C.resourcebars.data[key].textType={format}
                end
                """)
                harness.refresh()
                for value in (1, 11, 88, 100):
                    harness.execute(f"health={value};healthMax=100;resource={value};maximum=100;dispatchEvent('UNIT_HEALTH','player');dispatchEvent('UNIT_MANA','player')")
                    harness.advance(.1)
                    for owner in (harness.health, harness.power):
                        track, label = owner.track, owner.text
                        self.assertTrue(same(label.point[2], track))
                        self.assertTrue(same(track.point[2], owner))
                        self.assertFalse(same(label.point[2], owner.bar))
                        self.assertEqual(track.GetWidth(track), 242)
                        self.assertEqual(track.GetHeight(track), 9)
                        self.assertEqual(track.point[1], alignment)
                        self.assert_label_ink_centered(label, track)
        harness.execute("assertLegacyUnchanged();otherFramesUnchanged()")


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]] + REMAINING, verbosity=2)
