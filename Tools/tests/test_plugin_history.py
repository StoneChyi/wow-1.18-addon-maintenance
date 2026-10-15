"""Record identity, ordering and status guards for the generated change index."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from plugin_history import parse_entries, outputs, write_text, REPOSITORY


def entry(day="2026-10-15", number="01", title="调整显示", kind="修改", game="待游戏验收", source=None):
    record_id = "Fixture-" + day.replace("-", "") + "-" + number
    source = source or "随本条记录一并提交（见本页 Git 历史）"
    return f'''<a id="change-{record_id}"></a>

### {day}｜{title}

- 记录编号：`{record_id}`
- 记录类型：{kind}
- 游戏验收：{game}
- 对应提交：{source}

- 修改内容：保留真实行为说明。
- 验证：模拟检查通过，游戏未实测。

'''


def page(content):
    return "# Fixture 修改说明\n\n## 插件概况\n\n## 当前维护摘要\n\n## 逐次修改记录\n\n" + content + "## 早期历史汇总与维护依据\n"


class RecordTests(unittest.TestCase):
    def test_same_commit_placeholder_and_user_feedback(self):
        result = parse_entries(page(entry(kind="实测反馈", game="用户实测（限本条范围）")), "Fixture")
        self.assertEqual(result[0]["commits"], [])
        self.assertEqual(result[0]["game_acceptance"], "用户实测（限本条范围）")

    def test_existing_commits(self):
        sha = "a" * 40
        result = parse_entries(page(entry(source=f"[aaaaaaa]({REPOSITORY}/commit/{sha})")), "Fixture")
        self.assertEqual(result[0]["commits"], [sha])

    def test_multiple_same_day_and_other_dates(self):
        result = parse_entries(page(entry(number="02") + entry() + entry(day="2026-10-14")), "Fixture")
        self.assertEqual(len(result), 3)

    def test_ascending_order_rejected(self):
        with self.assertRaises(AssertionError): parse_entries(page(entry() + entry(number="02")), "Fixture")

    def test_duplicate_ids_rejected(self):
        with self.assertRaises(AssertionError): parse_entries(page(entry() + entry()), "Fixture")

    def test_identity_mismatch_rejected(self):
        with self.assertRaises(AssertionError): parse_entries(page(entry()).replace('id="change-Fixture', 'id="change-Other'), "Fixture")

    def test_invalid_date_rejected(self):
        with self.assertRaises(ValueError): parse_entries(page(entry(day="2026-02-30")), "Fixture")

    def test_missing_anchor_rejected(self):
        with self.assertRaises(AssertionError): parse_entries(page(entry()).replace('<a id="change-Fixture-20261015-01"></a>', ''), "Fixture")

    def test_invalid_status_and_kind_rejected(self):
        for content in [entry(kind="假定已修改"), entry(game="全部功能已通过")]:
            with self.subTest(content=content), self.assertRaises(AssertionError): parse_entries(page(content), "Fixture")

    def test_missing_and_duplicate_fields_rejected(self):
        for content in [entry().replace('- 游戏验收：待游戏验收\n', ''), entry().replace('- 游戏验收：待游戏验收\n', '- 游戏验收：待游戏验收\n- 游戏验收：待游戏验收\n')]:
            with self.subTest(content=content), self.assertRaises(AssertionError): parse_entries(page(content), "Fixture")

    def test_nested_original_headings_and_crlf(self):
        self.assertEqual(len(parse_entries(page(entry().replace('- 修改内容：', '### 具体内容\n\n- 修改内容：')).replace('\n', '\r\n'), "Fixture")), 1)

    def test_undated_legacy_content_is_not_an_event(self):
        self.assertEqual(parse_entries("# Fixture 修改说明\n\n## 当前记录\n尚未确认。", "Fixture"), [])

    def test_generated_indexes_and_idempotent_bytes(self):
        parent = Path(__file__).resolve().parents[2] / 'PluginHistory/check-results'
        parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='plugin-history-', dir=parent) as directory:
            root = Path(directory).resolve()
            assert root.is_relative_to(parent.resolve())
            notes = root / 'PluginHistory/Plugins'; notes.mkdir(parents=True)
            (notes / 'README.md').write_bytes(b'\xef\xbb\xbf# index\r\n')
            (notes / 'Fixture.md').write_text(page(entry()), encoding='utf-8')
            (notes / 'Unknown.md').write_text('# Unknown 修改说明\n', encoding='utf-8')
            (root / 'PluginHistory/maintenance-index.json').write_text(json.dumps({'addons': [
                {'addon': 'Fixture', 'status': 'documented_history', 'note': 'PluginHistory/Plugins/Fixture.md', 'purpose': '真实修改'},
                {'addon': 'Unknown', 'status': 'unconfirmed', 'note': 'PluginHistory/Plugins/Unknown.md', 'purpose': '待确认'}]}), encoding='utf-8')
            generated, _ = outputs(root)
            self.assertIn('Fixture.md#change-Fixture-20261015-01', generated['PluginHistory/Plugins/README.md'])
            self.assertNotIn('[Unknown]', generated['PluginHistory/Plugins/README.md'])
            self.assertIn('[Unknown]', generated['PluginHistory/待确认插件.md'])
            for name, text in generated.items(): write_text(root / name, text)
            snapshot = {name: (root / name).read_bytes() for name in generated}
            repeated, _ = outputs(root)
            for name, text in repeated.items(): write_text(root / name, text)
            self.assertEqual(snapshot, {name: (root / name).read_bytes() for name in generated})
            self.assertTrue(snapshot['PluginHistory/Plugins/README.md'].startswith(b'\xef\xbb\xbf'))
            self.assertNotIn(b'\n', snapshot['PluginHistory/Plugins/README.md'].replace(b'\r\n', b''))


if __name__ == '__main__':
    unittest.main()
