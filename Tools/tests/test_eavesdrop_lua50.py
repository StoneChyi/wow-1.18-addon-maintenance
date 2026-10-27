"""Compile the actual EavesDrop load chain with a real Lua 5.0 compiler.

Install LuaBinaries 5.0.3 separately in the ignored staging directory, or set
LUA50_COMPILER to an absolute luac50.exe path. The binary is not distributed
with the addon. This checks Lua syntax, not WoW's APIs or game behavior.
"""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / "Interface/AddOns/EavesDrop"
DEFAULT = ROOT / "PluginHistory/staging/lua503-validation/win64/luac50.exe"
COMPILER = Path(os.environ.get("LUA50_COMPILER", str(DEFAULT))).resolve()


def compile_bytes(path, directory):
    data = path.read_bytes()
    # Blizzard loads the existing UTF-8 BOM; stock Lua 5.0 rejects that marker.
    # Strip it only in the isolated compiler input, never in the real file.
    if data.startswith(b"\xef\xbb\xbf"):
        path = directory / "existing-bom-stripped.lua"
        path.write_bytes(data[3:])
    return subprocess.run([str(COMPILER), "-p", str(path)], cwd=COMPILER.parent,
                          capture_output=True, text=True, errors="replace")


def main():
    if not COMPILER.is_file():
        raise SystemExit("Lua 5.0 compiler not found; set LUA50_COMPILER to luac50.exe")
    with tempfile.TemporaryDirectory(prefix="eavesdrop-lua50-") as folder:
        temporary = Path(folder)
        probe = temporary / "lua51-only.lua"
        probe.write_text("return 1 % 2\n", encoding="ascii")
        rejected = compile_bytes(probe, temporary)
        if rejected.returncode == 0:
            raise SystemExit("Compiler accepted Lua 5.1 modulo syntax; expected Lua 5.0")
        toc = (ADDON / "EavesDrop.toc").read_text(encoding="utf-8-sig")
        listed = [ADDON / line.strip().replace("\\", "/") for line in toc.splitlines()
                  if line.strip() and not line.startswith("#") and line.lower().endswith(".lua")]
        paths = sorted(set(list(ADDON.glob("*.lua")) + listed))
        for path in paths:
            result = compile_bytes(path, temporary)
            if result.returncode:
                raise SystemExit(f"Lua 5.0 failed: {path.relative_to(ADDON)}\n{result.stderr}")
        print(f"Lua 5.0 rejects 5.1-only modulo and compiles {len(paths)} EavesDrop Lua files; game verification required.")


if __name__ == "__main__":
    main()
