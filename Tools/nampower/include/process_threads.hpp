#pragma once

// C++14, header-only current-process thread enumeration for nampower maintenance.
// This adapter only obtains thread IDs. It never reads thread contexts, suspends
// threads, or changes code. Existing caller-side patch safety checks must remain.
// PSS exports are resolved dynamically so older Windows can use Toolhelp.

#include <windows.h>
#include <tlhelp32.h>

#include <cstddef>
#include <cstdint>
#include <system_error>
#include <vector>

namespace nampower_maintenance
{

// Keep this ABI declaration independent of processsnapshot.h / SDK version.
// PSS_CAPTURE_THREADS does not request any contexts or a VA clone.
#pragma pack(push, 8)
struct PssThreadEntry
{
    DWORD exit_status;
    void* teb_base_address;
    DWORD process_id;
    DWORD thread_id;
    ULONG_PTR affinity_mask;
    int priority;
    int base_priority;
    void* last_syscall_first_argument;
    WORD last_syscall_number;
    FILETIME create_time;
    FILETIME exit_time;
    FILETIME kernel_time;
    FILETIME user_time;
    void* win32_start_address;
    FILETIME capture_time;
    DWORD flags;
    WORD suspend_count;
    WORD context_size;
    void* context_record;
};
#pragma pack(pop)

static_assert(sizeof(PssThreadEntry) == (sizeof(void*) == 4 ? 92 : 120),
              "PSS_THREAD_ENTRY ABI size mismatch");
static_assert(offsetof(PssThreadEntry, thread_id) == (sizeof(void*) == 4 ? 12 : 20),
              "PSS_THREAD_ENTRY ThreadId offset mismatch");
static_assert(offsetof(PssThreadEntry, context_record) == (sizeof(void*) == 4 ? 88 : 112),
              "PSS_THREAD_ENTRY ContextRecord offset mismatch");

enum class ThreadBackend
{
    none,
    process_snapshot,
    toolhelp
};

enum class ThreadFallback
{
    none,
    pss_unavailable,
    non_current_process,
    capture_failed,
    marker_failed,
    walk_failed,
    invalid_entry,
    cleanup_failed
};

struct ThreadDiagnostics
{
    ThreadBackend backend = ThreadBackend::none;
    ThreadFallback fallback = ThreadFallback::none;
    DWORD pss_error = ERROR_SUCCESS;
    DWORD cleanup_error = ERROR_SUCCESS;
    std::size_t pss_entries = 0;
    std::size_t toolhelp_entries = 0;
    std::size_t matched_entries = 0;
    std::size_t toolhelp_snapshot_retries = 0;
    // Raw QPC ticks; the caller can convert using QueryPerformanceFrequency.
    // No allocation, formatting, file I/O or OutputDebugString is performed here.
    std::uint64_t pss_capture_ticks = 0;
    std::uint64_t pss_walk_ticks = 0;
    std::uint64_t pss_phase_ticks = 0;
    std::uint64_t toolhelp_phase_ticks = 0;
    std::uint64_t total_ticks = 0;
};

struct ThreadApi
{
    using Capture = DWORD(WINAPI*)(HANDLE, DWORD, DWORD, HANDLE*);
    using FreeSnapshot = DWORD(WINAPI*)(HANDLE, HANDLE);
    using MarkerCreate = DWORD(WINAPI*)(void const*, HANDLE*);
    using MarkerFree = DWORD(WINAPI*)(HANDLE);
    using Walk = DWORD(WINAPI*)(HANDLE, DWORD, HANDLE, void*, DWORD);

    Capture capture = nullptr;
    FreeSnapshot free_snapshot = nullptr;
    MarkerCreate marker_create = nullptr;
    MarkerFree marker_free = nullptr;
    Walk walk = nullptr;

