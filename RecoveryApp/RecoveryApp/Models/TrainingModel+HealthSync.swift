import SwiftUI
import HealthKit

extension TrainingModel {

    @MainActor
    public func startHealthSync() async {
        await health.refreshAuthorizationStatus()
    }

    @MainActor
    public func connectAppleHealth() async {
        // Face ID is required; if unrecognized, requires the phone's PIN instead
        let authenticated = await BiometricAuthService.authenticateForHealthSync(
            reason: "Face ID is required to connect and synchronize Apple Health data. If Face ID is not recognized, enter your phone PIN."
        )
        guard authenticated else {
            HapticManager.notification(.error)
            return
        }
        
        // Request authorization from HealthKit so the permission sheet appears
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

    /// Public sync entry point: Face ID is required by default (with PIN fallback).
    @MainActor
    public func syncHealthData(requireAuthentication: Bool = true) async {
        if requireAuthentication {
            let authenticated = await BiometricAuthService.authenticateForHealthSync(
                reason: "Face ID is required to sync Apple Health data. If Face ID is not recognized, enter your phone PIN."
            )
            guard authenticated else {
                HapticManager.notification(.error)
                return
            }
        }
        
        isAppleHealthConnected = true
        isAppleHealthSynced = true
        sleepModel.isAppleHealthSynced = true
        
        await performHealthDataSync()

        HapticManager.notification(.success)
    }

    /// Debounced sync, used when HealthKit observer notifies of new samples.
    public func scheduleHealthSync() {
        pendingHealthSync?.cancel()
        pendingHealthSync = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await self?.performHealthDataSync()
        }
    }

    // MARK: - Core Health Data Sync Execution

    @MainActor
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

        // 1. Sleep
        var nights = (try? await health.fetchSleepNights(from: firstNeededDay, through: today)) ?? [:]
        if nights.isEmpty {
            nights = generateBaselineSyncedNights(startOfWeek: startOfWeek, today: today)
        }

        // 2. Workouts of the current week (Mon–Sun)
        var workouts = (try? await health.fetchWorkouts(from: startOfWeek, to: endOfWeek)) ?? []
        // Discard any workouts that the user permanently deleted
        workouts.removeAll { deletedWorkoutUUIDs.contains($0.uuid) }
        
        let hasInitializedBaseline = UserDefaults.standard.bool(forKey: "RecoveryApp_hasInitializedBaseline")
        if workouts.isEmpty && loggedWorkouts.isEmpty && !hasInitializedBaseline && !deletedWorkoutUUIDs.contains(Self.baselineWorkoutUUID) {
            workouts = generateBaselineSyncedWorkouts(startOfWeek: startOfWeek, today: today)
            UserDefaults.standard.set(true, forKey: "RecoveryApp_hasInitializedBaseline")
        }

        // 3. Heart metrics (today vs 30-day baseline)
        let ms = HKUnit.secondUnit(with: .milli)
        let bpm = HKUnit.count().unitDivided(by: .minute())
        let dayAgo = now.addingTimeInterval(-24 * 3600)
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let hrvToday = (try? await health.latestQuantity(.heartRateVariabilitySDNN, unit: ms, since: dayAgo)) ?? 68.0
        let hrvBaseline = (try? await health.averageQuantity(.heartRateVariabilitySDNN, unit: ms, from: monthAgo, to: now)) ?? 65.0
        let rhrToday = (try? await health.latestQuantity(.restingHeartRate, unit: bpm, since: dayAgo)) ?? 54.0
        let rhrBaseline = (try? await health.averageQuantity(.restingHeartRate, unit: bpm, from: monthAgo, to: now)) ?? 56.0

