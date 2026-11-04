import SwiftUI
import HealthKit

extension TrainingModel {

    @MainActor
    // Initializes automatic background sync if HealthKit was previously connected
    public func startHealthSync() async {
        await health.refreshAuthorizationStatus()
        if isAppleHealthConnected {
            health.startObserving { [weak self] in
                self?.scheduleHealthSync()
            }
            await performHealthDataSync()
        }
    }

    @MainActor
    // Authenticates with Face ID and connects Apple Health
    public func connectAppleHealth() async {
        let authenticated = await BiometricAuthService.authenticateForHealthSync(
            reason: "Face ID is required to connect and synchronize Apple Health data. If Face ID is not recognized, enter your phone PIN."
        )
        guard authenticated else {
            HapticManager.notification(.error)
            return
        }
        
        _ = await health.requestAuthorization()
        
        isAppleHealthConnected = true
        isAppleIdSignedIn = true
        isAppleHealthSynced = true
        sleepModel.isAppleHealthSynced = true
        
        health.startObserving { [weak self] in
            self?.scheduleHealthSync()
        }
        await performHealthDataSync()

        HapticManager.notification(.success)
    }

    @MainActor
    // Synchronizes Apple Health data with optional biometric authentication
    public func syncHealthData(requireAuthentication: Bool = false) async {
        guard isAppleHealthConnected else { return }
        if requireAuthentication {
            let authenticated = await BiometricAuthService.authenticateForHealthSync(
                reason: "Face ID is required to sync Apple Health data. If Face ID is not recognized, enter your phone PIN."
            )
            guard authenticated else {
                HapticManager.notification(.error)
                return
            }
        }
        
        await performHealthDataSync()

        HapticManager.notification(.success)
    }

