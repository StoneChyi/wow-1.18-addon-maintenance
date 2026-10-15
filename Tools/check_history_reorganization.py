"""Audit the 2026-10-15 record movement against its actual Git source."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

from plugin_history import collect

ROOT = Path(__file__).resolve().parents[1]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def main():
    report = json.loads((ROOT / "PluginHistory/Research/记录方式整理-20261015.json").read_bytes())
    before = report["before_commit"]
    catalog, records = collect(ROOT)
    old_catalog = json.loads(git("show", before + ":PluginHistory/maintenance-index.json"))
    for key in ["reference_commit", "counts", "added_counts", "package_comparisons", "package_deployments"]:
        assert catalog[key] == old_catalog[key], key
    old_rows = old_catalog["addons"] + old_catalog.get("added_addons", [])
    for old, new in zip(old_rows, catalog["addons"] + catalog.get("added_addons", [])):
        assert {k: v for k, v in old.items() if k != "purpose"} == {k: v for k, v in new.items() if k != "purpose"}, old["addon"]
    migrated = {p["path"]: p for p in report["pages"]}
    sections = dated = links = 0
    for row in old_rows:
        name = row["note"]
        original = git("show", before + ":" + name)
        current = (ROOT / name).read_bytes()
        if name not in migrated:
            assert current == original, (name, "Unconfirmed note changed")
            continue
        item = migrated[name]
        assert hashlib.sha256(original).hexdigest() == item["before_sha256"]
        assert current.startswith(original.split(b"\n", 1)[0] + b"\n"), name
        assert original.startswith(b"\xef\xbb\xbf") == current.startswith(b"\xef\xbb\xbf"), name
        matches = list(re.finditer(rb"^## ([^\r\n]+)\r?\n", original, re.M))
        preamble = original[original.index(b"\n") + 1:matches[0].start()]
        assert preamble in current, (name, "Original preamble lost")
        bodies = []
        for i, match in enumerate(matches):
            block = original[match.start():matches[i + 1].start() if i + 1 < len(matches) else len(original)]
            body = block.split(b"\n", 1)[1]
            assert body in current, (name, match.group(1), "Original body bytes lost/converted")
            bodies.append(body)
            if not re.match(rb"\d{4}-\d{2}-\d{2}(?:[ :]|\xef\xbc\x9a|$)", match.group(1)):
                assert b"#" + block in current, (name, "Historical section changed")
            sections += 1
        assert len(matches) == item["retained_sections"]
        for moved in item["moved_records"]:
            assert any(hashlib.sha256(body).hexdigest() == moved["body_sha256"] for body in bodies)
            dated += 1
        pattern = rb"\[[^\]\r\n]*\]\(([^)\r\n]+)\)"
        old_links = Counter(re.findall(pattern, original))
        assert not old_links - Counter(re.findall(pattern, current)), (name, "Original evidence link lost")
        links += sum(old_links.values())
    protected = ["Interface/AddOns", "PluginHistory/Evidence", "PluginHistory/history-index.json",
                 "PluginHistory/addon-catalog.json", "PluginHistory/baseline-files.json",
                 "dlls.txt", "dxvk.conf", ":(glob)*.dll"]
    assert not git("diff", "--name-only", before, "--", *protected), "Protected plugin/evidence/runtime files changed"
    assert len(migrated) == report["reorganized_pages"] == 57
    assert dated == report["existing_dated_sections"] == 79
    assert sum(r["record_count"] for r in records) == report["dated_records_after"] == 81
    print(json.dumps({"ok": True, "source_commit": before, "reorganized_pages": len(migrated),
                      "untouched_pages": len(old_rows) - len(migrated), "original_sections_preserved": sections,
                      "dated_sections_preserved": dated, "dated_records_after": 81,
                      "original_links_preserved": links, "protected_paths_unchanged": True}, ensure_ascii=False))


if __name__ == "__main__":
    main()
