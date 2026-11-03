//
//  TrainingModel+HealthSync.swift
//  RecoveryApp
//
//  Integrates Apple Health (HealthKit) synchronization with TrainingModel
//  (readiness score, sleep metrics, workouts, and profile).
//

import SwiftUI
import HealthKit

extension TrainingModel {

    // MARK: - Entry points

    /// Call once at launch: restores the HealthKit connection and starts live updates.
    @MainActor
    public func startHealthSync() async {
        await health.refreshAuthorizationStatus()
        guard health.isAuthorized else { return }
        isAppleHealthConnected = true
        health.startObserving { [weak self] in
            self?.scheduleHealthSync()
        }
        await syncHealthData()
    }

    /// Shows the Apple Health permission sheet and performs an immediate sync.
    @MainActor
    public func connectAppleHealth() async {
        // Always request authorization from HealthKit so the permission sheet appears
        _ = await health.requestAuthorization()
        
        isAppleHealthConnected = true
        isAppleIdSignedIn = true
        health.startObserving { [weak self] in
            self?.scheduleHealthSync()
        }
        await syncHealthData()

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Debounced sync, used when Health notifies of new samples.
    public func scheduleHealthSync() {
        pendingHealthSync?.cancel()
        pendingHealthSync = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await self?.syncHealthData()
        }
    }

    // MARK: - Full sync

    @MainActor
    public func syncHealthData() async {
        guard !health.isSyncing else { return }
        guard isAppleHealthConnected || health.isAuthorized else { return }
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
        let nights = (try? await health.fetchSleepNights(from: firstNeededDay, through: today)) ?? [:]

        // 2. Workouts of the current week (Mon–Sun)
        let workouts = (try? await health.fetchWorkouts(from: startOfWeek, to: endOfWeek)) ?? []

        // 3. Heart metrics (today vs 30-day baseline)
        let ms = HKUnit.secondUnit(with: .milli)
        let bpm = HKUnit.count().unitDivided(by: .minute())
        let dayAgo = now.addingTimeInterval(-24 * 3600)
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let hrvToday = try? await health.latestQuantity(.heartRateVariabilitySDNN, unit: ms, since: dayAgo)
        let hrvBaseline = try? await health.averageQuantity(.heartRateVariabilitySDNN, unit: ms, from: monthAgo, to: now)
        let rhrToday = try? await health.latestQuantity(.restingHeartRate, unit: bpm, since: dayAgo)
        let rhrBaseline = try? await health.averageQuantity(.restingHeartRate, unit: bpm, from: monthAgo, to: now)

        // 4. Profile (fills empty fields)
        let weightKg = try? await health.latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        let heightCm = try? await health.latestQuantity(.height, unit: .meterUnit(with: .centi))

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
            if let night = nights[startOfD], night.asleepMinutes > 0 {
                if offset < updatedWeeklySleep.count {
                    updatedWeeklySleep[offset] = night.asleepMinutes
                }
                if offset < updatedQualityBars.count {
                    // Evaluate this day's rest quality via RecoveryAlgorithm
                    let (dayQuality, _) = RecoveryAlgorithm.calculateRestQuality(
                        currentNight: night,
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
        guard !workouts.isEmpty else { return }

        let imported = workouts.map { w in
            LoggedWorkout(
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
        // Retain local-only workouts not saved to HealthKit
        let localOnly = loggedWorkouts.filter { $0.healthKitUUID == nil }
        loggedWorkouts = (localOnly + imported).sorted { $0.scheduledDate < $1.scheduledDate }
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
        // 1. Weight: real HealthKit measurement or baseline fallback
        if let kg = weightKg {
            weight = String(format: "%.1f kg", kg)
        } else if weight == "-" {
            weight = "72.0 kg"
        }

        // 2. Height: real HealthKit measurement or baseline fallback
        if let cm = heightCm {
            height = "\(Int(cm.rounded()))cm"
        } else if height == "-" {
            height = "178cm"
        }

        // 3. Gender: real HealthKit biological sex or baseline fallback
        if let sex = health.biologicalSexDescription() {
            gender = sex
        } else if gender == "-" {
            gender = "Male"
        }

        // 4. User Name: defaults to "User", user can edit it manually
        if userName == "-" || userName.isEmpty {
            userName = Self.resolveUserDisplayName()
        }

        // 5. YOUR SPORT (sportType, trainingLevel, weeklyFrequency) are left untouched
        // so they remain blank ("-") until the user manually selects them.
        // 6. Profile photo & summary icon remain the base user avatar
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
