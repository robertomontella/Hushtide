import Foundation
import HealthKit
import Observation

public struct SleepNight: Hashable, Sendable {
    public let day: Date
    public let bedtime: Date
    public let wakeTime: Date
    public let asleepMinutes: Int
    public let inBedMinutes: Int
    public let deepMinutes: Int
    public let remMinutes: Int

    public var efficiency: Double {
        guard inBedMinutes > 0 else { return 0 }
        return min(1, Double(asleepMinutes) / Double(inBedMinutes))
    }
}

public struct HealthWorkout: Hashable, Sendable {
    public let uuid: UUID
    public let localID: UUID?
    public let sportName: String
    public let start: Date
    public let end: Date
    public let durationMinutes: Int
    public let activeKilocalories: Double?
    public let intensity: IntensityLevel
    public let focusArea: String
    public let rpe: Int
    public let notes: String

    public init(
        uuid: UUID,
        localID: UUID? = nil,
        sportName: String,
        start: Date,
        end: Date,
        durationMinutes: Int,
        activeKilocalories: Double? = nil,
        intensity: IntensityLevel,
        focusArea: String,
        rpe: Int,
        notes: String
    ) {
        self.uuid = uuid
        self.localID = localID
        self.sportName = sportName
        self.start = start
        self.end = end
        self.durationMinutes = durationMinutes
        self.activeKilocalories = activeKilocalories
        self.intensity = intensity
        self.focusArea = focusArea
        self.rpe = rpe
        self.notes = notes
    }
}

@Observable
public final class HealthKitManager {

    public private(set) var isAuthorized: Bool = false
    public internal(set) var isSyncing: Bool = false
    public internal(set) var lastSyncDate: Date?
    public private(set) var lastError: String?

    public var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var observationTasks: [Task<Void, Never>] = []

    private enum MetadataKey {
        static let localID = "HushtideLocalID"
        static let sport = "RecoveryAppSport"
        static let intensity = "RecoveryAppIntensity"
        static let focusArea = "RecoveryAppFocusArea"
        static let rpe = "RecoveryAppRPE"
        static let notes = "RecoveryAppNotes"
    }

