"""Check reachable Git history and ZIP contents without displaying secret values."""
from pathlib import PurePosixPath
import io
import json
import re
import subprocess
import zipfile

from plugin_git import ROOT, git

PATTERNS = {
    "github_token": re.compile(rb"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})"),
    "aws_access_key": re.compile(rb"(?:AKIA|ASIA)[A-Z0-9]{16}"),
    "private_key": re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
}
BLOCKED_ROOTS = {"WTF", "Imports", "Logs", "Cache", "Data", "Screenshots", "WDB", "Errors"}


def main():
    names = {}
    for row in git("rev-list", "--objects", "--all").splitlines():
        oid, _, name = row.partition(b" ")
        names[oid] = name.decode("utf-8", errors="replace")
    metadata = git("cat-file", "--batch-check", data=b"\n".join(names) + b"\n")
    blobs = []
    findings = []
    for row in metadata.splitlines():
        oid, kind, length = row.split()
        if kind != b"blob":
            continue
        name = names[oid]
        if int(length) >= 100 * 1024 * 1024:
            findings.append({"path": name, "reason": "github_file_size_limit"})
        path = PurePosixPath(name)
        if path.parts and (path.parts[0] in BLOCKED_ROOTS or ".git" in path.parts):
            findings.append({"path": name, "reason": "excluded_directory_in_history"})
        if path.name.lower() in {"logins.txt", ".env", "id_rsa", "id_ed25519", "credentials"}:
            findings.append({"path": name, "reason": "credential_filename"})
        blobs.append((oid, int(length), name))

    def inspect(content, name):
        for label, pattern in PATTERNS.items():
            if pattern.search(content):
                findings.append({"path": name, "reason": label})

    process = subprocess.Popen(["git", "-C", str(ROOT), "cat-file", "--batch"],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    archives = 0
    try:
        for oid, length, name in blobs:
            process.stdin.write(oid + b"\n")
            process.stdin.flush()
            header = process.stdout.readline().split()
            if len(header) != 3 or int(header[2]) != length:
                raise RuntimeError("Unexpected Git object response")
            content = process.stdout.read(length)
            if len(content) != length or process.stdout.read(1) != b"\n":
                raise RuntimeError("Incomplete Git blob")
            inspect(content, name)
            if name.lower().endswith(".zip") and zipfile.is_zipfile(io.BytesIO(content)):
                with zipfile.ZipFile(io.BytesIO(content)) as archive:
                    for entry in archive.infolist():
                        if not entry.is_dir():
                            archives += 1
                            inspect(archive.read(entry), name + "!" + entry.filename)
    finally:
        process.stdin.close()
        process.wait()
    unique = sorted({(f["path"], f["reason"]) for f in findings})
    print(json.dumps({"ok": not unique, "reachable_blobs_checked": len(blobs),
                      "zip_entries_checked": archives,
                      "note": "Checks known token/private-key patterns, file paths and file-size limits; not a guarantee that all sensitive data is absent.",
                      "findings": [{"path": p, "reason": r} for p, r in unique]}, ensure_ascii=False, indent=2))
    return 1 if unique else 0


if __name__ == "__main__":
    raise SystemExit(main())
