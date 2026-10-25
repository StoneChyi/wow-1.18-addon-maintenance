"""Prepare isolated, pinned baseline and PSS sources. Never writes game files."""
import argparse
import difflib
import hashlib
import json
import re
from pathlib import Path
import shutil
import zipfile

HERE = Path(__file__).resolve().parent
SOURCE_COMMIT = '2c7f51cd436e9b0ce88271e84ce5a77c19f2c23b'
SOURCE_SHA256 = '64ff24035fb4ac7f6b0a3a9d0365f33e13993e1a4d740ea3697e0d1285f7d42f'
HADESMEM_SHA256 = '9abe86dde0ab59f6b5feecb0444848b280d61980523d7fed9700755162ba7728'


def checked_archive(path, expected):
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual != expected:
        raise ValueError('Pinned archive hash mismatch: ' + str(path))
    return zipfile.ZipFile(path)


def extract(archive, destination):
    for entry in archive.infolist():
        relative = Path(entry.filename)
        target = (destination / relative).resolve()
        if relative.is_absolute() or not target.is_relative_to(destination.resolve()):
            raise ValueError('Unsafe archive member: ' + entry.filename)
        if entry.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(entry))


def replace_once(path, old, new):
    data = path.read_bytes()
    newline = b'\r\n' if b'\r\n' in data else b'\n'
    old_bytes = old.replace('\r\n', '\n').replace('\n', newline.decode()).encode()
    new_bytes = new.replace('\r\n', '\n').replace('\n', newline.decode()).encode()
    if data.count(old_bytes) != 1:
        raise ValueError('Source anchor missing/non-unique: ' + old[:80])
    path.write_bytes(data.replace(old_bytes, new_bytes, 1))


SUMMARY = '''        startup_profile.Finish();
        for (std::size_t index = 0; index < startup_profile.Size(); ++index) {
            auto const& record = startup_profile.Record(index);
            DEBUG_LOG("[MaintenanceHook] offset=0x" << std::hex << record.offset << std::dec
                << " attempts=" << record.attempts << " success=" << record.success
                << " ms=" << nampower_maintenance::StartupMilliseconds(record.ticks)
                << " verify_ms=" << nampower_maintenance::StartupMilliseconds(record.delta.verify_ticks)
                << " enum_ms=" << nampower_maintenance::StartupMilliseconds(record.delta.enum_ticks)
                << " enum_samples=" << record.delta.enum_samples
                << " checks=" << record.delta.thread_checks
                << " pss_calls=" << record.delta.pss_calls
                << " fallback_calls=" << record.delta.fallback_calls);
        }
        auto const& totals = startup_profile.counters;
        DEBUG_LOG("[MaintenanceSummary] pss_enabled=" << NAMP_MAINT_USE_PSS
            << " init_ms=" << nampower_maintenance::StartupMilliseconds(startup_profile.Ticks())
            << " verify_ms=" << nampower_maintenance::StartupMilliseconds(totals.verify_ticks)
            << " enum_ms=" << nampower_maintenance::StartupMilliseconds(totals.enum_ticks)
            << " enum_samples=" << totals.enum_samples
            << " checks=" << totals.thread_checks << " verify_calls=" << totals.verify_calls
            << " pss_calls=" << totals.pss_calls << " fallback_calls=" << totals.fallback_calls
            << " pss_entries=" << totals.pss_entries << " toolhelp_entries=" << totals.toolhelp_entries
            << " last_pss_error=" << totals.last_pss_error
            << " last_cleanup_error=" << totals.last_cleanup_error
            << " dropped_records=" << startup_profile.Dropped());
'''