    private var readTypes: Set<HKObjectType> {
        [
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass),
            HKQuantityType(.height),
            HKCharacteristicType(.biologicalSex),
            HKObjectType.workoutType()
        ]
    }

    private var shareTypes: Set<HKSampleType> {
        [HKObjectType.workoutType()]
    }

    // Resets stored HealthKit authorization flags
    public func resetAuthorization() {
        isAuthorized = false
        lastSyncDate = nil
        lastError = nil
    }

    public init() {}

    // Refreshes HealthKit authorization status without showing UI
    public func refreshAuthorizationStatus() async {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        do {
            let status = try await store.statusForAuthorizationRequest(toShare: shareTypes, read: readTypes)
            isAuthorized = (status == .unnecessary)
        } catch {
            lastError = error.localizedDescription
        }
    }

    @discardableResult
    @MainActor
    // Requests authorization to read and write Apple Health data
    public func requestAuthorization() async -> Bool {
        guard isAvailable else {
            lastError = "Apple Health is not available on this device."
            #if targetEnvironment(simulator) || DEBUG
            isAuthorized = true
            return true
            #else
            return false
            #endif
        }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            lastError = nil
            isAuthorized = true
            return true
        } catch {
            lastError = error.localizedDescription
            print("HealthKit requestAuthorization error: \(error.localizedDescription)")
            #if targetEnvironment(simulator) || DEBUG
            isAuthorized = true
            return true
            #else
            return false
            #endif
        }
    }

    public var canSaveWorkouts: Bool {
        store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    // Observes live updates for sleep and workouts using anchored queries
    public func startObserving(onChange: @escaping @MainActor () -> Void) {
        stopObserving()
        let since = Calendar.current.date(byAdding: .day, value: -14, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: since, end: nil, options: [])
        let store = self.store

        let sleepTask = Task {
            let descriptor = HKAnchoredObjectQueryDescriptor(
                predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
                anchor: nil
            )
            var isFirstBatch = true
            do {
                for try await _ in descriptor.results(for: store) {
                    if isFirstBatch { isFirstBatch = false; continue }
                    await MainActor.run {
                        onChange()
                    }
                }
            } catch {
                print("HealthKit sleep observer stopped: \(error.localizedDescription)")
            }
        }

        let workoutTask = Task {
            let descriptor = HKAnchoredObjectQueryDescriptor(
                predicates: [.workout(predicate)],
                anchor: nil
            )
            var isFirstBatch = true
            do {
                for try await _ in descriptor.results(for: store) {
                    if isFirstBatch { isFirstBatch = false; continue }
                    await MainActor.run {
                        onChange()
                    }
                }
            } catch {
                print("HealthKit workout observer stopped: \(error.localizedDescription)")
            }
        }

        observationTasks = [sleepTask, workoutTask]
    }

    // Stops all active background queries and observers
    public func stopObserving() {
        observationTasks.forEach { $0.cancel() }
        observationTasks = []
    }

    // Fetches aggregated sleep data for a single night ending on the given date
    public func fetchSleepNight(endingOn day: Date) async throws -> SleepNight? {
        let nights = try await fetchSleepNights(from: day, through: day)
        return nights[Calendar.current.startOfDay(for: day)]
    }

    // Fetches aggregated sleep nights within a specified date range
    public func fetchSleepNights(from firstDay: Date, through lastDay: Date) async throws -> [Date: SleepNight] {
        guard isAvailable, isAuthorized else { return [:] }
        let calendar = Calendar.current
        let firstStart = calendar.startOfDay(for: firstDay)
        let lastStart = calendar.startOfDay(for: lastDay)
        guard let windowStart = calendar.date(byAdding: .hour, value: -6, to: firstStart),
              let windowEnd = calendar.date(byAdding: .hour, value: 18, to: lastStart) else { return [:] }

        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: windowEnd, options: [])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let samples = try await descriptor.result(for: store)

        let grouped = Dictionary(grouping: samples) { sample in
            calendar.startOfDay(for: sample.endDate.addingTimeInterval(6 * 3600))
        }

        var result: [Date: SleepNight] = [:]
        for (day, daySamples) in grouped {
            if let night = Self.makeNight(from: daySamples, day: day) {
                result[day] = night
            }
        }
        return result
    }

    // Converts raw HealthKit sleep samples into a structured sleep night
    private static func makeNight(from samples: [HKCategorySample], day: Date) -> SleepNight? {
        var all: [DateInterval] = []
        var asleep: [DateInterval] = []
        var deep: [DateInterval] = []
        var rem: [DateInterval] = []

        for sample in samples where sample.endDate > sample.startDate {
            let interval = DateInterval(start: sample.startDate, end: sample.endDate)
            all.append(interval)
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }
            if HKCategoryValueSleepAnalysis.allAsleepValues.contains(value) {
                asleep.append(interval)
            }
            if value == .asleepDeep { deep.append(interval) }
            if value == .asleepREM { rem.append(interval) }
        }

        guard !all.isEmpty else { return nil }
        let sleepIntervals = asleep.isEmpty ? all : asleep

        guard let bedtime = all.map(\.start).min(),
              let wakeTime = sleepIntervals.map(\.end).max() else { return nil }

        return SleepNight(
            day: day,
            bedtime: bedtime,
            wakeTime: wakeTime,
            asleepMinutes: minutes(of: sleepIntervals),
            inBedMinutes: minutes(of: all),
            deepMinutes: minutes(of: deep),
            remMinutes: minutes(of: rem)
        )
    }

    // Merges overlapping date intervals and calculates total minutes
    private static func minutes(of intervals: [DateInterval]) -> Int {
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [DateInterval] = []
        for interval in sorted {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
        let seconds = merged.reduce(0) { $0 + $1.duration }
        return Int((seconds / 60).rounded())
    }

    // Fetches the most recent sample value for a quantity type
    public func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, since: Date? = nil) async throws -> Double? {
        guard isAvailable, isAuthorized else { return nil }
        let predicate = since.map { HKQuery.predicateForSamples(withStart: $0, end: nil, options: []) }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(identifier), predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        return try await descriptor.result(for: store).first?.quantity.doubleValue(for: unit)
    }

    // Computes the average value of a quantity type over a date range
    public func averageQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, from start: Date, to end: Date) async throws -> Double? {
        guard isAvailable, isAuthorized else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(identifier), predicate: predicate),
            options: .discreteAverage
        )
        return try await descriptor.result(for: store)?.averageQuantity()?.doubleValue(for: unit)
    }

    // Retrieves biological sex from Apple Health profile
    public func biologicalSexDescription() -> String? {
        guard isAvailable, isAuthorized, let sex = try? store.biologicalSex().biologicalSex else { return nil }
        switch sex {
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Non-binary"
        default: return nil
        }
    }

    // Fetches recorded workouts within a date range
    public func fetchWorkouts(from start: Date, to end: Date) async throws -> [HealthWorkout] {
        guard isAvailable, isAuthorized else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        let workouts = try await descriptor.result(for: store)

        return workouts.map { workout in
            let metadata = workout.metadata ?? [:]
            let minutes = max(1, Int((workout.duration / 60).rounded()))
            let kcal = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie())

            let intensity: IntensityLevel = {
                if let raw = metadata[MetadataKey.intensity] as? String,
                   let saved = IntensityLevel(rawValue: raw) {
                    return saved
                }
                return Self.estimateIntensity(kilocalories: kcal, minutes: minutes)
            }()

            let parsedLocalID: UUID? = {
                if let str = (metadata[MetadataKey.localID] as? String) ?? (metadata["RecoveryAppLocalID"] as? String) {
                    return UUID(uuidString: str)
                }
                return nil
            }()

            return HealthWorkout(
                uuid: workout.uuid,
                localID: parsedLocalID,
                sportName: (metadata[MetadataKey.sport] as? String) ?? Self.sportName(for: workout.workoutActivityType),
                start: workout.startDate,
                end: workout.endDate,
                durationMinutes: minutes,
                activeKilocalories: kcal,
                intensity: intensity,
                focusArea: (metadata[MetadataKey.focusArea] as? String) ?? "Full Body",
                rpe: (metadata[MetadataKey.rpe] as? NSNumber)?.intValue ?? intensity.intensityRank * 2 + 1,
                notes: (metadata[MetadataKey.notes] as? String) ?? ""
            )
        }
    }

    // Saves a logged workout to Apple Health and returns its UUID
    public func saveWorkout(
        localID: UUID? = nil,
        sport: String,
        intensity: IntensityLevel,
        start: Date,
        durationMinutes: Int,
        focusArea: String,
        rpe: Int,
        notes: String
    ) async throws -> UUID? {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = Self.activityType(for: sport)
        if configuration.activityType == .swimming {
            configuration.swimmingLocationType = .pool
            configuration.lapLength = HKQuantity(unit: .meter(), doubleValue: 25)
        }

        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())
        let end = start.addingTimeInterval(TimeInterval(max(1, durationMinutes) * 60))

        var metadata: [String: Any] = [
            MetadataKey.sport: sport,
            MetadataKey.intensity: intensity.rawValue,
            MetadataKey.focusArea: focusArea,
            MetadataKey.rpe: NSNumber(value: rpe)
        ]
        if let localID {
            metadata[MetadataKey.localID] = localID.uuidString
            metadata["RecoveryAppLocalID"] = localID.uuidString
        }
        if !notes.isEmpty { metadata[MetadataKey.notes] = notes }

        try await builder.beginCollection(at: start)
        try await builder.addMetadata(metadata)
        try await builder.endCollection(at: end)
        let workout = try await builder.finishWorkout()
        return workout?.uuid
    }

    // Deletes a workout from Apple Health using its UUID
    public func deleteWorkout(uuid: UUID) async throws {
        guard isAvailable, canSaveWorkouts else { return }
        let predicate = HKQuery.predicateForObject(with: uuid)
        _ = try? await store.deleteObjects(of: HKObjectType.workoutType(), predicate: predicate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [],
            limit: 5
        )
        if let samples = try? await descriptor.result(for: store) {
            for sample in samples {
                try? await store.delete(sample)
            }
        }
    }

    // Deletes any workout from Apple Health that matches a local UUID in its metadata
    public func deleteWorkout(localID: UUID) async throws {
        guard isAvailable, canSaveWorkouts else { return }
        let p1 = HKQuery.predicateForObjects(withMetadataKey: MetadataKey.localID, operatorType: .equalTo, value: localID.uuidString)
        let p2 = HKQuery.predicateForObjects(withMetadataKey: "RecoveryAppLocalID", operatorType: .equalTo, value: localID.uuidString)
        let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [p1, p2])
        _ = try? await store.deleteObjects(of: HKObjectType.workoutType(), predicate: compound)
    }

    // Maps a sport name to a HealthKit workout activity type
    public static func activityType(for sport: String) -> HKWorkoutActivityType {
        switch sport {
        case "Powerlifting", "Bodybuilding", "Weightlifting", "Strength Training":
            return .traditionalStrengthTraining
        case "CrossFit": return .crossTraining
        case "Running": return .running
        case "Cycling": return .cycling
        case "Swimming": return .swimming
        case "HIIT": return .highIntensityIntervalTraining
        case "Calisthenics": return .functionalStrengthTraining
        case "Yoga": return .yoga
        case "Mobility": return .flexibility
        default: return .other
        }
    }

    // Maps a HealthKit workout activity type to a sport name
    public static func sportName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Calisthenics"
        case .crossTraining: return "CrossFit"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .flexibility: return "Mobility"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }

    // Estimates workout intensity from calorie burn and duration
    private static func estimateIntensity(kilocalories: Double?, minutes: Int) -> IntensityLevel {
        guard let kcal = kilocalories, minutes > 0 else { return .medium }
        let perMinute = kcal / Double(minutes)
        switch perMinute {
        case ..<4: return .light
        case ..<8: return .medium
        default: return .hard
        }
    }
}
