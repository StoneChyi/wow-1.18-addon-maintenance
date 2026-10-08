"""One-time import of existing local plugin evidence; never edits live addons."""
from collections import defaultdict
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import sys
from zoneinfo import ZoneInfo
from plugin_git import walk_files

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "PluginHistory"
LEGACY = Path("E:/WoW-PluginBackups/20261005-06_latest_20261006_100744")
SKIP = {".git", "node_modules", "__pycache__", "deps", "test-deps",
        "analysis-deps", "chatcopy-test-deps", "bcs-test-runtime"}
EXTENSIONS = {".lua", ".xml", ".toc", ".md", ".txt", ".json", ".py",
              ".original", ".before", ".patch", ".diff", ".zip", ".ini",
              ".tga", ".blp", ".dll"}


def save_json(name, data):
    (DEST / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    refresh = sys.argv[1:] == ["--refresh-current"]
    if (DEST / "Evidence").exists() and not refresh:
        raise RuntimeError("Evidence already exists; refusing to overwrite the initial import.")
    legacy_meta = json.loads((LEGACY / "Manifest/baselines.json").read_text(encoding="utf-8-sig"))
    for name, item in legacy_meta["selected"].items():
        if digest((LEGACY / item["path"]).read_bytes()) != item["sha256"]:
            raise RuntimeError("Historical baseline hash mismatch: " + name)
    rows = []

    def copy(source, relative):
        content = source.read_bytes()
        target = DEST / "Evidence" / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            if not refresh or target.read_bytes() != content:
                raise RuntimeError("Existing evidence differs: " + str(target))
        else:
            target.write_bytes(content)
        if source.read_bytes() != content or target.read_bytes() != content:
            raise RuntimeError("File changed during import: " + str(source))
        rows.append({"path": target.relative_to(ROOT).as_posix(), "source": str(source),
                     "bytes": len(content), "sha256": digest(content)})

    for directory in ("Baseline", "Docs", "Manifest", "Patches"):
        for source in sorted((LEGACY / directory).rglob("*")):
            if source.is_file():
                copy(source, Path("legacy-20261006") / source.relative_to(LEGACY))
    copy(LEGACY / "README.md", Path("legacy-20261006/README.md"))

    for directory in ("addons_tmp", "CodexBackups", "CatBackups", "CodexReports"):
        origin = ROOT / directory
        for source in sorted(origin.rglob("*")):
            if not source.is_file():
                continue
            parts = source.relative_to(origin).parts
            if any(p in SKIP or p.endswith("-deps") or p.endswith(".dist-info") for p in parts):
                continue
            if source.suffix.lower() not in EXTENSIONS:
                continue
            # Keep actual backup directories and maintenance scripts/reports,
            # excluding extracted game databases and inspection research caches.
            if directory == "addons_tmp" and len(parts) > 1 and "backup" not in parts[0]:
                continue
            prefix = "reports" if directory == "CodexReports" else directory
            copy(source, Path(prefix) / source.relative_to(origin))

    timestamp = datetime.now(ZoneInfo("Asia/Shanghai")).isoformat(timespec="seconds")
    baseline = []
    addon_files = defaultdict(list)
    for source in sorted(walk_files(ROOT / "Interface/AddOns")):
        if source.is_file():
            content = source.read_bytes()
            name = source.relative_to(ROOT).as_posix()
            item = {"path": name, "bytes": len(content), "sha256": digest(content)}
            baseline.append(item)
            addon_files[source.relative_to(ROOT / "Interface/AddOns").parts[0]].append(item)
    runtime = sorted(ROOT.glob("*.dll")) + [ROOT / "dlls.txt", ROOT / "dxvk.conf"]
    for source in runtime:
        if source.is_file():
            content = source.read_bytes()
            baseline.append({"path": source.name, "bytes": len(content), "sha256": digest(content)})

    documented = {name.split("/")[0] for name in legacy_meta["selected"]}
    documented.update(name.split("/")[0] for name in legacy_meta["absentBefore"])
    recent = {
        "CatPotion": ["addons_tmp/catpotion", "reports/CatPotion"],
        "SimpleRaidTargetIcons": ["addons_tmp/srti", "reports/SimpleRaidTargetIcons"],
        "pfUI": ["CodexBackups/pfUI", "addons_tmp/distanceindicator", "addons_tmp/action-monitor"],
        "WIM": ["CodexBackups/WIM"], "diminfo": ["CodexBackups/diminfo"],
        "hyx": ["CodexBackups/hyx", "reports/hyx"],
    }
    catalog = []
    for addon, files in sorted(addon_files.items()):
        references = []
        if addon in documented:
            references.append("PluginHistory/Evidence/legacy-20261006/Manifest/baselines.json")
        for row in rows:
            suffix = row["path"].removeprefix("PluginHistory/Evidence/")
            if any(suffix.startswith(prefix) for prefix in recent.get(addon, [])):
                references.append(row["path"])
        inline = [f["path"] for f in files if re.search(r"\.(bak|before|original)$", f["path"], re.I)]
        catalog.append({"addon": addon, "tracking": "complete_current_snapshot",
                        "files": len(files), "bytes": sum(f["bytes"] for f in files),
                        "documented_modification_evidence": bool(references),
                        "evidence": sorted(set(references)), "inline_backup_files": inline,
                        "upstream_status": "no_verified_complete_pristine_package"})
    save_json("baseline-files.json", {"captured_at": timestamp,
              "kind": "current_personal_version_not_pristine_upstream", "files": baseline})
    save_json("history-index.json", {"imported_at": timestamp,
              "note": "Existing stage evidence, not reconstructed chronological Git commits; account settings excluded.",
              "verified_legacy_before_files": len(legacy_meta["selected"]), "files": rows})
    save_json("addon-catalog.json", {"captured_at": timestamp, "addons": catalog})
    print(json.dumps({"addons": len(catalog), "addon_files": sum(len(f) for f in addon_files.values()),
                      "source_files_including_runtime": len(baseline), "evidence_files": len(rows),
                      "evidence_bytes": sum(r["bytes"] for r in rows),
                      "documented_addons": sum(a["documented_modification_evidence"] for a in catalog),
                      "verified_legacy_before_files": len(legacy_meta["selected"])}, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
