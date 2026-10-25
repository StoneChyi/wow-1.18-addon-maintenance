"""Run existing personal regressions against an isolated candidate addon tree.

Only production addon file reads are redirected. Test fixtures, strict font
contracts and Git baseline reads retain their original sources.
"""
from pathlib import Path
import argparse
import runpy
import sys

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--addons', type=Path, required=True)
parser.add_argument('tests', nargs='+')
args = parser.parse_args()
candidate = args.addons.resolve()
production = (ROOT / 'Interface/AddOns').resolve()
read_text, read_bytes = Path.read_text, Path.read_bytes


def redirect(path):
    try:
        rel = path.resolve().relative_to(production)
    except ValueError:
        return path
    if rel.parts and (candidate / rel.parts[0]).is_dir():
        return candidate / rel
    return path


Path.read_text = lambda path, *a, **k: read_text(redirect(path), *a, **k)
Path.read_bytes = lambda path, *a, **k: read_bytes(redirect(path), *a, **k)
try:
    for test in args.tests:
        target = (ROOT / 'Tools/tests' / test).resolve()
        assert target.parent == ROOT / 'Tools/tests' and target.is_file()
        sys.argv = [str(target)]
        print('RUN', test, flush=True)
        runpy.run_path(str(target), run_name='__main__')
finally:
    Path.read_text, Path.read_bytes = read_text, read_bytes