def prepare(workspace, variant, generation):
    # Explicit output scope, and refuse overwrite instead of recursively deleting.
    workspace = workspace.resolve()
    if workspace.drive.upper() != 'E:':
        raise ValueError('Build workspace must remain on E:')
    if generation and not re.fullmatch('[a-z0-9-]{1,32}',generation):
        raise ValueError('Unsafe generation name')
    destination = workspace / ('prepared-' + variant + ('-'+generation if generation else ''))
    if destination.exists():
        raise FileExistsError('Prepared directory already exists: ' + str(destination))
    destination.mkdir(parents=True)
    with checked_archive(workspace/'downloads/nampower-source.zip', SOURCE_SHA256) as archive:
        extract(archive, destination/'nampower')
    with checked_archive(workspace/'downloads/hadesmem-v142-Release-Win32.zip', HADESMEM_SHA256) as archive:
        extract(archive, destination/'hadesmem')
    source = destination/'nampower'/('nampower-'+SOURCE_COMMIT)
    hadesmem = destination/'hadesmem/hadesmem-v142-Release-Win32'
    main = source/'nampower/main.cpp'
    before = main.read_bytes()
    replace_once(main, '#include "logging.hpp"', '#include "logging.hpp"\n#include "startup_metrics.hpp"')
    replace_once(main,
        '        const int maxRetries = 10;',
        '        nampower_maintenance::HookMeasurement hook_measurement(static_cast<DWORD>(offset));\n        const int maxRetries = 10;')
    replace_once(main,
        '        for (int attempt = 0; attempt < maxRetries; ++attempt) {',
        '        for (int attempt = 0; attempt < maxRetries; ++attempt) {\n            hook_measurement.Attempt(static_cast<unsigned>(attempt + 1));')
    replace_once(main, '                return detour;', '                hook_measurement.Succeeded();\n                return detour;')
    replace_once(main,
        '    void initHooks() {\n        const hadesmem::Process process(::GetCurrentProcessId());',
        '    void initHooks() {\n        nampower_maintenance::StartupSession startup_profile;\n        const hadesmem::Process process(::GetCurrentProcessId());')
    replace_once(main,
        '        DEBUG_LOG("=== Starting hook initialization ===");',
        '        DEBUG_LOG("[MaintenanceBuild] source=' + SOURCE_COMMIT + ' pss_enabled=" << NAMP_MAINT_USE_PSS);\n        DEBUG_LOG("=== Starting hook initialization ===");')
    replace_once(main,
        '        DEBUG_LOG("=== All hooks initialized successfully ===");',
        SUMMARY + '        DEBUG_LOG("=== All hooks initialized successfully ===");')
    auxiliary = hadesmem/'include/memory/hadesmem/detail/patcher_aux.hpp'
    old_auxiliary = auxiliary.read_bytes()
    auxiliary_new = (HERE/'patches/patcher_aux.hpp').read_bytes()
    newline = b'\r\n' if b'\r\n' in old_auxiliary else b'\n'
    auxiliary.write_bytes(auxiliary_new.replace(b'\r\n',b'\n').replace(b'\n',newline))
    # Core gameplay, Lua registrations, hook addresses and order stay byte-identical
    # except this instrumentation in main.cpp. Include path injects shared headers.
    report = {
        'variant': variant, 'source_commit': SOURCE_COMMIT,
        'pss_enabled': variant == 'pss', 'source_directory': str(source),
        'hadesmem_directory': str(hadesmem), 'include_directory': str(HERE/'include'),
        'source_archive_sha256': SOURCE_SHA256, 'hadesmem_archive_sha256': HADESMEM_SHA256,
        'main_before_sha256': hashlib.sha256(before).hexdigest(),
        'main_after_sha256': hashlib.sha256(main.read_bytes()).hexdigest(),
        'modified_upstream_files': ['nampower/main.cpp', 'hadesmem/detail/patcher_aux.hpp'],
        'original_main_crlf': before.count(b'\r\n'),
        'prepared_main_crlf': main.read_bytes().count(b'\r\n'),
        'generation': generation,
        'shared_headers': {p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                           for p in sorted((HERE/'include').glob('*.hpp'))},
        'prepared_main_sha256': hashlib.sha256(main.read_bytes()).hexdigest(),
        'prepared_patcher_sha256': hashlib.sha256(auxiliary.read_bytes()).hexdigest(),
    }
    for label, old, new in [('main.cpp',before,main.read_bytes()),('patcher_aux.hpp',old_auxiliary,auxiliary.read_bytes())]:
        patch = ''.join(difflib.unified_diff(old.decode('utf-8-sig').splitlines(True),
            new.decode('utf-8-sig').splitlines(True),fromfile='original/'+label,tofile='prepared/'+label))
        (destination/(label+'.diff')).write_text(patch, encoding='utf-8', newline='')
    (destination/'prepared.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace',type=Path,required=True)
    parser.add_argument('--variant',choices=['original','pss'],required=True)
    parser.add_argument('--generation',default='')
    args = parser.parse_args()
    prepare(args.workspace,args.variant,args.generation)
