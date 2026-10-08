"""Validate addon-note coverage, evidence paths and local Markdown links.

Read-only. Historical source paths are checked against the explicit reference
commit, so another task's uncommitted addon deletion is not mistaken for lost
historical evidence. Does not validate addon behavior or infer authorship.
"""
from collections import Counter
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
STATUSES = {
    "documented_history": "有维护记录",
    "snapshot_difference": "有备份差异，来源待确认",
    "related_skin_only": "仅确认关联皮肤适配",
    "unconfirmed": "尚未确认个人修改",
}


def main():
    index_path = ROOT / "PluginHistory/maintenance-index.json"
    index = json.loads(index_path.read_text(encoding="utf-8"))
    reference = index["reference_commit"]
    raw = subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-tree", "-r", "--name-only", "-z", reference]
    )
    tracked = set(raw.decode("utf-8").split("\0")) - {""}
    expected = {
        p.split("/")[2] for p in tracked if p.startswith("Interface/AddOns/")
    }
    rows = index["addons"]
    names = [r["addon"] for r in rows]
    assert len(names) == len(set(names)), "Duplicate addon names"
    assert set(names) == expected, "Reference addons and notes differ"
    assert dict(Counter(r["status"] for r in rows)) == index["counts"]
    notes_root = ROOT / "PluginHistory/Plugins"
    expected_notes = {r["addon"] + ".md" for r in rows} | {"README.md"}
    assert {p.name for p in notes_root.glob("*.md")} == expected_notes

    def historical_path_exists(path):
        return path in tracked or any(p.startswith(path.rstrip("/") + "/") for p in tracked)

    files = [ROOT / r["note"] for r in rows] + [
        notes_root / "README.md",
        ROOT / "PluginHistory/待补充清单.md",
        ROOT / "PluginHistory/README.md",
        ROOT / "README.md",
    ]
    evidence_count = 0
    for row in rows:
        name = row["addon"]
        assert row["note"] == "PluginHistory/Plugins/" + name + ".md"
        text = (ROOT / row["note"]).read_text(encoding="utf-8")
        assert text.startswith("# " + name + " 修改说明\n")
        assert "**" + STATUSES[row["status"]] + "**" in text
        assert "## 待补充" in text and "## 依据" in text
        actual_count = sum(p.startswith("Interface/AddOns/" + name + "/") for p in tracked)
        assert row["tracked_files_at_reference"] == actual_count
        for source in row["sources"]:
            assert historical_path_exists(source) or (
                source.startswith("PluginHistory/Research/") and (ROOT / source).is_file()
            ), (name, source)
            evidence_count += 1
        for path in row["maintenance_files"]:
            assert path.startswith("Interface/AddOns/" + name + "/") and path in tracked, path

    links = 0
    for path in files:
        text = path.read_text(encoding="utf-8-sig")
        assert "\ufffd" not in text, "Replacement character in " + str(path)
        for target in re.findall(r"\[[^\]\n]*\]\(([^)\n]+)\)", text):
            target = target.strip().strip("<>")
            parsed = urlsplit(target)
            if parsed.scheme or target.startswith("#"):
                # Explicit historical GitHub links must refer to tracked paths.
                prefix = "/StoneChyi/wow-1.18-addon-maintenance/"
                if parsed.netloc == "github.com" and parsed.path.startswith(prefix):
                    parts = unquote(parsed.path[len(prefix):]).split("/", 2)
                    if len(parts) == 3 and parts[0] in {"blob", "tree"}:
                        assert parts[1] == reference and historical_path_exists(parts[2])
                continue
            resolved = (path.parent / unquote(parsed.path)).resolve()
            assert resolved.is_relative_to(ROOT), (path, target, "outside repository")
            relative = resolved.relative_to(ROOT).as_posix()
            assert resolved.exists() or historical_path_exists(relative), (path, target)
            links += 1
    print(json.dumps({
        "ok": True,
        "reference_commit": reference,
        "addon_notes": len(rows),
        "counts": index["counts"],
        "markdown_files_checked": len(files),
        "local_links_checked": links,
        "evidence_entries_checked": evidence_count,
        "scope": "documentation only; no addon behavior tested",
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
