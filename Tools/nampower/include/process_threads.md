# Current-process thread enumeration adapter

`process_threads.hpp` is an independent C++14, Windows-only maintenance adapter.
It needs only the standard library, `windows.h`, `tlhelp32.h` and Kernel32; it
does not depend on Boost/hadesmem and does not import PSS functions statically.

## Interface

```cpp
nampower_maintenance::ThreadDiagnostics diagnostics;
auto ids = nampower_maintenance::EnumerateProcessThreads(
    process_id, nampower_maintenance::SystemThreadApi(), &diagnostics);
```

The return value is a fresh `std::vector<DWORD>` for this call. Pass `nullptr`
for diagnostics to avoid QPC timing calls. The helper does no formatting or I/O.
QPC durations are raw ticks; convert them outside the helper using
`QueryPerformanceFrequency`.

PSS is used only when `process_id` is the current process ID and all five
capture/free/marker/walk exports are available. Other target processes use the
original Toolhelp enumeration strategy, without introducing a new OpenProcess
access requirement.

Every call creates a new snapshot. Missing APIs, capture errors, marker errors,
walk errors (including after partial results), malformed foreign/context entries,
an unexpectedly empty current-process result, or a PSS cleanup error cause a
complete Toolhelp fallback. No partial PSS IDs are reused. PSS cleanup is
completed/attempted before fallback starts. Cleanup functions are attempted once
per acquired object; failing cleanup is recorded, not retried on a descriptor
whose state is unknown.

Toolhelp errors throw `std::system_error`; callers that require a hadesmem error
type should translate that exception at their integration boundary. Failure to
allocate a vector propagates naturally, with RAII cleanup, rather than hiding an
allocation failure and trying a more expensive backend.

## Semantics and limits

Only `PSS_CAPTURE_THREADS` is requested. No thread context, VA clone, process
memory, or handle table is captured. The helper never opens/suspends threads and
never changes code. Existing `OpenThread` / `GetThreadContext` / range checks
must remain in the caller; enumeration is not a safe patch transaction by itself.

Unlike the exploratory C# program, this production adapter **does not filter
threads by ExitStatus/ExitTime**. Silently dropping an ID would change which
threads are checked by the original caller. A thread that exits after capture
must still be handled by the original validation/error policy. Thus this helper
does not claim to fix the existing running-thread context and patch-write race.

The ABI record is declared locally with 8-byte maximum packing and compile-time
size/offset checks (Win32: 92 bytes, Win64: 120 bytes). This permits compilation
with an older Windows SDK without `processsnapshot.h`; real old-Windows runtime
compatibility still needs separate testing. Current-process snapshots must be
freed using `GetCurrentProcess`, not a pseudo-remote target handle.

## Injectable C++ tests

Copy `SystemThreadApi()` and replace any function pointer. Suggested tests:

- Null each of the five PSS pointers; confirm no PSS call and full Toolhelp result.
- Capture/marker/walk failure; walk failure after at least one valid ID.
- Call-order assertions: marker free then snapshot free, then Toolhelp starts.
- Successful PSS avoids Toolhelp; no stale snapshot reused between calls.
- Foreign PID, zero thread ID, unexpected context, empty PSS result fall back.
- Exited metadata remains in the ID list for caller validation.
- Non-current target uses Toolhelp without calling PSS/OpenProcess.
- Exception during allocation/collection still releases acquired PSS objects.
- Toolhelp bad-length retry, enumeration errors and CloseHandle error propagate.
- Cleanup failure returns no successful PSS result and is exposed in diagnostics.
- QPC can be replaced with a deterministic counter or `nullptr`.

Native C++ tests should additionally compare real API thread coverage and resource
behavior on the current machine; the previous C# experiment is evidence for the
approach, not proof that this C++ adapter or a future game DLL has been validated.

The supplied `../tests/process_threads_test.cpp` has no Boost dependency. With a
Windows C++14 compiler, use `/EHsc /std:c++14 /O2`, choose x86 for the game-matching
run, and direct `/Fe` plus compiler temporary/object paths to an E-drive build
directory. No arguments run 13 injected test groups; `--live` runs five alternating
59-call native API batches, 72 held native workers, 20 thread create/exit rounds,
and 5000 snapshot calls with process-handle-count checks. The native test retains
exit metadata, matching this header rather than the earlier exploratory filter.

Test source and static review are complete. Compilation/runtime results must be
recorded separately by the integrating build; this document does not claim those
checks have already run.