    // All native operations are injectable for C++ failure/cleanup tests.
    decltype(&::CreateToolhelp32Snapshot) create_toolhelp_snapshot = &::CreateToolhelp32Snapshot;
    decltype(&::Thread32First) thread_first = &::Thread32First;
    decltype(&::Thread32Next) thread_next = &::Thread32Next;
    decltype(&::CloseHandle) close_handle = &::CloseHandle;
    decltype(&::GetLastError) last_error = &::GetLastError;
    decltype(&::GetCurrentProcessId) current_process_id = &::GetCurrentProcessId;
    decltype(&::GetCurrentProcess) current_process = &::GetCurrentProcess;
    decltype(&::QueryPerformanceCounter) performance_counter = &::QueryPerformanceCounter;

    bool HasPss() const noexcept
    {
        return capture && free_snapshot && marker_create && marker_free && walk;
    }
};

inline ThreadApi LoadThreadApi() noexcept
{
    ThreadApi api;
    HMODULE const kernel = ::GetModuleHandleW(L"kernel32.dll");
    if (kernel)
    {
        api.capture = reinterpret_cast<ThreadApi::Capture>(
            ::GetProcAddress(kernel, "PssCaptureSnapshot"));
        api.free_snapshot = reinterpret_cast<ThreadApi::FreeSnapshot>(
            ::GetProcAddress(kernel, "PssFreeSnapshot"));
        api.marker_create = reinterpret_cast<ThreadApi::MarkerCreate>(
            ::GetProcAddress(kernel, "PssWalkMarkerCreate"));
        api.marker_free = reinterpret_cast<ThreadApi::MarkerFree>(
            ::GetProcAddress(kernel, "PssWalkMarkerFree"));
        api.walk = reinterpret_cast<ThreadApi::Walk>(
            ::GetProcAddress(kernel, "PssWalkSnapshot"));
    }
    return api;
}

inline ThreadApi const& SystemThreadApi() noexcept
{
    static ThreadApi const api = LoadThreadApi();
    return api;
}

namespace thread_detail
{

inline std::uint64_t Tick(ThreadApi const& api, bool enabled) noexcept
{
    LARGE_INTEGER value{};
    return enabled && api.performance_counter && api.performance_counter(&value)
        ? static_cast<std::uint64_t>(value.QuadPart) : 0;
}

inline std::uint64_t Elapsed(std::uint64_t begin, std::uint64_t end) noexcept
{
    return begin && end >= begin ? end - begin : 0;
}

inline DWORD ErrorOrFailure(ThreadApi const& api) noexcept
{
    DWORD const error = api.last_error();
    return error ? error : ERROR_GEN_FAILURE;
}

inline void PssFailure(ThreadDiagnostics* diagnostics, ThreadFallback reason,
                       DWORD error) noexcept
{
    if (diagnostics && diagnostics->pss_error == ERROR_SUCCESS)
    {
        diagnostics->fallback = reason;
        diagnostics->pss_error = error ? error : ERROR_GEN_FAILURE;
    }
}

class PssObjects
{
public:
    PssObjects(ThreadApi const& api, ThreadDiagnostics* diagnostics) noexcept
        : api_(api), diagnostics_(diagnostics) {}

    ~PssObjects() noexcept { Close(); }
    PssObjects(PssObjects const&) = delete;
    PssObjects& operator=(PssObjects const&) = delete;

    bool Close() noexcept
    {
        DWORD error = ERROR_SUCCESS;
        // Marker-owned ContextRecord pointers are never exposed or retained.
        if (marker)
        {
            HANDLE const old = marker;
            marker = nullptr;
            error = api_.marker_free(old);
        }
        if (snapshot)
        {
            HANDLE const old = snapshot;
            snapshot = nullptr;
            // A locally captured snapshot belongs to this process, even if its
            // target differs. Currently only current-process captures are used.
            DWORD const free_error = api_.free_snapshot(api_.current_process(), old);
            if (!error) error = free_error;
        }
        if (error)
        {
            if (diagnostics_) diagnostics_->cleanup_error = error;
            PssFailure(diagnostics_, ThreadFallback::cleanup_failed, error);
        }
        return error == ERROR_SUCCESS;
    }

