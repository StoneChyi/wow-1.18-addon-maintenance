// Native C++14 test/benchmark for the production header. Never opens the game.
// Build with /EHsc /std:c++14 /O2; run no args for injected tests or --live.
#include "../include/process_threads.hpp"

#include <algorithm>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <exception>
#include <new>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

// A precise allocation-failure injection: the mock walk arms this immediately
// before the 33rd ID is pushed into the production vector (reserved for 32).
static bool fail_next_allocation = false;
void* operator new(std::size_t size)
{
    if (fail_next_allocation)
    {
        fail_next_allocation = false;
        throw std::bad_alloc();
    }
    if (void* memory = std::malloc(size ? size : 1)) return memory;
    throw std::bad_alloc();
}
void* operator new[](std::size_t size) { return ::operator new(size); }
void operator delete(void* memory) noexcept { std::free(memory); }
void operator delete[](void* memory) noexcept { std::free(memory); }
void operator delete(void* memory, std::size_t) noexcept { std::free(memory); }
void operator delete[](void* memory, std::size_t) noexcept { std::free(memory); }

namespace test
{
using namespace nampower_maintenance;

enum class Event { capture, marker_create, walk, marker_free, snapshot_free,
                   toolhelp_create, toolhelp_first, toolhelp_next, toolhelp_close };

struct FakeState
{
    std::vector<Event> events;
    std::vector<PssThreadEntry> pss;
    std::vector<THREADENTRY32> toolhelp;
    DWORD last_error = ERROR_SUCCESS;
    DWORD capture_error = ERROR_SUCCESS;
    DWORD marker_error = ERROR_SUCCESS;
    DWORD walk_error = ERROR_ACCESS_DENIED;
    DWORD marker_free_error = ERROR_SUCCESS;
    DWORD snapshot_free_error = ERROR_SUCCESS;
    DWORD toolhelp_create_error = ERROR_SUCCESS;
    DWORD first_error = ERROR_SUCCESS;
    DWORD next_error = ERROR_SUCCESS;
    DWORD close_error = ERROR_SUCCESS;
    unsigned bad_length_retries = 0;
    int fail_walk_at = -1;
    int fail_next_at = -1;
    int arm_bad_alloc_at = -1;
    std::size_t pss_index = 0;
    std::size_t toolhelp_index = 0;
    bool null_snapshot = false;
    bool null_marker = false;
    bool arguments_valid = true;
    unsigned captures = 0, snapshot_frees = 0, marker_creates = 0, marker_frees = 0;
    unsigned toolhelp_creates = 0, toolhelp_closes = 0;
    LONGLONG clock = 0;
};
FakeState state;

HANDLE Handle(std::uintptr_t value) { return reinterpret_cast<HANDLE>(value); }
DWORD WINAPI CurrentPid() { return 100; }
HANDLE WINAPI CurrentProcess() { return Handle(1); }
DWORD WINAPI LastError() { return state.last_error; }
BOOL WINAPI Counter(LARGE_INTEGER* value) { state.clock += 10; value->QuadPart = state.clock; return TRUE; }

void Check(bool condition, char const* message)
{
    if (!condition) throw std::runtime_error(message);
}
void Push(Event event) { state.events.push_back(event); }

DWORD WINAPI Capture(HANDLE process, DWORD flags, DWORD contexts, HANDLE* output)
{
    Push(Event::capture); ++state.captures;
    state.arguments_valid &= process == Handle(1) && flags == 0x80 && contexts == 0;
    state.pss_index = 0;
    *output = state.capture_error || state.null_snapshot ? nullptr : Handle(2);
    return state.capture_error;
}
DWORD WINAPI FreeSnapshot(HANDLE process, HANDLE snapshot)
{
    Push(Event::snapshot_free); ++state.snapshot_frees;
    state.arguments_valid &= process == Handle(1) && snapshot == Handle(2);
    return state.snapshot_free_error;
}
DWORD WINAPI MarkerCreate(void const* allocator, HANDLE* output)
{
    Push(Event::marker_create); ++state.marker_creates;
    state.arguments_valid &= allocator == nullptr;
    *output = state.marker_error || state.null_marker ? nullptr : Handle(3);
    return state.marker_error;
}
DWORD WINAPI MarkerFree(HANDLE marker)
{
    Push(Event::marker_free); ++state.marker_frees;
    state.arguments_valid &= marker == Handle(3);
    return state.marker_free_error;
}
DWORD WINAPI Walk(HANDLE snapshot, DWORD information_class, HANDLE marker,
                  void* buffer, DWORD length)
{
    Push(Event::walk);
    state.arguments_valid &= snapshot == Handle(2) && information_class == 3 &&
        marker == Handle(3) && length == sizeof(PssThreadEntry);
    if (state.fail_walk_at >= 0 && state.pss_index == static_cast<std::size_t>(state.fail_walk_at))
        return state.walk_error;
    if (state.pss_index == state.pss.size()) return ERROR_NO_MORE_ITEMS;
    *static_cast<PssThreadEntry*>(buffer) = state.pss[state.pss_index];
    if (state.arm_bad_alloc_at >= 0 && state.pss_index == static_cast<std::size_t>(state.arm_bad_alloc_at))
        fail_next_allocation = true;
    ++state.pss_index;
    return ERROR_SUCCESS;
}
HANDLE WINAPI CreateToolhelp(DWORD flags, DWORD process_id)
{
    Push(Event::toolhelp_create); ++state.toolhelp_creates;
    state.arguments_valid &= flags == TH32CS_SNAPTHREAD && process_id == 0;
    if (state.bad_length_retries)
    {
        --state.bad_length_retries; state.last_error = ERROR_BAD_LENGTH;
        return INVALID_HANDLE_VALUE;
    }
    if (state.toolhelp_create_error)
    {
        state.last_error = state.toolhelp_create_error; return INVALID_HANDLE_VALUE;
    }
    return Handle(4);
}
BOOL WINAPI First(HANDLE snapshot, THREADENTRY32* output)
{
    Push(Event::toolhelp_first);
    state.arguments_valid &= snapshot == Handle(4) && output->dwSize == sizeof(THREADENTRY32);
    state.toolhelp_index = 0;
    if (state.first_error) { state.last_error = state.first_error; return FALSE; }
    if (state.toolhelp.empty()) { state.last_error = ERROR_NO_MORE_FILES; return FALSE; }
    *output = state.toolhelp[0]; return TRUE;
}
BOOL WINAPI Next(HANDLE snapshot, THREADENTRY32* output)
{
    Push(Event::toolhelp_next);
    state.arguments_valid &= snapshot == Handle(4) && output->dwSize == sizeof(THREADENTRY32);
    ++state.toolhelp_index;
    if (state.fail_next_at >= 0 && state.toolhelp_index == static_cast<std::size_t>(state.fail_next_at))
    { state.last_error = state.next_error; return FALSE; }
    if (state.toolhelp_index == state.toolhelp.size())
    { state.last_error = ERROR_NO_MORE_FILES; return FALSE; }
    *output = state.toolhelp[state.toolhelp_index]; return TRUE;
}
BOOL WINAPI Close(HANDLE snapshot)
{
    Push(Event::toolhelp_close); ++state.toolhelp_closes;
    state.arguments_valid &= snapshot == Handle(4);
    if (state.close_error) { state.last_error = state.close_error; return FALSE; }
    return TRUE;
}

ThreadApi Reset()
{
    fail_next_allocation = false;
    state = FakeState{};
    state.events.reserve(512); state.pss.reserve(128); state.toolhelp.reserve(128);
    for (DWORD id : {11u, 12u})
    {
        PssThreadEntry entry{}; entry.process_id = 100; entry.thread_id = id;
        entry.exit_status = STILL_ACTIVE; state.pss.push_back(entry);
    }
    for (std::pair<DWORD, DWORD> id : {std::make_pair(13u, 999u), std::make_pair(21u, 100u), std::make_pair(22u, 100u)})
    {
        THREADENTRY32 entry{}; entry.dwSize = static_cast<DWORD>(sizeof(entry));
        entry.th32ThreadID = id.first; entry.th32OwnerProcessID = id.second;
        state.toolhelp.push_back(entry);
    }
    ThreadApi api;
    api.capture = &Capture; api.free_snapshot = &FreeSnapshot;
    api.marker_create = &MarkerCreate; api.marker_free = &MarkerFree; api.walk = &Walk;
    api.create_toolhelp_snapshot = &CreateToolhelp; api.thread_first = &First;
    api.thread_next = &Next; api.close_handle = &Close; api.last_error = &LastError;
    api.current_process_id = &CurrentPid; api.current_process = &CurrentProcess;
    api.performance_counter = &Counter;
    return api;
}

void CheckFallback(std::vector<DWORD> const& ids, ThreadDiagnostics const& diagnostics)
{
    Check(ids == std::vector<DWORD>({21, 22}), "fallback must contain only complete Toolhelp IDs");
    Check(diagnostics.backend == ThreadBackend::toolhelp, "fallback backend");
    Check(state.toolhelp_creates > 0 && state.toolhelp_closes == 1, "Toolhelp lifetime");
    Check(state.arguments_valid, "native argument contract");
    auto toolhelp = std::find(state.events.begin(), state.events.end(), Event::toolhelp_create);
    auto marker = std::find(state.events.begin(), state.events.end(), Event::marker_free);
    auto snapshot = std::find(state.events.begin(), state.events.end(), Event::snapshot_free);
    if (marker != state.events.end()) Check(marker < toolhelp, "marker cleanup precedes fallback");
    if (snapshot != state.events.end()) Check(snapshot < toolhelp, "snapshot cleanup precedes fallback");
    if (marker != state.events.end() && snapshot != state.events.end()) Check(marker < snapshot, "marker frees first");
}

void Success()
{
    auto api = Reset(); ThreadDiagnostics diagnostics;
    auto ids = EnumerateProcessThreads(100, api, &diagnostics);
    Check(ids == std::vector<DWORD>({11, 12}), "PSS ID list");
    Check(diagnostics.backend == ThreadBackend::process_snapshot, "PSS backend");
    Check(diagnostics.fallback == ThreadFallback::none && diagnostics.pss_error == 0, "no false fallback");
    Check(state.toolhelp_creates == 0 && state.captures == 1, "PSS does not use Toolhelp");
    Check(state.snapshot_frees == 1 && state.marker_frees == 1, "PSS lifetime");
    Check(diagnostics.pss_entries == 2 && diagnostics.matched_entries == 2, "entry counters");
    Check(diagnostics.pss_capture_ticks && diagnostics.pss_walk_ticks && diagnostics.total_ticks, "QPC timing");
    Check(state.arguments_valid, "PSS argument contract");
    state.pss[0].thread_id = 31;
    ids = EnumerateProcessThreads(100, api, &diagnostics);
    Check(ids.front() == 31 && state.captures == 2, "each call obtains fresh snapshot");
}
void ExitMetadata()
{
    auto api = Reset();
    state.pss[0].exit_status = 0; state.pss[0].exit_time.dwLowDateTime = 999;
    auto ids = EnumerateProcessThreads(100, api);
    Check(ids == std::vector<DWORD>({11, 12}), "exited metadata is not silently filtered");
}
void MissingExports()
{
    for (unsigned i = 0; i < 5; ++i)
    {
        auto api = Reset();
        switch (i) { case 0: api.capture = nullptr; break; case 1: api.free_snapshot = nullptr; break;
          case 2: api.marker_create = nullptr; break; case 3: api.marker_free = nullptr; break; case 4: api.walk = nullptr; break; }
        ThreadDiagnostics diagnostics;
        CheckFallback(EnumerateProcessThreads(100, api, &diagnostics), diagnostics);
        Check(state.captures == 0 && diagnostics.pss_error == ERROR_PROC_NOT_FOUND, "missing export gate");
        Check(diagnostics.fallback == ThreadFallback::pss_unavailable, "unavailable reason");
    }
}
void CaptureFailure()
{
    auto api = Reset(); state.capture_error = ERROR_ACCESS_DENIED; ThreadDiagnostics diagnostics;
    CheckFallback(EnumerateProcessThreads(100, api, &diagnostics), diagnostics);
    Check(diagnostics.fallback == ThreadFallback::capture_failed, "capture failure reason");
    Check(state.snapshot_frees == 0 && state.marker_creates == 0, "failed capture creates no owned object");
}
void MarkerFailure()
{
    auto api = Reset(); state.marker_error = ERROR_NOT_ENOUGH_MEMORY; ThreadDiagnostics diagnostics;
    CheckFallback(EnumerateProcessThreads(100, api, &diagnostics), diagnostics);
    Check(diagnostics.fallback == ThreadFallback::marker_failed, "marker failure reason");
    Check(state.snapshot_frees == 1 && state.marker_frees == 0, "marker error cleans snapshot");
}
void WalkFailure()
{
    for (int failure_index : {0, 1})
    {
        auto api = Reset(); state.fail_walk_at = failure_index; ThreadDiagnostics diagnostics;
        CheckFallback(EnumerateProcessThreads(100, api, &diagnostics), diagnostics);
        Check(diagnostics.fallback == ThreadFallback::walk_failed, "walk failure reason");
        Check(diagnostics.pss_entries == static_cast<std::size_t>(failure_index), "partial PSS list was really collected");
        Check(state.snapshot_frees == 1 && state.marker_frees == 1, "walk error cleanup");
    }
}
void InvalidEntries()
{
    for (int mode = 0; mode < 7; ++mode)
    {
        auto api = Reset();
        switch (mode) { case 0: state.pss[0].process_id = 999; break; case 1: state.pss[0].thread_id = 0; break;
        case 2: state.pss[0].context_record = Handle(8); break; case 3: state.pss[0].context_size = 716; break;
        case 4: state.pss.clear(); break; case 5: state.null_snapshot = true; break; case 6: state.null_marker = true; break; }
        ThreadDiagnostics diagnostics;
        CheckFallback(EnumerateProcessThreads(100, api, &diagnostics), diagnostics);
        Check(diagnostics.pss_error == ERROR_INVALID_DATA, "invalid native result error");
    }
}
void CleanupFailure()
{
    for (int mode = 0; mode < 3; ++mode)
    {
        auto api = Reset();
        if (mode == 0) state.marker_free_error = ERROR_INVALID_HANDLE;
        if (mode == 1) state.snapshot_free_error = ERROR_INVALID_HANDLE;
        if (mode == 2) { state.fail_walk_at = 1; state.snapshot_free_error = ERROR_INVALID_HANDLE; }
        ThreadDiagnostics diagnostics;
        CheckFallback(EnumerateProcessThreads(100, api, &diagnostics), diagnostics);
        Check(state.marker_frees == 1 && state.snapshot_frees == 1, "both cleanup attempts exactly once");
        Check(diagnostics.cleanup_error == ERROR_INVALID_HANDLE, "cleanup error retained");
        Check(diagnostics.pss_error == (mode == 2 ? ERROR_ACCESS_DENIED : ERROR_INVALID_HANDLE), "first PSS error preserved");
    }
}
void AllocationFailure()
{
    auto api = Reset(); state.pss.clear();
    for (DWORD i = 0; i < 33; ++i) { PssThreadEntry entry{}; entry.process_id = 100; entry.thread_id = i + 1; state.pss.push_back(entry); }
    state.arm_bad_alloc_at = 32; bool caught = false;
    try { EnumerateProcessThreads(100, api); } catch (std::bad_alloc const&) { caught = true; }
    fail_next_allocation = false;
    Check(caught, "collection allocation failure propagates");
    Check(state.pss_index == 33, "bad_alloc occurs after acquired snapshot and 32 collected IDs");
    Check(state.marker_frees == 1 && state.snapshot_frees == 1, "exception RAII cleanup");
    Check(state.toolhelp_creates == 0, "allocation failure is not hidden by expensive fallback");
}
void OtherProcess()
{
    auto api = Reset(); state.toolhelp[0].th32OwnerProcessID = 200; ThreadDiagnostics diagnostics;
    auto ids = EnumerateProcessThreads(200, api, &diagnostics);
    Check(ids == std::vector<DWORD>({13}), "remote PID filtering");
    Check(state.captures == 0 && diagnostics.fallback == ThreadFallback::non_current_process, "remote PID uses original backend");
}
void ToolhelpRetryAndEmpty()
{
    auto api = Reset(); api.capture = nullptr; state.bad_length_retries = 2; ThreadDiagnostics diagnostics;
    CheckFallback(EnumerateProcessThreads(100, api, &diagnostics), diagnostics);
    Check(state.toolhelp_creates == 3 && diagnostics.toolhelp_snapshot_retries == 2, "bad length retry semantics");
    api = Reset(); api.capture = nullptr; state.toolhelp.clear();
    Check(EnumerateProcessThreads(100, api).empty(), "empty Toolhelp is successful end-of-list");
    Check(state.toolhelp_closes == 1, "empty Toolhelp closes snapshot");
}
void ToolhelpErrors()
{
    for (int mode = 0; mode < 5; ++mode)
    {
        auto api = Reset(); api.capture = nullptr;
        switch (mode) { case 0: state.toolhelp_create_error = ERROR_ACCESS_DENIED; break;
        case 1: state.first_error = ERROR_ACCESS_DENIED; break;
        case 2: state.fail_next_at = 1; state.next_error = ERROR_ACCESS_DENIED; break;
        case 3: state.toolhelp[0].dwSize = 0; break;
        case 4: state.close_error = ERROR_INVALID_HANDLE; break; }
        bool caught = false;
        try { EnumerateProcessThreads(100, api); } catch (std::system_error const&) { caught = true; }
        Check(caught, "Toolhelp failure must not return a success/partial list");
        Check(state.toolhelp_closes == (mode == 0 ? 0u : 1u), "Toolhelp error cleanup attempt count");
    }
}
void OptionalTiming()
{
    auto api = Reset(); auto ids = EnumerateProcessThreads(100, api);
    Check(state.clock == 0 && ids.size() == 2, "null diagnostics performs no timing calls");
    api = Reset(); api.performance_counter = nullptr; ThreadDiagnostics diagnostics;
    EnumerateProcessThreads(100, api, &diagnostics);
    Check(diagnostics.total_ticks == 0 && diagnostics.pss_phase_ticks == 0, "optional QPC provider");
}

int UnitTests()
{
    using Test = std::pair<char const*, void(*)()>;
    Test const tests[] = { {"success-and-freshness", &Success}, {"exit-metadata-retained", &ExitMetadata},
        {"missing-exports", &MissingExports}, {"capture-failure", &CaptureFailure}, {"marker-failure", &MarkerFailure},
        {"walk-and-partial-failure", &WalkFailure}, {"invalid-native-results", &InvalidEntries},
        {"cleanup-failures", &CleanupFailure}, {"bad-alloc-propagation", &AllocationFailure},
        {"other-process", &OtherProcess}, {"toolhelp-retry-empty", &ToolhelpRetryAndEmpty},
        {"toolhelp-errors", &ToolhelpErrors}, {"optional-timing", &OptionalTiming} };
    int failures = 0;
    for (auto const& test : tests)
    {
        try { test.second(); std::printf("PASS %s\n", test.first); }
        catch (std::exception const& error) { ++failures; fail_next_allocation = false; std::printf("FAIL %s: %s\n", test.first, error.what()); }
    }
    std::printf("unit_groups=%zu failures=%d bitness=%zu\n", sizeof(tests)/sizeof(tests[0]), failures, sizeof(void*)*8);
    return failures ? 1 : 0;
}

class LiveWorker
{
public:
    LiveWorker()
    {
        try
        {
            ready_ = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
            stop_ = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
            if (!ready_ || !stop_) throw std::runtime_error("CreateEvent failed");
            thread_ = ::CreateThread(nullptr, 0, &Run, this, 0, &id_);
            if (!thread_ || ::WaitForSingleObject(ready_, 5000) != WAIT_OBJECT_0)
                throw std::runtime_error("CreateThread/readiness failed");
        }
        catch (...) { Close(); throw; }
    }
    ~LiveWorker() { Close(); }
    LiveWorker(LiveWorker const&) = delete;
    LiveWorker& operator=(LiveWorker const&) = delete;
    DWORD Id() const noexcept { return id_; }
private:
    void Close() noexcept
    {
        if (stop_) ::SetEvent(stop_);
        if (thread_) { ::WaitForSingleObject(thread_, INFINITE); ::CloseHandle(thread_); thread_ = nullptr; }
        if (ready_) { ::CloseHandle(ready_); ready_ = nullptr; }
        if (stop_) { ::CloseHandle(stop_); stop_ = nullptr; }
    }
    static DWORD WINAPI Run(void* argument)
    {
        LiveWorker* worker = static_cast<LiveWorker*>(argument);
        ::SetEvent(worker->ready_); ::WaitForSingleObject(worker->stop_, INFINITE); return 0;
    }
    HANDLE ready_ = nullptr, stop_ = nullptr, thread_ = nullptr;
    DWORD id_ = 0;
};

int LiveTests()
{
    std::vector<LiveWorker*> workers;
    workers.reserve(72);
    try
    {
        for (unsigned i = 0; i < 72; ++i) workers.push_back(new LiveWorker());
        LARGE_INTEGER frequency{}; Check(::QueryPerformanceFrequency(&frequency) != 0, "QPC frequency");
        ThreadApi const pss_api = SystemThreadApi();
        Check(pss_api.HasPss(), "live PSS unavailable");
        ThreadApi toolhelp_api = pss_api; toolhelp_api.capture = nullptr;
        auto verify = [&workers](std::vector<DWORD> const& ids)
        {
            for (auto const worker : workers)
                Check(std::find(ids.begin(), ids.end(), worker->Id()) != ids.end(), "stable live worker missing");
            std::vector<DWORD> sorted(ids); std::sort(sorted.begin(), sorted.end());
            Check(std::adjacent_find(sorted.begin(), sorted.end()) == sorted.end(), "duplicate live ID");
        };
        DWORD const pid = ::GetCurrentProcessId();
        for (unsigned round = 0; round < 5; ++round)
        {
            for (unsigned slot = 0; slot < 2; ++slot)
            {
                bool const use_pss = (slot + round) % 2 != 0;
                ThreadApi const& api = use_pss ? pss_api : toolhelp_api;
                std::uint64_t total_ticks = 0; std::size_t visits = 0;
                for (unsigned i = 0; i < 59; ++i)
                {
                    ThreadDiagnostics diagnostics;
                    auto const ids = EnumerateProcessThreads(pid, api, &diagnostics);
                    verify(ids);
                    Check(diagnostics.backend == (use_pss ? ThreadBackend::process_snapshot : ThreadBackend::toolhelp), "unexpected live fallback");
                    total_ticks += diagnostics.total_ticks;
                    visits += use_pss ? diagnostics.pss_entries : diagnostics.toolhelp_entries;
                }
                std::printf("round=%u backend=%s total59_ms=%.6f visited=%zu\n", round, use_pss ? "pss" : "toolhelp",
                    1000.0 * total_ticks / frequency.QuadPart, visits);
            }
        }
        // Freshness with held native threads, including the adapter's no-filter policy.
        for (unsigned i = 0; i < 20; ++i)
        {
            DWORD transient_id;
            {
                LiveWorker transient; transient_id = transient.Id();
                auto const ids = EnumerateProcessThreads(pid, pss_api);
                verify(ids);
                Check(std::find(ids.begin(), ids.end(), transient_id) != ids.end(), "new live thread missing");
            }
            auto const ids = EnumerateProcessThreads(pid, pss_api);
            verify(ids);
            Check(std::find(ids.begin(), ids.end(), transient_id) == ids.end(), "exited thread retained by native adapter");
        }
        DWORD before_handles = 0, after_handles = 0;
        Check(::GetProcessHandleCount(::GetCurrentProcess(), &before_handles) != 0, "handle count before");
        for (unsigned i = 0; i < 5000; ++i) verify(EnumerateProcessThreads(pid, pss_api));
        Check(::GetProcessHandleCount(::GetCurrentProcess(), &after_handles) != 0, "handle count after");
        Check(after_handles == before_handles, "native adapter handle accumulation");
        std::printf("live_pass bitness=%zu held_workers=72 lifecycle_rounds=20 resource_rounds=5000 handles_before=%lu handles_after=%lu\n",
                    sizeof(void*)*8, before_handles, after_handles);
    }
    catch (...)
    {
        for (auto const worker : workers) delete worker;
        throw;
    }
    for (auto const worker : workers) delete worker;
    return 0;
}

} // namespace test

int main(int argc, char** argv)
{
    try
    {
        if (argc == 2 && std::strcmp(argv[1], "--live") == 0) return test::LiveTests();
        if (argc != 1) { std::printf("Usage: process_threads_test.exe [--live]\n"); return 2; }
        return test::UnitTests();
    }
    catch (std::exception const& error) { std::printf("FATAL %s\n", error.what()); return 1; }
}
