#include "startup_metrics.hpp"
#include <cstdio>
#include <stdexcept>

using namespace nampower_maintenance;
static void Require(bool value) { if (!value) throw std::runtime_error("metrics assertion failed"); }
int main()
{
    try
    {
        Require(StartupElapsed(0, 99) == 0);
        Require(StartupElapsed(99, 0) == 0);
        Require(StartupElapsed(99, 98) == 0);
        Require(StartupElapsed(99, 99) == 0);
        Require(StartupElapsed(99, 101) == 2);
        Require(ActiveStartupSession() == nullptr);
        {
            StartupSession outer;
#if NAMP_MAINT_PROFILE
            Require(ActiveStartupSession() == &outer);
            {
                StartupSession nested;
                Require(ActiveStartupSession() == &nested);
            }
            Require(ActiveStartupSession() == &outer);
            {
                HookMeasurement hook(0x1234);
                hook.Attempt(2);
                VerificationMeasurement verify;
                verify.CheckedThread();
                ThreadDiagnostics d;
                d.backend = ThreadBackend::process_snapshot;
                d.pss_entries = 2;
                d.total_ticks = 10;
                verify.Enumeration(d);
                hook.Succeeded();
            }
            Require(outer.Size() == 1 && outer.Record(0).success);
            Require(outer.Record(0).offset == 0x1234 && outer.Record(0).attempts == 2);
            Require(outer.counters.verify_calls == 1 && outer.counters.thread_checks == 1);
            Require(outer.counters.enum_samples == 1 && outer.counters.pss_calls == 1);
            try { HookMeasurement failed(0x5678); throw std::runtime_error("expected"); }
            catch (std::runtime_error const&) {}
            Require(outer.Size() == 2 && !outer.Record(1).success);
            for (unsigned i = 0; i < 140; ++i) outer.Add(HookRecord{});
            Require(outer.Size() == 128 && outer.Dropped() == 14);
#else
            Require(ActiveStartupSession() == nullptr);
            HookMeasurement hook(0x1234);
            VerificationMeasurement verify;
            verify.CheckedThread();
            hook.Succeeded();
            Require(outer.Size() == 0 && outer.counters.verify_calls == 0);
#endif
            outer.Finish();
        }
        Require(ActiveStartupSession() == nullptr);
        std::printf("metrics_pass profile=%d clock_edges/nesting/unwind/capacity\n", NAMP_MAINT_PROFILE);
        return 0;
    }
    catch (std::exception const& e) { std::printf("metrics_fail %s\n", e.what()); return 1; }
}