    HANDLE snapshot = nullptr;
    HANDLE marker = nullptr;

private:
    ThreadApi const& api_;
    ThreadDiagnostics* diagnostics_;
};

inline bool TryPss(DWORD process_id, ThreadApi const& api,
                   std::vector<DWORD>& ids, ThreadDiagnostics* diagnostics)
{
    PssObjects objects(api, diagnostics);
    std::uint64_t const begin = Tick(api, diagnostics != nullptr);
    HANDLE snapshot = nullptr;
    DWORD error = api.capture(api.current_process(), 0x80u, 0u, &snapshot);
    std::uint64_t const captured = Tick(api, diagnostics != nullptr);
    if (diagnostics) diagnostics->pss_capture_ticks = Elapsed(begin, captured);
    if (error || !snapshot)
    {
        PssFailure(diagnostics, ThreadFallback::capture_failed,
                   error ? error : ERROR_INVALID_DATA);
        return false;
    }
    objects.snapshot = snapshot;

    HANDLE marker = nullptr;
    error = api.marker_create(nullptr, &marker);
    bool success = false;
    if (error || !marker)
    {
        PssFailure(diagnostics, ThreadFallback::marker_failed,
                   error ? error : ERROR_INVALID_DATA);
    }
    else
    {
        objects.marker = marker;
        std::uint64_t const walk_begin = Tick(api, diagnostics != nullptr);
        for (;;)
        {
            PssThreadEntry entry{};
            error = api.walk(snapshot, 3u, marker, &entry,
                             static_cast<DWORD>(sizeof(entry)));
            if (error == ERROR_NO_MORE_ITEMS)
            {
                // A live current process must contain at least its caller.
                success = !ids.empty();
                if (!success)
                    PssFailure(diagnostics, ThreadFallback::invalid_entry,
                               ERROR_INVALID_DATA);
                break;
            }
            if (error)
            {
                PssFailure(diagnostics, ThreadFallback::walk_failed, error);
                break;
            }
            if (diagnostics) ++diagnostics->pss_entries;
            if (entry.process_id != process_id || !entry.thread_id ||
                entry.context_size || entry.context_record)
            {
                PssFailure(diagnostics, ThreadFallback::invalid_entry,
                           ERROR_INVALID_DATA);
                break;
            }
            // Deliberately do not silently discard threads by ExitStatus or
            // ExitTime. Let the existing OpenThread/GetThreadContext validation
            // handle thread-exit races, just as on the original Toolhelp path.
            ids.push_back(entry.thread_id);
        }
        if (diagnostics)
            diagnostics->pss_walk_ticks = Elapsed(walk_begin, Tick(api, true));
    }
    // Finish all cleanup before the caller starts a fresh Toolhelp fallback.
    return objects.Close() && success;
}

class ToolhelpSnapshot
{
public:
    ToolhelpSnapshot(ThreadApi const& api, HANDLE handle) noexcept
        : api_(api), handle_(handle) {}
    ~ToolhelpSnapshot() noexcept
    {
        if (handle_ != INVALID_HANDLE_VALUE) api_.close_handle(handle_);
    }
    ToolhelpSnapshot(ToolhelpSnapshot const&) = delete;
    ToolhelpSnapshot& operator=(ToolhelpSnapshot const&) = delete;

