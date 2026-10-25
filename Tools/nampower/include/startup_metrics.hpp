#pragma once

// Startup-only counters: no formatting or allocation inside patch verification.
// The original and PSS candidates use the same measurements. Inactive probes
// do not read QPC, and profiling never changes patching or thread state.
#include "process_threads.hpp"
#include <array>

#ifndef NAMP_MAINT_PROFILE
#define NAMP_MAINT_PROFILE 1
#endif
#ifndef NAMP_MAINT_USE_PSS
#define NAMP_MAINT_USE_PSS 0
#endif

namespace nampower_maintenance
{
struct StartupCounters
{
    std::uint64_t verify_calls = 0, verify_ticks = 0, thread_checks = 0;
    std::uint64_t enum_ticks = 0, enum_samples = 0, pss_calls = 0, fallback_calls = 0;
    std::uint64_t pss_entries = 0, toolhelp_entries = 0;
    DWORD last_pss_error = 0, last_cleanup_error = 0;
};

struct HookRecord
{
    DWORD offset = 0;
    unsigned attempts = 0;
    bool success = false;
    std::uint64_t ticks = 0;
    StartupCounters delta;
};

inline std::uint64_t StartupTick() noexcept
{
    LARGE_INTEGER value{};
    return ::QueryPerformanceCounter(&value)
        ? static_cast<std::uint64_t>(value.QuadPart) : 0;
}

inline double StartupMilliseconds(std::uint64_t ticks) noexcept
{
    LARGE_INTEGER frequency{};
    return ::QueryPerformanceFrequency(&frequency) && frequency.QuadPart > 0
        ? 1000.0 * static_cast<double>(ticks) / frequency.QuadPart : 0.0;
}

constexpr std::uint64_t StartupElapsed(std::uint64_t begin, std::uint64_t end) noexcept
{
    return begin && end >= begin ? end - begin : 0;
}
static_assert(StartupElapsed(0, 100) == 0, "Failed begin timestamp must not produce a duration");
static_assert(StartupElapsed(100, 0) == 0, "Failed end timestamp must not underflow");
static_assert(StartupElapsed(100, 99) == 0, "Clock reversal must not underflow");
static_assert(StartupElapsed(100, 150) == 50, "Normal duration must be preserved");

class StartupSession;
inline StartupSession*& ActiveStartupSession() noexcept
{
    static thread_local StartupSession* current = nullptr;
    return current;
}

class StartupSession
{
public:
    StartupSession() noexcept : previous_(ActiveStartupSession())
    {
#if NAMP_MAINT_PROFILE
        begin_ = StartupTick();
        ActiveStartupSession() = this;
#endif
    }
    ~StartupSession() noexcept { ActiveStartupSession() = previous_; }
    StartupSession(StartupSession const&) = delete;
    StartupSession& operator=(StartupSession const&) = delete;
    void Finish() noexcept
    {
        if (begin_) ticks_ = StartupElapsed(begin_, StartupTick());
    }
    void Add(HookRecord const& record) noexcept
    {
        if (count_ < records_.size()) records_[count_++] = record;
        else ++dropped_;
    }
    std::size_t Size() const noexcept { return count_; }
    HookRecord const& Record(std::size_t index) const noexcept { return records_[index]; }
    std::uint64_t Ticks() const noexcept { return ticks_; }
    std::size_t Dropped() const noexcept { return dropped_; }
    StartupCounters counters;
private:
    StartupSession* previous_;
    std::uint64_t begin_ = 0, ticks_ = 0;
    std::array<HookRecord, 128> records_{};
    std::size_t count_ = 0, dropped_ = 0;
};

inline StartupCounters Difference(StartupCounters const& end,
                                  StartupCounters const& begin) noexcept
{
    StartupCounters result;
#define NAMP_COUNTER_DIFF(field) result.field = end.field - begin.field
    NAMP_COUNTER_DIFF(verify_calls); NAMP_COUNTER_DIFF(verify_ticks);
    NAMP_COUNTER_DIFF(thread_checks); NAMP_COUNTER_DIFF(enum_ticks);
    NAMP_COUNTER_DIFF(enum_samples);
    NAMP_COUNTER_DIFF(pss_calls); NAMP_COUNTER_DIFF(fallback_calls);
    NAMP_COUNTER_DIFF(pss_entries); NAMP_COUNTER_DIFF(toolhelp_entries);
#undef NAMP_COUNTER_DIFF
    result.last_pss_error = end.last_pss_error;
    result.last_cleanup_error = end.last_cleanup_error;
    return result;
}

class HookMeasurement
{
public:
    explicit HookMeasurement(DWORD offset) noexcept : session_(ActiveStartupSession())
    {
        record_.offset = offset;
        if (session_) { before_ = session_->counters; begin_ = StartupTick(); }
    }
    ~HookMeasurement() noexcept
    {
        if (session_)
        {
            record_.ticks = StartupElapsed(begin_, StartupTick());
            record_.delta = Difference(session_->counters, before_);
            session_->Add(record_);
        }
    }
    void Attempt(unsigned value) noexcept { record_.attempts = value; }
    void Succeeded() noexcept { record_.success = true; }
private:
    StartupSession* session_;
    std::uint64_t begin_ = 0;
    StartupCounters before_;
    HookRecord record_;
};

class VerificationMeasurement
{
public:
    VerificationMeasurement() noexcept : session_(ActiveStartupSession())
    {
        if (session_) begin_ = StartupTick();
    }
    ~VerificationMeasurement() noexcept
    {
        if (session_)
        {
            ++session_->counters.verify_calls;
            session_->counters.verify_ticks += StartupElapsed(begin_, StartupTick());
            session_->counters.thread_checks += checks_;
        }
    }
    bool Enabled() const noexcept { return session_ != nullptr; }
    void CheckedThread() noexcept { ++checks_; }
    void Enumeration(ThreadDiagnostics const& diagnostics) noexcept
    {
        if (!session_) return;
        auto& counters = session_->counters;
        ++counters.enum_samples;
        counters.enum_ticks += diagnostics.total_ticks;
        counters.pss_entries += diagnostics.pss_entries;
        counters.toolhelp_entries += diagnostics.toolhelp_entries;
        if (diagnostics.backend == ThreadBackend::process_snapshot) ++counters.pss_calls;
        else ++counters.fallback_calls;
        if (diagnostics.pss_error) counters.last_pss_error = diagnostics.pss_error;
        if (diagnostics.cleanup_error) counters.last_cleanup_error = diagnostics.cleanup_error;
    }
private:
    StartupSession* session_;
    std::uint64_t begin_ = 0, checks_ = 0;
};
} // namespace nampower_maintenance
