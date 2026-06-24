import Foundation
import Combine
#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - Value types (shared with AutoModeEngine)

/// A snapshot of the metrics Automatic Mode looks at. All optional — a phone with
/// no Apple Watch may have steps but no HRV, etc.
struct HealthReadings: Codable {
    var hrvSDNN: Double?      // ms
    var restingHR: Double?    // bpm
    var moveKcal: Double?     // active energy today
    var exerciseMin: Double?  // exercise minutes today
    var steps: Double?        // steps today
    var asOf: Date

    static let empty = HealthReadings(hrvSDNN: nil, restingHR: nil, moveKcal: nil,
                                      exerciseMin: nil, steps: nil, asOf: Date())
}

/// A personal baseline (robust median + MAD) computed over a rolling window so the
/// heuristic compares you to *you*, not population norms.
struct HealthBaseline: Codable {
    var hrvMedian: Double?
    var hrvMAD: Double?
    var restingHRMedian: Double?
    var restingHRMAD: Double?
    var moveMedian: Double?
    var stepsMedian: Double?
    var computedAt: Date
    var sampleDays: Int

    static let empty = HealthBaseline(hrvMedian: nil, hrvMAD: nil, restingHRMedian: nil,
                                      restingHRMAD: nil, moveMedian: nil, stepsMedian: nil,
                                      computedAt: .distantPast, sampleDays: 0)
}

/// Thin wrapper over HealthKit. Knows nothing about blocking — it just supplies
/// readings + a baseline. Degrades gracefully like `ScreenTimeManager`: on a
/// device without HealthKit (iPad/sim) it stays unavailable and never crashes.
@MainActor
final class HealthManager: ObservableObject {
    enum Status { case unavailable, notDetermined, denied, authorized }

    @Published private(set) var status: Status = .notDetermined

    static let baselineDays = 14

    private let defaults = UserDefaults(suiteName: RinklerConstants.appGroupID)

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.stepCount),
        ]
        types.insert(HKCategoryType(.sleepAnalysis))
        return types
    }
    #endif

    init() {
        refreshAvailability()
    }

    var isAvailable: Bool { status != .unavailable }
    var isAuthorized: Bool { status == .authorized }

    func refreshAvailability() {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { status = .unavailable; return }
        // HealthKit deliberately never reveals read authorization, so we infer
        // "authorized" from a stored flag we set after a successful request, and
        // otherwise show the priming/Grant path.
        if defaults?.bool(forKey: "health.didAuthorize") == true {
            status = .authorized
        } else {
            status = .notDetermined
        }
        #else
        status = .unavailable
        #endif
    }

    /// Triggers the Health permission sheet. Returns true if the request itself
    /// succeeded (HealthKit hides whether the user said yes to reads).
    @discardableResult
    func requestAuthorization() async -> Bool {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { status = .unavailable; return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            defaults?.set(true, forKey: "health.didAuthorize")
            status = .authorized
            return true
        } catch {
            status = .denied
            return false
        }
        #else
        status = .unavailable
        return false
        #endif
    }

    // MARK: - Readings

    func latestReadings() async -> HealthReadings {
        #if canImport(HealthKit)
        async let hrv = latestQuantity(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli))
        async let rhr = latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let move = todaySum(.activeEnergyBurned, unit: .kilocalorie())
        async let exercise = todaySum(.appleExerciseTime, unit: .minute())
        async let steps = todaySum(.stepCount, unit: .count())
        return await HealthReadings(hrvSDNN: hrv, restingHR: rhr, moveKcal: move,
                                    exerciseMin: exercise, steps: steps, asOf: Date())
        #else
        return .empty
        #endif
    }

    /// Recomputes the personal baseline over the rolling window (median + MAD).
    func recomputeBaseline() async -> HealthBaseline {
        #if canImport(HealthKit)
        async let hrvSamples = samples(.heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), days: Self.baselineDays)
        async let rhrSamples = samples(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), days: Self.baselineDays)
        async let moveDaily = dailySums(.activeEnergyBurned, unit: .kilocalorie(), days: Self.baselineDays)
        async let stepDaily = dailySums(.stepCount, unit: .count(), days: Self.baselineDays)

        let hrv = await hrvSamples, rhr = await rhrSamples
        let move = await moveDaily, steps = await stepDaily
        let dayCount = max(move.count, hrv.isEmpty ? 0 : Self.baselineDays)

        let baseline = HealthBaseline(
            hrvMedian: median(hrv), hrvMAD: mad(hrv),
            restingHRMedian: median(rhr), restingHRMAD: mad(rhr),
            moveMedian: median(move), stepsMedian: median(steps),
            computedAt: Date(), sampleDays: dayCount
        )
        if let data = try? JSONEncoder().encode(baseline) {
            defaults?.set(data, forKey: RinklerConstants.autoModeBaselineKey)
        }
        return baseline
        #else
        return .empty
        #endif
    }

    func cachedBaseline() -> HealthBaseline {
        guard let data = defaults?.data(forKey: RinklerConstants.autoModeBaselineKey),
              let b = try? JSONDecoder().decode(HealthBaseline.self, from: data) else { return .empty }
        return b
    }

    #if canImport(HealthKit)
    // MARK: - HealthKit query helpers

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(id)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: sort) { _, samples, _ in
                let v = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                cont.resume(returning: v)
            }
            store.execute(q)
        }
    }

    private func todaySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        let type = HKQuantityType(id)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func samples(_ id: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async -> [Double] {
        let type = HKQuantityType(id)
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, _ in
                let values = (samples as? [HKQuantitySample])?.map { $0.quantity.doubleValue(for: unit) } ?? []
                cont.resume(returning: values)
            }
            store.execute(q)
        }
    }

    private func dailySums(_ id: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async -> [Double] {
        let type = HKQuantityType(id)
        let cal = Calendar.current
        let anchor = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -days, to: anchor) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate,
                                                options: .cumulativeSum, anchorDate: anchor,
                                                intervalComponents: DateComponents(day: 1))
            q.initialResultsHandler = { _, collection, _ in
                var out: [Double] = []
                collection?.enumerateStatistics(from: start, to: Date()) { stat, _ in
                    if let v = stat.sumQuantity()?.doubleValue(for: unit) { out.append(v) }
                }
                cont.resume(returning: out)
            }
            store.execute(q)
        }
    }

    /// Registers an observer + hourly background delivery for HRV so iOS wakes the
    /// app when new readings land. The handler is supplied by the coordinator.
    func enableBackgroundDelivery(onUpdate: @escaping () async -> Void) {
        guard isAuthorized else { return }
        let type = HKQuantityType(.heartRateVariabilitySDNN)
        let observer = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, _ in
            Task { await onUpdate(); completion() }
        }
        store.execute(observer)
        store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
    }
    #endif

    // MARK: - Robust statistics

    private func median(_ xs: [Double]) -> Double? {
        guard !xs.isEmpty else { return nil }
        let s = xs.sorted()
        let n = s.count
        return n % 2 == 1 ? s[n / 2] : (s[n / 2 - 1] + s[n / 2]) / 2
    }

    /// Median absolute deviation — robust spread, scaled to ~1σ for normal data.
    private func mad(_ xs: [Double]) -> Double? {
        guard let m = median(xs) else { return nil }
        let devs = xs.map { abs($0 - m) }
        guard let d = median(devs) else { return nil }
        return d * 1.4826
    }
}
