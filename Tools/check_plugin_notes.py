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


def validate_addon_sets(index, expected):
    """Keep the frozen reference catalog distinct from plugins created later."""
    rows = index["addons"]
    added = index.get("added_addons", [])
    names = [row["addon"] for row in rows]
    new_names = [row["addon"] for row in added]
    assert len(names) == len(set(names)), "Duplicate reference addon names"
    assert set(names) == expected, "Reference addons and notes differ"
    assert dict(Counter(row["status"] for row in rows)) == index["counts"]
    assert len(new_names) == len(set(new_names)), "Duplicate added addon names"
    assert not set(new_names) & expected, "Existing addon cannot be recast as newly added"
    assert dict(Counter(row["status"] for row in added)) == index.get("added_counts", {})
    for row in added:
        assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", row["added_on"]), "Missing actual addition date"
        assert re.fullmatch(r"[0-9a-f]{40}", row["creation_base_commit"]), "Missing creation base"
        assert row["tracked_files_at_reference"] == 0, "New addon existed at reference"
        assert row["status"] in STATUSES, "Unknown added status"
        assert row["addon"] not in {".", ".."} and not re.search(r"[/\\]", row["addon"])
    return rows, added


def main():
    index_path = ROOT / "PluginHistory/maintenance-index.json"
    index = json.loads(index_path.read_text(encoding="utf-8"))
    reference = index["reference_commit"]
    raw = subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-tree", "-r", "--name-only", "-z", reference]
    )
    tracked = set(raw.decode("utf-8").split("\0")) - {""}
    # Later maintenance can add a module/test to an existing addon. Keep the frozen
    # reference for historical counts, but validate new entries against scoped Git files.
    current_tracked = set(subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-files", "-z"]
    ).decode("utf-8").split("\0")) - {""}

    def current_path_exists(path):
        resolved = (ROOT / path).resolve()
        return path in current_tracked and resolved.is_relative_to(ROOT) and resolved.is_file()
    expected = {
        p.split("/")[2] for p in tracked if p.startswith("Interface/AddOns/")
    }
    rows, added = validate_addon_sets(index, expected)
    runtime = index.get("runtime_components", [])
    runtime_names = {row["addon"] for row in runtime}
    assert len(runtime_names) == len(runtime), "Duplicate runtime components"
    assert not runtime_names & {row["addon"] for row in rows + added}, "Runtime/addon names overlap"
    all_rows = rows + added + runtime
    added_names = {row["addon"] for row in added}
    notes_root = ROOT / "PluginHistory/Plugins"
    expected_notes = {r["addon"] + ".md" for r in all_rows} | {"README.md"}
    assert {p.name for p in notes_root.glob("*.md")} == expected_notes

    def historical_path_exists(path):
        return path in tracked or any(p.startswith(path.rstrip("/") + "/") for p in tracked)

    files = [ROOT / r["note"] for r in all_rows] + [
        notes_root / "README.md",
        ROOT / "PluginHistory/待补充清单.md",
        ROOT / "PluginHistory/README.md",
        ROOT / "PluginHistory/待确认插件.md",
        ROOT / "PluginHistory/记录规范.md",
        ROOT / "PluginHistory/记录模板.md",
        ROOT / "PluginHistory/GitHub同步说明.md",
        ROOT / "PluginHistory/Research/记录方式整理-20261015.md",
        ROOT / "README.md",
    ]
    evidence_count = 0
    for row in all_rows:
        name = row["addon"]
        assert row["note"] == "PluginHistory/Plugins/" + name + ".md"
        text = (ROOT / row["note"]).read_text(encoding="utf-8")
        assert text.startswith("# " + name + " 修改说明\n")
        assert "**" + STATUSES[row["status"]] + "**" in text
        assert "## 待补充" in text and "## 依据" in text
        actual_count = sum(p.startswith("Interface/AddOns/" + name + "/") for p in tracked)
        if name not in runtime_names:
            assert row["tracked_files_at_reference"] == actual_count
        for source in row["sources"]:
            assert historical_path_exists(source) or (
                source.startswith("PluginHistory/Research/") and (ROOT / source).is_file()
            ) or current_path_exists(source), (name, source)
            evidence_count += 1
        for path in row["maintenance_files"]:
            if name in runtime_names:
                part = Path(path)
                assert len(part.parts) == 1 and (part.suffix.lower() == ".dll" or path in {"dlls.txt", "dxvk.conf"}), path
                assert path in tracked or current_path_exists(path), path
                continue
            assert path.startswith("Interface/AddOns/" + name + "/"), path
            if name in added_names:
                resolved = (ROOT / path).resolve()
                assert resolved.is_relative_to(ROOT / "Interface/AddOns" / name) and resolved.is_file(), path
            else:
                assert path in tracked or current_path_exists(path), path

    links = 0
    for path in files:
        text = path.read_text(encoding="utf-8-sig")
        assert "\ufffd" not in text, "Replacement character in " + str(path)
        # Templates contain literal future-page links and placeholder paths;
        # fenced examples are not navigable Markdown links in this document.
        text = re.sub(r"^```[^\n]*\n.*?^```[^\n]*$", "", text, flags=re.M | re.S)
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
        "added_addon_notes": len(added),
        "added_counts": index.get("added_counts", {}),
        "runtime_component_notes": len(runtime),
        "markdown_files_checked": len(files),
        "local_links_checked": links,
        "evidence_entries_checked": evidence_count,
        "scope": "documentation only; no addon behavior tested",
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