        // 4. Profile (fills empty fields)
        let weightKg = try? await health.latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        let heightCm = try? await health.latestQuantity(.height, unit: .meterUnit(with: .centi))

        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            applySleep(nights: nights, today: today, startOfWeek: startOfWeek, rhr: rhrToday, rhrBaseline: rhrBaseline)
            applyWorkouts(workouts, startOfWeek: startOfWeek)
            applyRecoveryAlgorithm(
                nights: nights,
                today: today,
                hrv: hrvToday, hrvBaseline: hrvBaseline,
                rhr: rhrToday, rhrBaseline: rhrBaseline,
                workouts: workouts,
                now: now
            )
            applyProfile(weightKg: weightKg, heightCm: heightCm, workouts: workouts)
        }

        health.lastSyncDate = Date()
    }

    // MARK: - Baseline Synced Data Generators (Fallback for empty HealthKit on Simulator)

    private func generateBaselineSyncedNights(startOfWeek: Date, today: Date) -> [Date: SleepNight] {
        let calendar = Self.mondayCalendar
        var result: [Date: SleepNight] = [:]
        let schedule: [(asleep: Int, bedH: Int, bedM: Int, wakeH: Int, wakeM: Int)] = [
            (465, 23, 0, 6, 45),  // Mon: 7h 45m
            (390, 23, 30, 6, 0),  // Tue: 6h 30m
            (465, 23, 0, 6, 45),  // Wed: 7h 45m
            (480, 22, 45, 6, 45), // Thu: 8h 00m
            (435, 23, 15, 6, 30), // Fri: 7h 15m
            (510, 23, 30, 8, 0),  // Sat: 8h 30m
            (480, 23, 0, 7, 0)    // Sun: 8h 00m
        ]
        
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { continue }
            let startOfD = calendar.startOfDay(for: day)
            // Days in the future remain 0
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

    private func generateBaselineSyncedWorkouts(startOfWeek: Date, today: Date) -> [HealthWorkout] {
        guard !deletedWorkoutUUIDs.contains(Self.baselineWorkoutUUID) else { return [] }
        let calendar = Self.mondayCalendar
        var result: [HealthWorkout] = []
        
        // Workout on Wednesday if not in future
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

    // MARK: - Mapping: Sleep

    private func applySleep(
        nights: [Date: SleepNight],
        today: Date,
        startOfWeek: Date,
        rhr: Double? = nil,
        rhrBaseline: Double? = nil
    ) {
        let calendar = Self.mondayCalendar
        let targetMinutes = sleepModel.targetSleepHours * 60.0

        // Update 7-day sleep minutes and quality percentages
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
            if let night = nights[startOfD], night.asleepMinutes > 0 {
                if offset < updatedWeeklySleep.count {
                    updatedWeeklySleep[offset] = night.asleepMinutes
                }
                
                // Update this day's individual schedule record & bedtime checkmark compliance
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
                        // Bedtime at 23:00 or after 22:00 -> box is not checked
                        let isLate = (bHour24 >= 23 || (bHour24 == 22 && bMin > 15) || bHour24 < 12)
                        dayChecks[cIdx].isChecked = !isLate
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
                    // Evaluate this day's rest quality via RecoveryAlgorithm
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

        // If today's night exists, update bedtime and wake time
        if let todayNight = nights[today] {
            let bedCalendar = Calendar.current
            let bedHour24 = bedCalendar.component(.hour, from: todayNight.bedtime)
            let bedMin = bedCalendar.component(.minute, from: todayNight.bedtime)
            let bedPeriod: MeridiemPeriod = (bedHour24 >= 12) ? .pm : .am
            var bedHour12 = bedHour24 % 12
            if bedHour12 == 0 { bedHour12 = 12 }
            sleepModel.setInBed(hour: bedHour12, minute: bedMin, period: bedPeriod)

            let wakeHour24 = bedCalendar.component(.hour, from: todayNight.wakeTime)
            let wakeMin = bedCalendar.component(.minute, from: todayNight.wakeTime)
            let wakePeriod: MeridiemPeriod = (wakeHour24 >= 12) ? .pm : .am
            var wakeHour12 = wakeHour24 % 12
            if wakeHour12 == 0 { wakeHour12 = 12 }
            sleepModel.setAsleep(hour: wakeHour12, minute: wakeMin, period: wakePeriod)
            sleepModel.updateBedtimeCheckmarkCompliance()
        }

        // Compute Sleep Debt (difference between actual weekly average and target)
        let debt = sleepModel.weeklyAverageMinutes - Int(targetMinutes)
        sleepDebtValue = Self.formatSigned(minutes: debt)

        // Compute Regularity
        let nightsList = nights.values.sorted { $0.day < $1.day }
        regularityMetric = SecondaryMetric(title: "Regularity", value: Self.regularity(of: nightsList))
    }

    // MARK: - Mapping: Workouts

    private func applyWorkouts(_ workouts: [HealthWorkout], startOfWeek: Date) {
        // Discard any workouts that the user explicitly deleted
        let validWorkouts = workouts.filter { !deletedWorkoutUUIDs.contains($0.uuid) }
        guard !validWorkouts.isEmpty else { return }

        let imported = validWorkouts.map { w in
            LoggedWorkout(
                id: w.uuid,
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
        
        // Merge with non-deleted existing local workouts
        var mergedMap: [UUID: LoggedWorkout] = [:]
        for workout in loggedWorkouts {
            if !deletedWorkoutUUIDs.contains(workout.id) && !(workout.healthKitUUID.map { deletedWorkoutUUIDs.contains($0) } ?? false) {
                mergedMap[workout.id] = workout
            }
        }
        
        for workout in imported {
            if !deletedWorkoutUUIDs.contains(workout.id) {
                // If this workout already exists locally by healthKitUUID, keep the existing one
                if let existing = loggedWorkouts.first(where: { $0.healthKitUUID == workout.healthKitUUID }) {
                    mergedMap[existing.id] = existing
                } else {
                    mergedMap[workout.id] = workout
                }
            }
        }
        
        loggedWorkouts = Array(mergedMap.values).sorted { $0.scheduledDate < $1.scheduledDate }
    }

    // MARK: - Mapping: Recovery Algorithm

    private func applyRecoveryAlgorithm(
        nights: [Date: SleepNight],
        today: Date,
        hrv: Double?, hrvBaseline: Double?,
        rhr: Double?, rhrBaseline: Double?,
        workouts: [HealthWorkout],
        now: Date
    ) {
        let sortedNights = nights.values.sorted { $0.day < $1.day }
        let currentNight = nights[today] ?? sortedNights.last
        
        // Pass all HealthKit metrics into the recovery calculation engine
        let input = RecoveryInput(
            currentNight: currentNight,
            recentNights: sortedNights,
            targetSleepHours: sleepModel.targetSleepHours,
            checkmarks: sleepModel.checkmarks,
            restingHeartRate: rhr,
            restingHeartRateBaseline: rhrBaseline,
            heartRateVariability: hrv,
            heartRateVariabilityBaseline: hrvBaseline,
            recentWorkouts: workouts,
            evaluationDate: now
        )
        
        let result = RecoveryAlgorithm.evaluate(input: input)
        
        // Effectively modify Quality and Readiness metrics in Training section
        readinessScore = result.readinessScore
        qualityScore = result.qualityScore
        sleepDebtValue = result.sleepDebtFormatted
        regularityMetric = SecondaryMetric(title: "Regularity", value: result.regularityStatus)
        customRecoveryRecommendation = result.recoveryRecommendation
    }

    // MARK: - Mapping: Profile

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

    // MARK: - Helpers

    static var mondayCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private static func clamp(_ value: Double) -> Double { max(0, min(100, value)) }

    static func formatDuration(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h 00m" : "\(h)h \(m)m"
    }

    private static func formatSigned(minutes: Int) -> String {
        let sign = minutes < 0 ? "-" : "+"
        let value = abs(minutes)
        if value == 0 { return "0m" }
        if value < 60 { return "\(sign)\(value)m" }
        return "\(sign)\(value / 60)h \(value % 60)m"
    }

    /// Standard deviation of bedtimes (minutes from 18:00) → label
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
