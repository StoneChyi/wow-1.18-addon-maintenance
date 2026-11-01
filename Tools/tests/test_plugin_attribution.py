"""Verify attribution metadata edits preserve original byte streams."""
import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("plugin_attribution", ROOT / "Tools/plugin_attribution.py")
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class AttributionTests(unittest.TestCase):
    def assert_additive(self, before):
        change = module.annotate_bytes(before)
        after = change.after
        self.assertEqual(module.annotate_bytes(after).after, after)
        reconstructed = []
        for line in after.splitlines(keepends=True):
            value, ending = module.content_and_ending(line)
            probe = value.removeprefix(b"\xef\xbb\xbf")
            if probe.startswith((b"## X-Maintained-By:", b"## X-Maintenance-Scope:")):
                continue
            if change.notes_added and probe == b"## Notes: " + module.VISIBLE:
                continue
            if module.NOTE.match(value):
                value = value.replace(module.NOTES_SUFFIX, b"")
            reconstructed.append(value + ending)
        recovered = b"".join(reconstructed)
        if before.startswith(b"\xef\xbb\xbf") and not recovered.startswith(b"\xef\xbb\xbf"):
            recovered = b"\xef\xbb\xbf" + recovered
        self.assertEqual(recovered, before)
        return change

    def test_crlf_utf8_bom_and_original_metadata(self):
        before = b"\xef\xbb\xbf## Interface: 11200\r\n## Author: Original Author\r\n## License: GPLv2\r\n## Notes: Original notes\r\n\r\nCore.lua\r\n"
        after = self.assert_additive(before).after
        self.assertTrue(after.startswith(b"\xef\xbb\xbf"))
        self.assertIn(b"## Author: Original Author\r\n## License: GPLv2\r\n", after)

    def test_mixed_endings_and_gbk_notes_unchanged(self):
        before = b"## Interface: 11200\r\n## Notes-zhCN: " + "原始说明".encode("gbk") + b"  \n## Notes-enUS: Keep me\r\nCore.lua"
        change = self.assert_additive(before)
        self.assertEqual(change.notes_updated, 2)
        self.assertFalse(change.after.endswith(b"\n"))

    def test_no_notes_adds_visible_notes(self):
        change = self.assert_additive(b"## Interface: 11200\n## Author: A\nCore.lua\n")
        self.assertTrue(change.notes_added)
        self.assertIn(b"## Notes: " + module.VISIBLE, change.after)

    def test_introductory_comment_and_mixed_tie_are_stable(self):
        raw = b"# Keep the following line!\r\n## Interface: 11200\r\nCore.lua\nEnd.lua\n"
        after = self.assert_additive(raw).after
        self.assertTrue(after.startswith(b"# Keep the following line!\r\n## Interface: 11200\r\n## X-Maintained-By:"))
        self.assertIn(b"StoneChyi & Codex\r\n", after)

    def test_existing_complete_credit_is_idempotent(self):
        first = module.annotate_bytes(b"## Interface: 11200\n## Notes: N\nCore.lua\n").after
        second = module.annotate_bytes(first)
        self.assertEqual(first, second.after)
        self.assertFalse(second.notes_added)
        self.assertEqual(second.notes_updated, 0)

    def test_duplicate_or_other_maintainers_are_not_overwritten(self):
        for raw in [b"## X-Maintained-By: Other Person\n", b"## X-Maintained-By: StoneChyi & Codex\n" * 2]:
            with self.assertRaises(ValueError):
                module.annotate_bytes(raw)

    def test_utf16_rejected_without_transcoding(self):
        with self.assertRaises(ValueError):
            module.annotate_bytes(b"\xff\xfe" + "## Interface: 11200\r\n".encode("utf-16-le"))

    def test_single_terminal_line_and_empty_file(self):
        for raw in [b"## Interface: 11200", b"\xef\xbb\xbf## Interface: 11200", b"", b"\n"]:
            self.assert_additive(raw)

    def test_plan_preserves_original_root_scope(self):
        selected, absent = module.targets(ROOT, exclude=["hyx"])
        self.assertIn("HideOutdoorWorldState", absent)
        self.assertNotIn("hyx", {row["addon"] for row, _ in selected})
        self.assertNotIn("UnitXP_SP3_Addon", {row["addon"] for row, _ in selected})
        self.assertTrue(all(toc.parent.parent == ROOT / "Interface/AddOns" for _, toc in selected))
        with self.assertRaises(ValueError):
            module.run("apply", ROOT, report="PluginHistory/MaintenanceAttribution.md")
        with self.assertRaises(ValueError):
            module.run("apply", ROOT, report="PluginHistory/Research/插件维护署名-20261102.json")


if __name__ == "__main__":
    unittest.main()