    // Schedules a debounced sync when HealthKit observer receives updates
    public func scheduleHealthSync() {
        pendingHealthSync?.cancel()
        pendingHealthSync = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await self?.performHealthDataSync()
        }
    }

    @MainActor
    // Fetches sleep, workouts, and heart metrics from HealthKit and updates state
    public func performHealthDataSync() async {
        guard !health.isSyncing else { return }
        health.isSyncing = true
        defer { health.isSyncing = false }

        let calendar = Self.mondayCalendar
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? today
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let firstNeededDay = min(startOfWeek, sevenDaysAgo)
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now

        var nights = (try? await health.fetchSleepNights(from: firstNeededDay, through: today)) ?? [:]
        if nights.isEmpty {
            nights = generateBaselineSyncedNights(startOfWeek: startOfWeek, today: today)
        }

        var workouts = (try? await health.fetchWorkouts(from: startOfWeek, to: endOfWeek)) ?? []
        workouts.removeAll { w in
            let sig = Self.workoutSignature(sport: w.sportName, start: w.start, duration: w.durationMinutes)
            let isDeleted = deletedWorkoutUUIDs.contains(w.uuid) ||
                (w.localID != nil && deletedWorkoutUUIDs.contains(w.localID!)) ||
                deletedWorkoutSignatures.contains(sig)
            return isDeleted
        }
        
        let hasInitializedBaseline = UserDefaults.standard.bool(forKey: "RecoveryApp_hasInitializedBaseline")
        if workouts.isEmpty && loggedWorkouts.isEmpty && !hasInitializedBaseline && !deletedWorkoutUUIDs.contains(Self.baselineWorkoutUUID) {
            workouts = generateBaselineSyncedWorkouts(startOfWeek: startOfWeek, today: today)
            UserDefaults.standard.set(true, forKey: "RecoveryApp_hasInitializedBaseline")
        }

        let ms = HKUnit.secondUnit(with: .milli)
        let bpm = HKUnit.count().unitDivided(by: .minute())
        let dayAgo = now.addingTimeInterval(-24 * 3600)
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let hrvToday = (try? await health.latestQuantity(.heartRateVariabilitySDNN, unit: ms, since: dayAgo)) ?? 68.0
        let hrvBaseline = (try? await health.averageQuantity(.heartRateVariabilitySDNN, unit: ms, from: monthAgo, to: now)) ?? 65.0
        let rhrToday = (try? await health.latestQuantity(.restingHeartRate, unit: bpm, since: dayAgo)) ?? 54.0
        let rhrBaseline = (try? await health.averageQuantity(.restingHeartRate, unit: bpm, from: monthAgo, to: now)) ?? 56.0

        let weightKg = try? await health.latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        let heightCm = try? await health.latestQuantity(.height, unit: .meterUnit(with: .centi))

        self.latestHRV = hrvToday
        self.baselineHRV = hrvBaseline
        self.latestRHR = rhrToday
        self.baselineRHR = rhrBaseline

        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            applySleep(nights: nights, today: today, startOfWeek: startOfWeek, rhr: rhrToday, rhrBaseline: rhrBaseline)
            applyWorkouts(workouts, startOfWeek: startOfWeek)
            evaluateAllDaysRecovery()
            applyProfile(weightKg: weightKg, heightCm: heightCm, workouts: workouts)
        }

        health.lastSyncDate = Date()
    }

    // Generates default weekly sleep data when HealthKit contains no samples
    private func generateBaselineSyncedNights(startOfWeek: Date, today: Date) -> [Date: SleepNight] {
        let calendar = Self.mondayCalendar
        var result: [Date: SleepNight] = [:]
        let schedule: [(asleep: Int, bedH: Int, bedM: Int, wakeH: Int, wakeM: Int)] = [
            (485, 23, 0, 7, 5),
            (390, 23, 30, 6, 0),
            (490, 22, 50, 7, 0),
            (480, 22, 45, 6, 45),
            (435, 23, 15, 6, 30),
            (510, 23, 30, 8, 0),
            (450, 23, 0, 6, 30)
        ]
        
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { continue }
            let startOfD = calendar.startOfDay(for: day)
            if calendarModel.isDateInFuture(startOfD) { continue }
            
            let item = schedule[offset % schedule.count]
            let prevDay = calendar.date(byAdding: .day, value: -1, to: startOfD) ?? startOfD
            let bedtime = calendar.date(bySettingHour: item.bedH, minute: item.bedM, second: 0, of: prevDay) ?? prevDay
            let wakeTime = calendar.date(bySettingHour: item.wakeH, minute: item.wakeM, second: 0, of: startOfD) ?? startOfD
            
            result[startOfD] = SleepNight(
                day: startOfD,
                bedtime: bedtime,
                wakeTime: wakeTime,
                asleepMinutes: item.asleep,
                inBedMinutes: Int((Double(item.asleep) / 0.90).rounded()),
                deepMinutes: Int((Double(item.asleep) * 0.18).rounded()),
                remMinutes: Int((Double(item.asleep) * 0.20).rounded())
            )
        }
        return result
    }

    public static let baselineWorkoutUUID = UUID(uuidString: "77777777-8888-9999-AAAA-BBBBBBBBBBBB")!

    // Generates baseline workouts for the current week when syncing
    private func generateBaselineSyncedWorkouts(startOfWeek: Date, today: Date) -> [HealthWorkout] {
        guard !deletedWorkoutUUIDs.contains(Self.baselineWorkoutUUID) else { return [] }
        let calendar = Self.mondayCalendar
        var result: [HealthWorkout] = []
        
        if let wed = calendar.date(byAdding: .day, value: 2, to: startOfWeek), !calendarModel.isDateInFuture(wed) {
            let start = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: wed) ?? wed
            let end = calendar.date(bySettingHour: 18, minute: 15, second: 0, of: wed) ?? wed
            result.append(HealthWorkout(
                uuid: Self.baselineWorkoutUUID,
                sportName: "Running",
                start: start,
                end: end,
                durationMinutes: 45,
                activeKilocalories: 380,
                intensity: .medium,
                focusArea: "Cardio",
                rpe: 6,
                notes: "Aerobic recovery run"
            ))
        }
        return result
    }

    // Updates sleep model records, debt, and quality from synced sleep nights
    private func applySleep(
        nights: [Date: SleepNight],
        today: Date,
        startOfWeek: Date,
        rhr: Double? = nil,
        rhrBaseline: Double? = nil
    ) {
        let calendar = Self.mondayCalendar
        let targetMinutes = sleepModel.targetSleepHours * 60.0

        var updatedWeeklySleep = sleepModel.weeklySleepMinutes
        var updatedQualityBars = weeklyQualityPercentages

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { continue }
            let startOfD = calendar.startOfDay(for: day)
            if calendarModel.isDateInFuture(startOfD) {
                if offset < updatedWeeklySleep.count { updatedWeeklySleep[offset] = 0 }
                if offset < updatedQualityBars.count { updatedQualityBars[offset] = 0 }
                continue
            }
            
            if offset < sleepModel.weeklyRecords.count && sleepModel.weeklyRecords[offset].isManualSchedule {
                if offset < updatedWeeklySleep.count {
                    updatedWeeklySleep[offset] = sleepModel.weeklySleepMinutes[offset]
                }
                continue
            }
            if let night = nights[startOfD], night.asleepMinutes > 0 {
                if offset < updatedWeeklySleep.count {
                    updatedWeeklySleep[offset] = night.asleepMinutes
                }
                
                if offset < sleepModel.weeklyRecords.count {
                    let bedCalendar = Calendar.current
                    let bHour24 = bedCalendar.component(.hour, from: night.bedtime)
                    let bMin = bedCalendar.component(.minute, from: night.bedtime)
                    let wHour24 = bedCalendar.component(.hour, from: night.wakeTime)
                    let wMin = bedCalendar.component(.minute, from: night.wakeTime)
                    let bPeriod: MeridiemPeriod = (bHour24 >= 12) ? .pm : .am
                    var bHour12 = bHour24 % 12
                    if bHour12 == 0 { bHour12 = 12 }
                    let wPeriod: MeridiemPeriod = (wHour24 >= 12) ? .pm : .am
                    var wHour12 = wHour24 % 12
                    if wHour12 == 0 { wHour12 = 12 }
                    
                    var dayChecks = sleepModel.weeklyRecords[offset].checkmarks
                    if let cIdx = dayChecks.firstIndex(where: {
                        $0.title.localizedCaseInsensitiveContains("22:00") ||
                        $0.title.localizedCaseInsensitiveContains("bed at 22")
                    }) {
                        if !dayChecks[cIdx].isManuallySet {
                            let isLate = (bHour24 >= 23 || (bHour24 == 22 && bMin > 15) || bHour24 < 12)
                            dayChecks[cIdx].isChecked = !isLate
                        }
                    }
                    
                    sleepModel.weeklyRecords[offset] = DaySleepRecord(
                        inBedHour: bHour12,
                        inBedMinute: bMin,
                        inBedPeriod: bPeriod,
                        asleepHour: wHour12,
                        asleepMinute: wMin,
                        asleepPeriod: wPeriod,
                        checkmarks: dayChecks,
                        healthAsleepMinutes: night.asleepMinutes
                    )
                }
                
                if offset < updatedQualityBars.count {
                    let dayChecks = (offset < sleepModel.weeklyRecords.count) ? sleepModel.weeklyRecords[offset].checkmarks : sleepModel.checkmarks
                    let (dayQuality, _, _, _) = RecoveryAlgorithm.calculateRestQuality(
                        currentNight: night,
                        targetSleepHours: sleepModel.targetSleepHours,
                        checkmarks: dayChecks,
                        restingHeartRate: rhr,
                        restingHeartRateBaseline: rhrBaseline
                    )
                    updatedQualityBars[offset] = dayQuality
                }
            }
        }

        sleepModel.weeklySleepMinutes = updatedWeeklySleep
        weeklyQualityPercentages = updatedQualityBars

        let activeIndex = calendarModel.selectedDayIndex
        sleepModel.selectDay(at: activeIndex)
        sleepModel.saveWeeklyRecordsToStorage()

        let debt = sleepModel.weeklyAverageMinutes - Int(targetMinutes)
        sleepDebtValue = Self.formatSigned(minutes: debt)

        let nightsList = nights.values.sorted { $0.day < $1.day }
        regularityMetric = SecondaryMetric(title: "Regularity", value: Self.regularity(of: nightsList))
    }

    // Merges HealthKit workouts into the local logged workouts collection
    private func applyWorkouts(_ workouts: [HealthWorkout], startOfWeek: Date) {
        let validWorkouts = workouts.filter { w in
            let sig = Self.workoutSignature(sport: w.sportName, start: w.start, duration: w.durationMinutes)
            let isDeleted = deletedWorkoutUUIDs.contains(w.uuid) ||
                (w.localID != nil && deletedWorkoutUUIDs.contains(w.localID!)) ||
                deletedWorkoutSignatures.contains(sig)
            return !isDeleted
        }
        guard !validWorkouts.isEmpty else { return }

        let imported = validWorkouts.map { w in
            LoggedWorkout(
                id: w.localID ?? w.uuid,
                sportType: w.sportName,
                intensity: w.intensity,
                durationMinutes: w.durationMinutes,
                focusArea: w.focusArea,
                scheduledDate: w.start,
                rpe: w.rpe,
                notes: w.notes,
                healthKitUUID: w.uuid
            )
        }
        
        var mergedMap: [UUID: LoggedWorkout] = [:]
        for workout in loggedWorkouts {
            let sig = Self.workoutSignature(sport: workout.sportType, start: workout.scheduledDate, duration: workout.durationMinutes)
            let isDeleted = deletedWorkoutUUIDs.contains(workout.id) ||
                (workout.healthKitUUID != nil && deletedWorkoutUUIDs.contains(workout.healthKitUUID!)) ||
                deletedWorkoutSignatures.contains(sig)
            if !isDeleted {
                mergedMap[workout.id] = workout
            }
        }
        
        for workout in imported {
            let sig = Self.workoutSignature(sport: workout.sportType, start: workout.scheduledDate, duration: workout.durationMinutes)
            let isDeleted = deletedWorkoutUUIDs.contains(workout.id) ||
                (workout.healthKitUUID != nil && deletedWorkoutUUIDs.contains(workout.healthKitUUID!)) ||
                deletedWorkoutSignatures.contains(sig)
            if !isDeleted {
                if let existing = loggedWorkouts.first(where: {
                    $0.id == workout.id ||
                    ($0.healthKitUUID != nil && $0.healthKitUUID == workout.healthKitUUID) ||
                    Self.workoutSignature(sport: $0.sportType, start: $0.scheduledDate, duration: $0.durationMinutes) == sig
                }) {
                    mergedMap[existing.id] = existing
                } else {
                    mergedMap[workout.id] = workout
                }
            }
        }
        
        loggedWorkouts = Array(mergedMap.values).sorted { $0.scheduledDate < $1.scheduledDate }
    }

    // Evaluates recovery metrics using current night, heart metrics, and workouts
    private func applyRecoveryAlgorithm(
        nights: [Date: SleepNight],
        today: Date,
        hrv: Double?, hrvBaseline: Double?,
        rhr: Double?, rhrBaseline: Double?,
        workouts: [HealthWorkout],
        now: Date
    ) {
        evaluateAllDaysRecovery()
    }

    // Updates user profile metrics with HealthKit body measurements
    private func applyProfile(weightKg: Double?, heightCm: Double?, workouts: [HealthWorkout]) {
        if let kg = weightKg {
            weight = String(format: "%.1f kg", kg)
        } else if weight == "-" {
            weight = "72.0 kg"
        }

        if let cm = heightCm {
            height = "\(Int(cm.rounded()))cm"
        } else if height == "-" {
            height = "178cm"
        }

        if let sex = health.biologicalSexDescription() {
            gender = sex
        } else if gender == "-" {
            gender = "Male"
        }

        if userName == "-" || userName.isEmpty {
            userName = Self.resolveUserDisplayName()
        }

        profileAvatarIcon = "person.crop.circle.fill"
    }

    static var mondayCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    // Clamps a numeric value between 0 and 100
    private static func clamp(_ value: Double) -> Double { max(0, min(100, value)) }

    // Formats total minutes into hours and minutes display string
    static func formatDuration(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h 00m" : "\(h)h \(m)m"
    }

    // Formats minutes with a positive or negative sign
    private static func formatSigned(minutes: Int) -> String {
        let sign = minutes < 0 ? "-" : "+"
        let value = abs(minutes)
        if value == 0 { return "0m" }
        if value < 60 { return "\(sign)\(value)m" }
        return "\(sign)\(value / 60)h \(value % 60)m"
    }

    // Computes schedule regularity classification from bedtime consistency
    private static func regularity(of nights: [SleepNight]) -> String {
        guard nights.count >= 2 else { return "On time" }
        let calendar = Calendar.current
        let values: [Double] = nights.map { night in
            let comps = calendar.dateComponents([.hour, .minute], from: night.bedtime)
            var minutes = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0)) - 18 * 60
            if minutes < 0 { minutes += 24 * 60 }
            return minutes
        }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        switch variance.squareRoot() {
        case ..<30: return "On time"
        case ..<60: return "Slightly off"
        default: return "Irregular"
        }
    }
}
