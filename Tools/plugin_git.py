"""Local plugin history: status, scoped checkpoints, byte-for-byte verification."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def git(*args, data=None):
    result = subprocess.run(["git", "-C", str(ROOT), *args], input=data,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise RuntimeError(result.stderr.decode("utf-8", errors="replace").strip())
    return result.stdout


def walk_files(directory):
    for folder, directories, files in os.walk(directory):
        directories[:] = [name for name in directories if name != ".git"]
        for name in files:
            if name != ".git":
                yield Path(folder) / name


def source_paths():
    paths = {p.relative_to(ROOT).as_posix()
             for p in walk_files(ROOT / "Interface/AddOns") if p.is_file()}
    paths.update(p.name for p in ROOT.glob("*.dll") if p.is_file())
    paths.update(name for name in ("dlls.txt", "dxvk.conf") if (ROOT / name).is_file())
    return paths


def stage_paths(paths):
    """Store raw files even when a parent directory is an embedded repository."""
    modes = {}
    for entry in git("ls-files", "--stage", "-z").split(b"\0"):
        if entry:
            meta, name = entry.split(b"\t", 1)
            mode, oid, stage = meta.split()
            modes[name.decode("utf-8")] = mode
    existing = sorted(p for p in paths if (ROOT / p).is_file())
    missing = sorted(p for p in paths if not (ROOT / p).is_file() and p in modes)
    records = [b"0 " + b"0" * 40 + b"\t" + p.encode("utf-8") + b"\0" for p in missing]
    # Remove gitlinks before inserting their individual child files.
    if records:
        git("update-index", "-z", "--index-info", data=b"".join(records))
    for start in range(0, len(existing), 100):
        batch = existing[start:start + 100]
        objects = git("hash-object", "-w", "--no-filters", "--", *batch).splitlines()
        if len(objects) != len(batch):
            raise RuntimeError("Unexpected number of stored blobs.")
        records = []
        for name, oid in zip(batch, objects):
            mode = modes.get(name, b"100644")
            if mode not in {b"100644", b"100755"}:
                mode = b"100644"
            records.append(mode + b" " + oid + b"\t" + name.encode("utf-8") + b"\0")
        git("update-index", "-z", "--index-info", data=b"".join(records))


def verify(ref):
    tree = {}
    for entry in git("ls-tree", "-rz", "--full-tree", ref).split(b"\0"):
        if not entry:
            continue
        meta, path = entry.split(b"\t", 1)
        mode, kind, oid = meta.split()
        if kind != b"blob":
            raise RuntimeError("Unexpected submodule/tree: " + path.decode("utf-8"))
        tree[path.decode("utf-8")] = oid.decode("ascii")
    failures = []
    for name, oid in tree.items():
        path = ROOT / name
        if not path.is_file():
            failures.append({"path": name, "status": "missing"})
            continue
        content = path.read_bytes()
        actual = hashlib.sha1(b"blob " + str(len(content)).encode("ascii") + b"\0" + content).hexdigest()
        if actual != oid:
            failures.append({"path": name, "status": "modified"})
    for name in sorted(source_paths() - tree.keys()):
        failures.append({"path": name, "status": "unrecorded_plugin_file"})
    print(json.dumps({"ref": ref, "checked_files": len(tree),
                      "ok": not failures, "differences": failures}, ensure_ascii=False, indent=2))
    return 1 if failures else 0


def note_path(name):
    """Accept explicit maintenance documents, never archived evidence/settings."""
    path = PurePosixPath(name)
    if ("\\" in name or ":" in name or path.is_absolute() or
            ".." in path.parts or any(p.lower() == ".git" for p in path.parts) or "." in name.split("/") or
            len(path.parts) < 2 or path.parts[0] != "PluginHistory" or
            path.suffix not in {".md", ".json"} or
            (len(path.parts) > 2 and path.parts[1] not in {"Plugins", "Research"}) or
            (len(path.parts) == 2 and path.suffix == ".json" and
             path.name not in {"maintenance-index.json", "change-index.json"})):
        raise RuntimeError("Use an explicit PluginHistory maintenance .md/.json path; archived evidence is excluded.")
    resolved = (ROOT / name).resolve()
    if not resolved.is_relative_to((ROOT / "PluginHistory").resolve()):
        raise RuntimeError("Maintenance note resolves outside PluginHistory.")
    if len(path.parts) > 2 and not resolved.is_relative_to((ROOT / "PluginHistory" / path.parts[1]).resolve()):
        raise RuntimeError("Maintenance note resolves outside its document category.")
    if not resolved.is_file() and not git("ls-files", "-z", "--", ":(literal)" + name):
        raise RuntimeError("Unknown maintenance note: " + name)
    return path.as_posix()


def checkpoint(addons, runtime, message, notes=()):
    if git("diff", "--cached", "--name-only", "-z"):
        raise RuntimeError("Staging area is not empty; review it before recording this task.")
    scopes = []
    for addon in addons:
        if addon in {".", ".."} or any(c in addon for c in "/\\\0"):
            raise RuntimeError("Use a single addon directory name.")
        scope = "Interface/AddOns/" + addon
        known = git("ls-files", "-z", "--", ":(literal)" + scope)
        if not (ROOT / scope).is_dir() and not known:
            raise RuntimeError("Unknown addon: " + addon)
        scopes.append(scope)
    for name in runtime:
        if Path(name).name != name or not (name.lower().endswith(".dll") or name in {"dlls.txt", "dxvk.conf"}):
            raise RuntimeError("Runtime scope must be a root DLL, dlls.txt or dxvk.conf.")
        if not (ROOT / name).is_file() and not git("ls-files", "-z", "--", ":(literal)" + name):
            raise RuntimeError("Unknown runtime file: " + name)
        scopes.append(name)
    # Validate every document before staging anything. This permits a single
    # atomic implementation + notes commit while retaining the empty-index guard.
    scopes.extend(note_path(name) for name in notes)
    if not scopes:
        raise RuntimeError("Specify --addon, --runtime or --note; no unscoped commits.")
    # Explicit file paths flatten embedded repositories without touching their
    # private .git data. Directory-based git add would store only gitlinks.
    paths = set()
    for scope in scopes:
        paths.update(p.decode("utf-8") for p in
                     git("ls-files", "-z", "--", ":(literal)" + scope).split(b"\0") if p)
        directory = ROOT / scope
        if directory.is_dir():
            paths.update(p.relative_to(ROOT).as_posix() for p in walk_files(directory) if p.is_file())
        elif directory.is_file():
            paths.add(scope)
    stage_paths(paths)
    if not git("diff", "--cached", "--name-only", "-z"):
        print("No changes in the selected plugins, runtime files or maintenance notes.")
        return 0
    # Commit messages should include purpose and actual validation results.
    git("-c", "commit.gpgSign=false", "commit", "-m", message)
    print(git("log", "-1", "--format=%h %s").decode("utf-8").strip())
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status")
    check = commands.add_parser("verify")
    check.add_argument("--ref", default="HEAD")
    save = commands.add_parser("checkpoint")
    save.add_argument("--addon", action="append", default=[])
    save.add_argument("--runtime", action="append", default=[])
    save.add_argument("--note", action="append", default=[],
                      help="Explicit PluginHistory maintenance document; repeat for reviewed indexes/reports.")
    save.add_argument("--message", required=True)
    args = parser.parse_args()
    if args.command == "status":
        print(git("-c", "core.quotepath=false", "status", "--short", "--branch").decode("utf-8"), end="")
        return 0
    if args.command == "verify":
        return verify(args.ref)
    return checkpoint(args.addon, args.runtime, args.message, args.note)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(2)
