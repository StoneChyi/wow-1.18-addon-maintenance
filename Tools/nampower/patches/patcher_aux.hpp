// Copyright (C) 2010-2015 Joshua Boyce
// See the upstream COPYING for copying permission.
// Maintenance change: replace repeated system enumeration only; preserve the
// original IsExecutingInRange check, current-thread exclusion and exception.
#pragma once

#include <cstdint>
#include <windows.h>
#include <hadesmem/detail/thread_aux.hpp>
#include <hadesmem/error.hpp>
#include <hadesmem/thread_list.hpp>
#include <hadesmem/thread_helpers.hpp>
#include "startup_metrics.hpp"

namespace hadesmem
{
namespace detail
{
inline void VerifyOnePatchThread(ThreadEntry const& thread_entry, void* target,
                                 std::size_t len,
                                 nampower_maintenance::VerificationMeasurement& measurement)
{
    if (thread_entry.GetId() == ::GetCurrentThreadId()) return;
    measurement.CheckedThread();
    if (IsExecutingInRange(thread_entry, target,
                           static_cast<std::uint8_t*>(target) + len))
    {
        HADESMEM_DETAIL_THROW_EXCEPTION(
            Error{} << ErrorString{"Thread is currently executing patch target."});
    }
}

inline void VerifyPatchThreads(DWORD pid, void* target, std::size_t len)
{
    nampower_maintenance::VerificationMeasurement measurement;
#if NAMP_MAINT_USE_PSS
    nampower_maintenance::ThreadDiagnostics diagnostics;
    std::vector<DWORD> ids;
    try
    {
        ids = nampower_maintenance::EnumerateProcessThreads(
            pid, nampower_maintenance::SystemThreadApi(),
            measurement.Enabled() ? &diagnostics : nullptr);
    }
    catch (std::system_error const& error)
    {
        // Preserve the existing hadesmem error/retry boundary for Toolhelp errors.
        HADESMEM_DETAIL_THROW_EXCEPTION(
            Error{} << ErrorString{"Thread enumeration failed."}
                    << ErrorCodeWinLast{static_cast<DWORD>(error.code().value())});
    }
    measurement.Enumeration(diagnostics);
    for (DWORD const id : ids)
    {
        THREADENTRY32 entry{};
        entry.dwSize = sizeof(entry);
        entry.th32OwnerProcessID = pid;
        entry.th32ThreadID = id;
        VerifyOnePatchThread(ThreadEntry{entry}, target, len, measurement);
    }
#else
    // Diagnostic baseline uses the actual original hadesmem iterator, not an
    // approximation by the new adapter's fallback implementation.
    ThreadList threads{pid};
    for (auto const& thread_entry : threads)
        VerifyOnePatchThread(thread_entry, target, len, measurement);
#endif
}
} // namespace detail
} // namespace hadesmem
