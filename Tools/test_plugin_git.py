"""Exercise scoped recording in a disposable repo, including an embedded repo."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import tempfile

import plugin_git as maintenance


def main():
    original_root = maintenance.ROOT
    parent = original_root / "PluginHistory/check-results"
    parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="plugin-git-test-", dir=parent) as temporary:
        root = Path(temporary).resolve()
        assert root.is_relative_to(parent.resolve())
        maintenance.ROOT = root
        try:
            maintenance.git("init", "--initial-branch=main", "--object-format=sha1")
            maintenance.git("config", "user.name", "Plugin History Test")
            maintenance.git("config", "user.email", "plugin-history-test@localhost")
            maintenance.git("config", "core.autocrlf", "false")
            (root / ".git/info/attributes").write_bytes((original_root / "Tools/git-info-attributes").read_bytes())
            addon = root / "Interface/AddOns/Fixture"
            addon.mkdir(parents=True)
            subprocess.run(["git", "-C", str(addon), "init", "--initial-branch=main"],
                           check=True, capture_output=True)
            (addon / ".gitignore").write_text("ignored.lua\n", encoding="utf-8")
            (addon / ".gitattributes").write_text("* text=auto\n", encoding="utf-8")
            (addon / "code.lua").write_bytes(b"\xef\xbb\xbflocal a = 1\r\nlocal b = 2\n")
            (addon / "delete.lua").write_bytes(b"local obsolete = true\r\n")
            maintenance.stage_paths(maintenance.source_paths())
            maintenance.git("-c", "commit.gpgSign=false", "commit", "-m", "fixture baseline")

            (addon / "code.lua").write_bytes(b"\xef\xbb\xbflocal a = 3\r\nlocal b = 2\n")
            (addon / "ignored.lua").write_bytes(b"local newly_added = true\r\n")
            (addon / "image.tga").write_bytes(bytes(range(256)))
            (addon / "delete.lua").unlink()
            with contextlib.redirect_stdout(io.StringIO()):
                assert maintenance.checkpoint(["Fixture"], [], "fixture modification") == 0
                assert maintenance.verify("HEAD") == 0
            assert maintenance.git("show", "HEAD:Interface/AddOns/Fixture/code.lua") == (addon / "code.lua").read_bytes()
            assert maintenance.git("show", "HEAD:Interface/AddOns/Fixture/image.tga") == bytes(range(256))
            assert b"delete.lua" not in maintenance.git("ls-files", "-z")
            assert b"ignored.lua" in maintenance.git("ls-files", "-z")
            assert b"160000" not in maintenance.git("ls-files", "--stage")
            assert all(".git" not in Path(name).parts for name in maintenance.source_paths())
            assert (addon / ".git/HEAD").is_file()

            before = maintenance.git("rev-parse", "HEAD")
            with contextlib.redirect_stdout(io.StringIO()):
                assert maintenance.checkpoint(["Fixture"], [], "must remain a no-op") == 0
            assert maintenance.git("rev-parse", "HEAD") == before

            (root / "unrelated.txt").write_text("another task", encoding="utf-8")
            maintenance.git("add", "--", "unrelated.txt")
            try:
                maintenance.checkpoint(["Fixture"], [], "must refuse unrelated staged files")
            except RuntimeError as error:
                assert "Staging area is not empty" in str(error)
            else:
                raise AssertionError("Checkpoint accepted unrelated staged changes")
            assert maintenance.git("rev-parse", "HEAD") == before
            assert maintenance.git("diff", "--cached", "--name-only").strip() == b"unrelated.txt"
        finally:
            maintenance.ROOT = original_root
    print(json.dumps({"ok": True, "checks": ["embedded repository actual files",
          "BOM and mixed line endings", "binary exact bytes", "ignored new file",
          "deleted file", "nested git metadata excluded and preserved",
          "no-op checkpoint", "unrelated staged changes rejected"]}, indent=2))


if __name__ == "__main__":
    main()
