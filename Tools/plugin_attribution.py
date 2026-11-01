"""Add/check personal-edition maintenance credits without rewriting source bytes.

Only TOC metadata is edited. Existing authors, license fields, file loading order,
encoding, BOM, and each original line terminator are retained. Unknown historical
authorship is not converted into an authorship claim by this maintenance credit.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from hashlib import sha256
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MAINTAINERS = b"StoneChyi & Codex"
SCOPE = b"Personal modifications; original authors and licenses retained"
VISIBLE = b"Personal edition: " + MAINTAINERS
NOTES_SUFFIX = b" | " + VISIBLE
KEYS = {b"X-Maintained-By": MAINTAINERS, b"X-Maintenance-Scope": SCOPE}
NOTE = re.compile(br"^(?:\xef\xbb\xbf)?##[ \t]*Notes(?:-[A-Za-z]{4})?[ \t]*:", re.I)
META = re.compile(br"^(?:\xef\xbb\xbf)?##[ \t]*([^:\r\n]+):[ \t]*(.*)$")


@dataclass
class Change:
    before: bytes
    after: bytes
    notes_updated: int
    notes_added: bool


def content_and_ending(line: bytes) -> tuple[bytes, bytes]:
    if line.endswith(b"\r\n"):
        return line[:-2], b"\r\n"
    if line.endswith(b"\n") or line.endswith(b"\r"):
        return line[:-1], line[-1:]
    return line, b""


def annotate_bytes(before: bytes) -> Change:
    """Return an additive metadata edit; never transcode an original line."""
    if before.startswith((b"\xff\xfe", b"\xfe\xff")) or b"\0" in before:
        raise ValueError("UTF-16/NUL-containing TOC needs explicit review; no bytes changed")
    lines = before.splitlines(keepends=True)
    endings = [content_and_ending(line)[1] for line in lines]
    populated = [ending for ending in endings if ending]
    # A stable tie break matters for mixed-ending TOCs across Python processes.
    newline = max(populated, key=populated.count) if populated else b"\n"
    found = {}
    notes = 0
    changed_notes = 0
    edited = []
    for line in lines:
        value, ending = content_and_ending(line)
        match = META.match(value)
        if match:
            key = next((k for k in KEYS if k.lower() == match[1].strip().lower()), None)
            if key:
                if key in found:
                    raise ValueError("Duplicate maintenance metadata field")
                found[key] = match[2].strip()
                if found[key] != KEYS[key]:
                    raise ValueError("Existing maintenance credit differs; review it without replacing its owner")
        if NOTE.match(value):
            notes += 1
            if VISIBLE not in value:
                value += NOTES_SUFFIX
                changed_notes += 1
        edited.append(value + ending)
    addition = b"".join(b"## " + key + b": " + value + newline
                        for key, value in KEYS.items() if key not in found)
    notes_added = not notes
    if notes_added:
        addition += b"## Notes: " + VISIBLE + newline
    # Insert after the first complete metadata line, normally the Interface field.
    # Keep introductory comments adjacent to the original line they describe.
    # In particular, keep a terminal line without newline terminal and unchanged.
    if addition:
        insertion = next((i + 1 for i, line in enumerate(edited)
                          if endings[i] and META.match(content_and_ending(line)[0])), None)
        if insertion is not None:
            after = b"".join(edited[:insertion]) + addition + b"".join(edited[insertion:])
        else:
            bom = b"\xef\xbb\xbf" if before.startswith(b"\xef\xbb\xbf") else b""
            raw = b"".join(edited)
            after = bom + addition + raw[len(bom):]
    else:
        after = b"".join(edited)
    return Change(before, after, changed_notes, notes_added)


def catalog(root: Path = ROOT):
    data = json.loads((root / "PluginHistory/maintenance-index.json").read_bytes())
    return data["addons"] + data.get("added_addons", [])


def targets(root: Path = ROOT, addons=(), exclude=()):
    requested = set(addons)
    rows = catalog(root)
    known = {row["addon"] for row in rows}
    unknown = requested - known
    if unknown:
        raise ValueError("Add/update maintenance-index before attributing unknown plugins: " + ", ".join(sorted(unknown)))
    result = []
    absent = []
    for row in rows:
        addon = row["addon"]
        if addon in exclude or (requested and addon not in requested):
            continue
        if not requested and row.get("history_group") != "modified":
            continue
        if row.get("history_group") != "modified":
            raise ValueError("No recorded plugin modification/edition maintenance scope: " + addon)
        directory = root / "Interface/AddOns" / addon
        if not directory.is_dir():
            absent.append(addon)
            continue
        tocs = sorted(directory.glob("*.toc"), key=lambda p: p.name.lower())
        if not tocs:
            raise ValueError("No root TOC for existing plugin: " + addon)
        for toc in tocs:
            result.append((row, toc))
    return result, absent


def run(command, root: Path = ROOT, addons=(), exclude=(), report=None):
    output = root / report if report else None
    if output and not output.resolve().is_relative_to((root / "PluginHistory/Research").resolve()):
        raise ValueError("Attribution report must be under PluginHistory/Research")
    if output and output.exists():
        raise ValueError("Keep existing attribution evidence; choose a new report path")
    selected, absent = targets(root, addons, exclude)
    changes = []
    # Prepare/validate every target before writing any file.
    for row, toc in selected:
        change = annotate_bytes(toc.read_bytes())
        changes.append((row, toc, change))
    changed = [(row, toc, change) for row, toc, change in changes if change.before != change.after]
    if command == "apply":
        for row, toc, change in changed:
            toc.write_bytes(change.after)
    result = {
        "maintainers": MAINTAINERS.decode(),
        "scope": SCOPE.decode(),
        "selected_addons": sorted({row["addon"] for row, _, _ in changes}, key=str.lower),
        "selected_tocs": len(changes),
        "absent_not_recreated": absent,
        "excluded": list(exclude),
        "changed_tocs": len(changed),
        "files": [{"addon": row["addon"], "path": toc.relative_to(root).as_posix(),
                   "historical_evidence_status": row["status"],
                   "before_sha256": sha256(change.before).hexdigest(),
                   "after_sha256": sha256(change.after).hexdigest(),
                   "notes_appended": change.notes_updated,
                   "notes_added": change.notes_added}
                  for row, toc, change in changed],
    }
    if output:
        output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({k: v for k, v in result.items() if k not in {"files", "selected_addons"}}, ensure_ascii=False))
    if command == "check" and changed:
        for _, toc, _ in changed:
            print("Missing/incomplete credit: " + toc.relative_to(root).as_posix())
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("plan", "apply", "check"))
    parser.add_argument("--addon", action="append", default=[])
    parser.add_argument("--exclude", action="append", default=[])
    parser.add_argument("--report")
    args = parser.parse_args()
    return run(args.command, addons=args.addon, exclude=args.exclude, report=args.report)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(2)
