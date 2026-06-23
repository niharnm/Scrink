import SwiftUI
#if canImport(DeviceActivity)
import DeviceActivity
#endif

#if canImport(DeviceActivity)
extension DeviceActivityReport.Context {
    static let rinklerUsage = Self(rawValue: "rinklerUsage")
}
#endif

/// Hosts the DeviceActivity report (real per-app screen time for today). The
/// numbers are computed in the RinklerActivityReport extension and rendered
/// out-of-process inside this view. Requires Screen Time authorization.
struct UsageReportView: View {
    #if canImport(DeviceActivity)
    @State private var filter = DeviceActivityFilter(
        segment: .daily(
            during: Calendar.current.dateInterval(of: .day, for: Date())
                ?? DateInterval(start: Date(), duration: 86_400)
        ),
        users: .all,
        devices: .init([.iPhone])
    )
    #endif

    var body: some View {
        #if canImport(DeviceActivity)
        DeviceActivityReport(.rinklerUsage, filter: filter)
        #else
        EmptyView()
        #endif
    }
}
