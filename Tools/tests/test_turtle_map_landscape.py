"""Production regressions for source/semantic landscape reconstruction."""
import json
from pathlib import Path
import struct
import sys
import unittest

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import rebuild_turtle_map_landscape as landscape


class LandscapeTests(unittest.TestCase):
    def test_liquid_disabled_quads_and_dry_vertices_do_not_flood_whole_chunk(self):
        flags = np.full((8, 8), 15, dtype='u1'); flags[:4, :4] = 0
        water = struct.pack('<2f', 2, 2)+b''.join(struct.pack('<If', 0, 2) for _ in range(81))+flags.tobytes()
        cell = dict(water=True, children={b'QLCM': water}, heights=np.zeros((9, 9)))
        wet, depth = landscape.liquid_field(cell, 32)
        self.assertTrue(wet[:16, :16].all()); self.assertFalse(wet[16:, :].any()); self.assertFalse(wet[:, 16:].any())
        self.assertTrue(np.all(depth == 2))
        cell['heights'][:] = 3
        self.assertFalse(landscape.liquid_field(cell, 32)[0].any())
        cell['children'][b'QLCM'] = b'\0'*8
        self.assertFalse(landscape.liquid_field(cell, 32)[0].any())

    def test_road_weights_follow_actual_alpha_not_whole_chunk(self):
        # A road is only the right half; merely mentioning a road texture must
        # not preserve a rectangular 33-yard chunk around it.
        values = np.zeros((64, 64), dtype='uint8'); values[:, 32:] = 15
        packed = (values.reshape(-1, 2)[:, 0] | values.reshape(-1, 2)[:, 1] << 4).tobytes()
        cell = dict(children={b'YLCM': struct.pack('<8I', 0, 0, 0, 0, 1, 0, 0, 0), b'LACM': packed})
        mask = np.asarray(landscape.road_field(cell, ['soil.blp', 'humanroad.blp'], 64))
        self.assertEqual(int(mask[:, :28].max()), 0); self.assertEqual(int(mask[:, 36:].min()), 255)
        weights = landscape.material_weights(cell, ['soil.blp', 'humanroad.blp'])
        self.assertAlmostEqual(sum(weights.values()), 1, places=6)
        self.assertAlmostEqual(weights['soil.blp'], .5, places=6)
        self.assertAlmostEqual(weights['humanroad.blp'], .5, places=6)

    def test_context_ignores_untrusted_placeholder_colours(self):
        a = np.empty((80, 100, 3), np.float32); a[:] = (100, 140, 70)
        trust = np.ones((80, 100), np.float32); trust[20:60, 30:70] = 0
        a[20:60, 30:70] = (0, 0, 0)
        result = landscape.context_field(a, trust, (80, 80, 80))
        self.assertLess(float(np.abs(result[35:45, 45:55]-(100, 140, 70)).max()), .01)

    def test_long_line_repair_is_limited_to_reviewed_allowed_pixels(self):
        a = np.empty((80, 100, 3), np.uint8); a[:, :50] = (30, 100, 30); a[:, 50:] = (180, 80, 20)
        allowed = Image.new('L', (100, 80)); ImageDraw.Draw(allowed).rectangle((0, 20, 99, 60), fill=255)
        mask = np.asarray(landscape.palette_borders(Image.fromarray(a), Image.new('L', (100, 80), 255), allowed))
        # Palette quantization may place several contours in the softened
        # transition; none may escape the reviewed/allowed rectangle.
        self.assertTrue(mask[20:60].any()); self.assertFalse(mask[:20].any()); self.assertFalse(mask[61:].any())

    def test_field_sampling_preserves_global_alignment_at_canvas_edges(self):
        source = Image.fromarray(np.arange(100, dtype='float32').reshape(10, 10))
        sample = landscape.crop_field(source, (-8, -8, 8, 8), (16, 16))
        self.assertEqual(sample.size, (16, 16)); self.assertEqual(sample.getpixel((0, 0)), 0)
        # Interior windows of a shared field must have the same sample phase.
        full = landscape.crop_field(source, (0, 0, 80, 80), (80, 80))
        right = landscape.crop_field(source, (40, 0, 80, 80), (40, 80))
        self.assertLess(float(np.abs(np.asarray(full)[:, 42:]-np.asarray(right)[:, 2:]).max()), 1e-4)

    def test_cutaway_fills_enclosed_surface_gap_but_never_its_rectangular_corners(self):
        image = Image.new('RGBA', (320, 320)); d = ImageDraw.Draw(image)
        d.ellipse((70, 70, 250, 250), fill=(100, 90, 70, 255)); d.ellipse((110, 110, 210, 210), fill=(0, 0, 0, 0))
        result = landscape.closed_cutaway(image, 96)
        self.assertEqual(result.getpixel((160, 160))[3], 255)
        self.assertEqual(result.getpixel((0, 0))[3], 0)
        self.assertEqual(result.getpixel((160, 80)), image.getpixel((160, 80)))

    def test_audit_register_retains_all_records_and_unconfirmed_candidates(self):
        plan = json.loads(landscape.PLAN.read_text(encoding='utf8'))
        self.assertEqual(len(plan['findings']), 51)
        self.assertEqual(len({r['id'] for r in plan['findings']}), 51)
        self.assertEqual({r['id'] for r in plan['findings'] if r['severity'] == 'V'}, {'C05', 'V01', 'V02', 'V03', 'T01'})

    def test_block_aligned_gutters_encode_identical_neighbour_colours(self):
        previous = landscape.OUT
        landscape.OUT = landscape.STAGING/'v9-gutter-test'; (landscape.OUT/'Art').mkdir(parents=True, exist_ok=True)
        try:
            pixels = np.random.default_rng(112).integers(0, 256, (496, 496, 4), dtype='uint8')
            files = []; scene = landscape.save_pyramid(Image.fromarray(pixels), [0, 0, 496, 496], 'fixture', files, (1,))
            self.assertEqual((scene['inner'], scene['gutter']), (248, 4))
            images = {(c, r): np.asarray(landscape.decode_blp((landscape.OUT/'Art'/f'fixture_1_{c}_{r}.blp').read_bytes()).convert('RGBA')) for c in (0, 1) for r in (0, 1)}
            np.testing.assert_array_equal(images[0, 0][:, 252:256], images[1, 0][:, 4:8])
            np.testing.assert_array_equal(images[0, 0][:, 248:252], images[1, 0][:, 0:4])
            np.testing.assert_array_equal(images[0, 0][252:256], images[0, 1][4:8])
            np.testing.assert_array_equal(images[0, 0][248:252], images[0, 1][0:4])
        finally:
            landscape.OUT = previous

    def test_material_mixtures_and_texture_phase_are_continuous_between_adts(self):
        surface = object.__new__(landscape.MaterialSurface)
        surface.manifest = dict(bounds=[0, 0, 2, 1]); surface.client = None
        x = np.arange(64, dtype=np.float32)/64*2*np.pi
        source = np.broadcast_to(128+55*np.sin(x)[None, :, None], (64, 64, 3)).copy()
        surface.cache = {'rock': source, 'grass': source[:, ::-1].copy()}
        blend = np.broadcast_to(np.linspace(0, 1, 32, dtype=np.float32)[None], (16, 32))
        surface.weights = {'rock': Image.fromarray(1-blend), 'grass': Image.fromarray(blend.copy())}
        left = np.asarray(surface.tile(0, 0, size=128, halo=16)).astype('int16')
        right = np.asarray(surface.tile(1, 0, size=128, halo=16)).astype('int16')
        # Shared halo samples represent the exact same world positions.
        self.assertLessEqual(int(np.abs(left[:, 128:160]-right[:, :32]).max()), 1)

    def test_native_landform_detail_survives_broad_material_reconstruction(self):
        native = Image.new('RGBA', (512, 512), (110, 100, 80, 255))
        draw = ImageDraw.Draw(native)
        draw.ellipse((125, 125, 155, 155), fill=(200, 185, 150, 255))
        draw.ellipse((170, 170, 190, 190), fill=(35, 30, 25, 255))
        gain = landscape.source_detail(native, (192, 192, 576, 576), (384, 384))
        self.assertGreater(float(gain[88, 88, 0]), 1.3)
        self.assertLess(float(gain[168, 168, 0]), .7)
        self.assertEqual(gain.shape, (384, 384, 3))


if __name__ == '__main__': unittest.main(verbosity=2)
