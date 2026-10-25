// Exercise the prepared hadesmem verification path in this test process only.
// It observes waiting threads but never installs a hook or writes process memory.
#include <hadesmem/detail/patcher_aux.hpp>
#include "startup_metrics.hpp"
#include <cstdio>
#include <vector>
#include <stdexcept>

static DWORD WINAPI WaitingWorker(void* event)
{
    ::WaitForSingleObject(static_cast<HANDLE>(event), INFINITE);
    return 0;
}

int main()
{
    HANDLE stop = ::CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!stop) return 2;
    std::vector<HANDLE> workers;
    int result = 1;
    try
    {
        for (unsigned i = 0; i < 72; ++i)
        {
            HANDLE thread = ::CreateThread(nullptr, 0, &WaitingWorker, stop, 0, nullptr);
            if (!thread) throw std::runtime_error("CreateThread failed");
            workers.push_back(thread);
        }
        nampower_maintenance::StartupSession profile;
        // The target is never called by the worker threads. GetThreadContext's
        // running-thread limitations remain; this test is not patch safety proof.
        for (unsigned i = 0; i < 59; ++i)
            hadesmem::detail::VerifyPatchThreads(::GetCurrentProcessId(),
                reinterpret_cast<void*>(&main), 5);
        profile.Finish();
        auto const& c = profile.counters;
        bool valid = c.verify_calls == 59 && c.thread_checks >= 59 * workers.size();
#if NAMP_MAINT_USE_PSS
        valid = valid && c.pss_calls + c.fallback_calls == 59;
#endif
        std::printf("integration pss=%d init_ms=%.6f verify_ms=%.6f enum_ms=%.6f enum_samples=%llu calls=%llu checks=%llu pss_calls=%llu fallback=%llu pss_entries=%llu system_entries=%llu pass=%d\n",
            NAMP_MAINT_USE_PSS, nampower_maintenance::StartupMilliseconds(profile.Ticks()),
            nampower_maintenance::StartupMilliseconds(c.verify_ticks),
            nampower_maintenance::StartupMilliseconds(c.enum_ticks), c.enum_samples, c.verify_calls,
            c.thread_checks, c.pss_calls, c.fallback_calls, c.pss_entries,
            c.toolhelp_entries, valid ? 1 : 0);
        result = valid ? 0 : 1;
    }
    catch (std::exception const& error) { std::printf("integration exception: %s\n", error.what()); }
    ::SetEvent(stop);
    for (HANDLE worker : workers) { ::WaitForSingleObject(worker, INFINITE); ::CloseHandle(worker); }
    ::CloseHandle(stop);
    return result;
}
