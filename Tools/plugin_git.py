"""Local plugin history: status, scoped checkpoints, byte-for-byte verification."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def git(*args, data=None):
    result = subprocess.run(["git", "-C", str(ROOT), *args], input=data,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise RuntimeError(result.stderr.decode("utf-8", errors="replace").strip())
    return result.stdout


def source_paths():
    paths = {p.relative_to(ROOT).as_posix()
             for p in (ROOT / "Interface/AddOns").rglob("*") if p.is_file()}
    paths.update(p.name for p in ROOT.glob("*.dll") if p.is_file())
    paths.update(name for name in ("dlls.txt", "dxvk.conf") if (ROOT / name).is_file())
    return paths


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


def checkpoint(addons, runtime, message):
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
    if not scopes:
        raise RuntimeError("Specify --addon or --runtime; no unscoped commits.")
    git("add", "--all", "--force", "--", *[":(literal)" + s for s in scopes])
    if not git("diff", "--cached", "--name-only", "-z"):
        print("No changes in the selected plugins.")
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
    save.add_argument("--message", required=True)
    args = parser.parse_args()
    if args.command == "status":
        print(git("-c", "core.quotepath=false", "status", "--short", "--branch").decode("utf-8"), end="")
        return 0
    if args.command == "verify":
        return verify(args.ref)
    return checkpoint(args.addon, args.runtime, args.message)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(2)