    void Close()
    {
        HANDLE const old = handle_;
        handle_ = INVALID_HANDLE_VALUE;
        if (!api_.close_handle(old))
            throw std::system_error(static_cast<int>(ErrorOrFailure(api_)),
                                    std::system_category(), "CloseHandle(thread snapshot)");
    }

private:
    ThreadApi const& api_;
    HANDLE handle_;
};

inline std::vector<DWORD> Toolhelp(DWORD process_id, ThreadApi const& api,
                                  ThreadDiagnostics* diagnostics)
{
    HANDLE snapshot;
    // Preserve the original hadesmem retry semantics for transient snapshots.
    for (;;)
    {
        snapshot = api.create_toolhelp_snapshot(TH32CS_SNAPTHREAD, 0);
        if (snapshot != INVALID_HANDLE_VALUE) break;
        DWORD const error = ErrorOrFailure(api);
        if (error != ERROR_BAD_LENGTH)
            throw std::system_error(static_cast<int>(error), std::system_category(),
                                    "CreateToolhelp32Snapshot(threads)");
        if (diagnostics) ++diagnostics->toolhelp_snapshot_retries;
    }
    ToolhelpSnapshot owned(api, snapshot);
    std::vector<DWORD> ids;
    ids.reserve(32);
    THREADENTRY32 entry{};
    entry.dwSize = static_cast<DWORD>(sizeof(entry));
    BOOL ok = api.thread_first(snapshot, &entry);
    for (;;)
    {
        if (!ok)
        {
            DWORD const error = ErrorOrFailure(api);
            if (error == ERROR_NO_MORE_FILES) break;
            throw std::system_error(static_cast<int>(error), std::system_category(),
                                    "Thread32First/Next");
        }
        if (diagnostics) ++diagnostics->toolhelp_entries;
        if (entry.dwSize < offsetof(THREADENTRY32, th32OwnerProcessID) + sizeof(DWORD))
            throw std::system_error(ERROR_BAD_LENGTH, std::system_category(),
                                    "Incomplete THREADENTRY32");
        if (entry.th32OwnerProcessID == process_id) ids.push_back(entry.th32ThreadID);
        entry = THREADENTRY32{};
        entry.dwSize = static_cast<DWORD>(sizeof(entry));
        ok = api.thread_next(snapshot, &entry);
    }
    owned.Close();
    return ids;
}

} // namespace thread_detail

inline std::vector<DWORD> EnumerateProcessThreads(
    DWORD process_id, ThreadApi const& api = SystemThreadApi(),
    ThreadDiagnostics* diagnostics = nullptr)
{
    if (diagnostics) *diagnostics = ThreadDiagnostics{};
    std::uint64_t const begin = thread_detail::Tick(api, diagnostics != nullptr);
    if (process_id == api.current_process_id() && api.HasPss())
    {
        std::vector<DWORD> ids;
        ids.reserve(32);
        bool const success = thread_detail::TryPss(process_id, api, ids, diagnostics);
        if (diagnostics)
            diagnostics->pss_phase_ticks = thread_detail::Elapsed(
                begin, thread_detail::Tick(api, true));
        if (success)
        {
            if (diagnostics)
            {
                diagnostics->backend = ThreadBackend::process_snapshot;
                diagnostics->matched_entries = ids.size();
                diagnostics->total_ticks = thread_detail::Elapsed(
                    begin, thread_detail::Tick(api, true));
            }
            return ids;
        }
        // 'ids' and all PSS objects are gone before Toolhelp begins. Partial
        // results cannot be mixed with or reused as a fallback thread list.
    }
    else if (diagnostics)
    {
        diagnostics->fallback = process_id != api.current_process_id()
            ? ThreadFallback::non_current_process : ThreadFallback::pss_unavailable;
        if (diagnostics->fallback == ThreadFallback::pss_unavailable)
            diagnostics->pss_error = ERROR_PROC_NOT_FOUND;
    }

    std::uint64_t const fallback_begin = thread_detail::Tick(api, diagnostics != nullptr);
    std::vector<DWORD> ids = thread_detail::Toolhelp(process_id, api, diagnostics);
    if (diagnostics)
    {
        diagnostics->backend = ThreadBackend::toolhelp;
        diagnostics->matched_entries = ids.size();
        std::uint64_t const end = thread_detail::Tick(api, true);
        diagnostics->toolhelp_phase_ticks = thread_detail::Elapsed(fallback_begin, end);
        diagnostics->total_ticks = thread_detail::Elapsed(begin, end);
    }
    return ids;
}

} // namespace nampower_maintenance
