import Foundation
#if canImport(DeviceActivity)
import DeviceActivity
#endif

/// Schedules the Strict Mode window with DeviceActivity so it auto-lifts at the
/// end even if the app is never reopened — the paired DeviceActivityMonitor
/// extension's `intervalDidEnd` clears the shield. Gated like the shield
/// controller: only invoked when Screen Time access is granted, and the whole
/// body compiles to a no-op without the framework/entitlement.
///
/// NOTE: a same-day window is the common case; a cross-midnight window is handled
/// by DeviceActivitySchedule's wrap-around. The monitor extension that receives
/// `intervalDidEnd` is added in the entitlement-gated phase.
final class StrictModeActivityScheduler {
    #if canImport(DeviceActivity)
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("rinkler.strict")
    #endif

    func start(until end: Date) {
        #if canImport(DeviceActivity)
        let cal = Calendar.current
        let start = cal.dateComponents([.hour, .minute], from: Date())
        let endComps = cal.dateComponents([.hour, .minute], from: end)
        let schedule = DeviceActivitySchedule(intervalStart: start, intervalEnd: endComps, repeats: false)
        try? center.startMonitoring(activityName, during: schedule)
        #endif
    }

    func stop() {
        #if canImport(DeviceActivity)
        center.stopMonitoring([activityName])
        #endif
    }
}
