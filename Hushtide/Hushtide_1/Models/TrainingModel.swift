//
//  TrainingModel.swift
//  RecoveryApp
//
//  Created by AFP FED 020 on 30/10/2026.
//

import SwiftUI
import Observation
import AuthenticationServices

@Observable
public final class TrainingModel {
    
    // MARK: - Navigation State
    public var selectedTab: AppTab = .summary
    public var isProfilePresented: Bool = false
    public var isDebugSliderExpanded: Bool = false
    
    // MARK: - Centralized Headers & Labels
    public var summaryTitle: String = "Summary"
    public var sleepTitle: String = "Sleep"
    public var trainingTitle: String = "Training"
    public var profileTitle: String = "Personalize your Profile"
    public var intensitySectionLabel: String = "INTENSITY"
    public var readinessLabel: String = "READINESS"
    
    // MARK: - Shared Sleep Model State
    public var sleepModel = SleepModel()
    
    // MARK: - Summary Screen Metrics (Dynamic & Synchronized)
    public var selectedSummaryMetric: SummaryMetricTab = .sleep
    
    // Quality target and daily scores
    public var qualityTargetPercentage: Int = 85
    public var weeklyQualityPercentages: [Int] = [86, 72, 92, 80, 90, 96, 88]
    
    public var weeklyQualityAverage: Int {
        guard !weeklyQualityPercentages.isEmpty else { return 85 }
        return weeklyQualityPercentages.reduce(0, +) / weeklyQualityPercentages.count
    }
    
    public var summaryQualityValue: String {
        "\(weeklyQualityAverage)%"
    }
    
    public var summaryQualitySubtitle: String {
        "average\nrating"
    }
    
    public var summaryQualityProgress: Double {
        min(1.0, max(0.01, Double(weeklyQualityAverage) / 100.0))
    }
    
    // Sleep metrics synchronized with sleepModel
    public var sleepTargetHours: Double {
        get { sleepModel.targetSleepHours }
        set { sleepModel.targetSleepHours = newValue }
    }
    public var summarySleepValue: String {
        "\(sleepModel.daysMeetingTargetCount)/7"
    }
    
    public var summarySleepSubtitle: String {
        "average\n\(sleepModel.weeklyAverageFormatted)"
    }
    
    public var summarySleepProgress: Double {
        sleepModel.weeklySleepProgress
    }
    
    // Training target and calculations based on weekly logged workouts
    public var trainingWeeklyMinutesTarget: Int = 150
    
    public var weeklyLoggedTrainingMinutes: Int {
        loggedWorkouts.reduce(0) { $0 + $1.durationMinutes }
    }
    
    public var dailyTrainingAverageMinutes: Int {
        weeklyLoggedTrainingMinutes / 7
    }
    
    public var summaryTrainingValue: String {
        "\(weeklyLoggedTrainingMinutes)m"
    }
    
    public var summaryTrainingSubtitle: String {
        "of \(trainingWeeklyMinutesTarget)min\nper week"
    }
    
    public var summaryTrainingProgress: Double {
        min(1.0, max(0.01, Double(weeklyLoggedTrainingMinutes) / Double(max(1, trainingWeeklyMinutesTarget))))
    }
    
    public var currentDayWorkouts: [LoggedWorkout] {
        loggedWorkouts.filter { $0.dayIndex == selectedDayIndex }
    }
    
    public var dailyTrainingMinutes: [Int] {
        var result = [Int](repeating: 0, count: 7)
        for workout in loggedWorkouts {
            if workout.dayIndex >= 0 && workout.dayIndex < 7 {
                result[workout.dayIndex] += workout.durationMinutes
            }
        }
        return result
    }
    
    public func setQualityTarget(_ target: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            qualityTargetPercentage = max(10, min(100, target))
        }
    }
    
    public func setTrainingWeeklyTarget(_ minutes: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            trainingWeeklyMinutesTarget = max(15, min(999, minutes))
        }
    }
    
    public func selectSummaryMetric(_ metric: SummaryMetricTab) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedSummaryMetric = metric
        }
    }
    
    // MARK: - Weekdays Selector
    public var days: [DayItem] = [
        DayItem(id: 0, letter: "M", dayNumber: 26, fullDateDescription: "Monday, 26 October"),
        DayItem(id: 1, letter: "T", dayNumber: 27, fullDateDescription: "Tuesday, 27 October"),
        DayItem(id: 2, letter: "W", dayNumber: 28, fullDateDescription: "Today, Wednesday 28 October", isSelectedDefault: true),
        DayItem(id: 3, letter: "T", dayNumber: 29, fullDateDescription: "Thursday, 29 October"),
        DayItem(id: 4, letter: "F", dayNumber: 30, fullDateDescription: "Friday, 30 October"),
        DayItem(id: 5, letter: "S", dayNumber: 31, fullDateDescription: "Saturday, 31 October"),
        DayItem(id: 6, letter: "S", dayNumber: 1,  fullDateDescription: "Sunday, 1 November")
    ]
    
    public var selectedDayIndex: Int = 2
    
    public var currentDaySubtitle: String {
        guard selectedDayIndex >= 0 && selectedDayIndex < days.count else {
            return "Today, Wednesday 28 October"
        }
        return days[selectedDayIndex].fullDateDescription
    }
    
    // MARK: - Training Screen Metrics (Centralized & Customizable)
    public var readinessScore: Double = 93.0
    
    // Rest Levels & Sleep Quality (Computed from HealthKit data)
    public var qualityScore: Int = 88
    public var qualityValue: String {
        if let custom = _customQualityValue {
            return custom
        }
        return "\(qualityScore)%"
    }
    private var _customQualityValue: String? = nil
    
    // Sleep Debt (difference between actual sleep and target)
    public var sleepDebtValue: String = "-15m"
    
    public var sleepDebtMetric: SecondaryMetric {
        get { SecondaryMetric(title: "Sleep Debt", value: sleepDebtValue) }
        set { sleepDebtValue = newValue.value }
    }
    
    public var qualityMetric: SecondaryMetric {
        get { SecondaryMetric(title: "Quality", value: qualityValue) }
        set { _customQualityValue = newValue.value }
    }
    
    public var restedMetric: SecondaryMetric {
        get { qualityMetric }
        set { qualityMetric = newValue }
    }
    
    public var restedValue: String {
        get { qualityValue }
        set { _customQualityValue = newValue }
    }
    
    public var regularityMetric: SecondaryMetric = SecondaryMetric(title: "Regularity", value: "On time")
    
    // Custom recommendation message dynamically generated by the recovery algorithm
    public var customRecoveryRecommendation: String? = nil
    
    // Backwards-compatible aliases
    public var sleepMetric: SecondaryMetric {
        get { sleepDebtMetric }
        set { sleepDebtMetric = newValue }
    }
    
    // MARK: - Intensity Selector State
    public var selectedIntensity: IntensityLevel? = nil
    
    // MARK: - Settings & Accessibility State
    public var isHapticsEnabled: Bool = true {
        didSet {
            HapticManager.isHapticsEnabled = isHapticsEnabled
        }
    }
    public var isReduceMotionEnabled: Bool = false
    public var isHighContrastEnabled: Bool = false
    public var isAnalyticsOptOut: Bool = true
    
    // MARK: - Logged Workouts State & Feature
    public var loggedWorkouts: [LoggedWorkout] = []
    
    // MARK: - Profile Screen Data (Default "User", customizable by user)
    public var userName: String = "User"
    public var profileAvatarIcon: String = "person.crop.circle.fill"
    public var profileAvatarColor: Color = Color(red: 0.0, green: 0.48, blue: 1.0)
    public var profileCustomImageData: Data? = nil
    public var customSports: [String] = []
    public var sportType: String = "-"
    
    public var allAvailableSports: [String] {
        var list = ProfileOptions.sports
        for sport in customSports {
            if !list.contains(sport) {
                list.append(sport)
            }
        }
        return list
    }
    public var trainingLevel: String = "-"
    public var weeklyFrequency: String = "-"
    public var gender: String = "-"
    public var weight: String = "-"
    public var height: String = "-"
    public var isAppleHealthConnected: Bool = false
    public var isAppleIdSignedIn: Bool = false
    
    // MARK: - Apple Health (HealthKit) Manager
    public let health = HealthKitManager()
    @ObservationIgnored var pendingHealthSync: Task<Void, Never>?
    
    public var appleHealthNotice: String {
        if !health.isAvailable {
            return "Apple Health is not available on this device"
        }
        guard isAppleIdSignedIn && isAppleHealthConnected else {
            return "Sign in with Apple to synchronize Apple Health data"
        }
        if let last = health.lastSyncDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "✓ Apple Health synchronized · last update \(formatter.string(from: last))"
        }
        return "✓ Apple Health is actively synchronized"
    }
    
    public var signInWithAppleButtonText: String {
        isAppleIdSignedIn
            ? "Connected with Apple ID"
            : "Sign in with Apple"
    }
    
    public init() {
        self.loggedWorkouts = []
        self.sleepModel.onStateChanged = { [weak self] in
            self?.evaluateRecovery()
        }
        evaluateRecovery()
    }
    
    // MARK: - Dynamic Color Logic (0–39%: Red, 40–59%: Orange, 60–79%: Yellow, 80–100%: Green)
    public var dynamicThemeColor: Color {
        switch readinessScore {
        case ..<40.0:
            return Color(red: 0.95, green: 0.26, blue: 0.21) // Apple HIG Red
        case 40.0..<60.0:
            return Color(red: 1.0, green: 0.58, blue: 0.0)   // Apple HIG Orange
        case 60.0..<80.0:
            return Color(red: 0.96, green: 0.72, blue: 0.0)  // Warm Golden Yellow
        default:
            return Color(red: 0.20, green: 0.78, blue: 0.35) // Apple HIG Green
        }
    }
    
    public var dynamicColorName: String {
        switch readinessScore {
        case ..<40.0: return "Red (0–39%)"
        case 40.0..<60.0: return "Orange (40–59%)"
        case 60.0..<80.0: return "Yellow (60–79%)"
        default: return "Green (80–100%)"
        }
    }
    
    // MARK: - Dynamic Recovery Status & Recommendation
    public var recoveryStatusTitle: String {
        switch readinessScore {
        case ..<40.0:
            return "Needs rest"
        case 40.0..<60.0:
            return "Take it easy"
        case 60.0..<80.0:
            return "Moderate readiness"
        default:
            return "Ready to push"
        }
    }
    
    public var recoveryStatusIcon: String {
        switch readinessScore {
        case ..<40.0:
            return "bed.double.fill"
        case 40.0..<60.0:
            return "leaf.fill"
        case 60.0..<80.0:
            return "bolt.fill"
        default:
            return "flame.fill"
        }
    }
    
    public var recoveryStatusDescription: String {
        if let custom = customRecoveryRecommendation {
            return custom
        }
        switch readinessScore {
        case ..<40.0:
            return "High fatigue detected: prioritize sleep, hydration and light recovery"
        case 40.0..<60.0:
            return "Partial recovery: suitable for active recovery or light mobility"
        case 60.0..<80.0:
            return "Moderate recovery: ideal for tempo work, hypertrophy or light cardio"
        default:
            return "Full recovery: good day for strength, or a long session"
        }
    }
    
    // MARK: - Automatic Recommended Intensity Level
    public var recommendedIntensityLevel: IntensityLevel {
        switch readinessScore {
        case ..<40.0:
            return .rest
        case 40.0..<60.0:
            return .light
        case 60.0..<80.0:
            return .medium
        default:
            return .hard
        }
    }
    
    public var recommendedIntensityBadgeText: String {
        return "Recommended"
    }
    
    public func dateForDay(at index: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: now) ?? now
        let day = calendar.date(byAdding: .day, value: index, to: monday) ?? monday
        return calendar.date(bySettingHour: 17, minute: 0, second: 0, of: day) ?? day
    }
    
    // MARK: - User Intent Actions
    public func addWorkout(
        sportType: String,
        intensity: IntensityLevel,
        durationMinutes: Int,
        focusArea: String = "",
        scheduledDate: Date,
        dayIndex: Int? = nil,
        rpe: Int = 8,
        notes: String = ""
    ) {
        let targetDayIndex = dayIndex ?? selectedDayIndex
        let workout = LoggedWorkout(
            sportType: sportType,
            intensity: intensity,
            durationMinutes: durationMinutes,
            focusArea: focusArea,
            scheduledDate: scheduledDate,
            dayIndex: targetDayIndex,
            rpe: rpe,
            notes: notes
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            loggedWorkouts.append(workout)
            evaluateRecovery()
        }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        // Write the workout to Apple Health too if authorized
        guard health.isAuthorized && isAppleHealthConnected, health.canSaveWorkouts else { return }
        let localID = workout.id
        Task { [weak self] in
            guard let self else { return }
            do {
                let uuid = try await health.saveWorkout(
                    sport: sportType,
                    intensity: intensity,
                    start: scheduledDate,
                    durationMinutes: durationMinutes,
                    focusArea: focusArea,
                    rpe: rpe,
                    notes: notes
                )
                if let uuid, let index = loggedWorkouts.firstIndex(where: { $0.id == localID }) {
                    loggedWorkouts[index].healthKitUUID = uuid
                }
                await syncHealthData()
            } catch {
                print("Saving workout to Apple Health failed: \(error.localizedDescription)")
            }
        }
    }
    
    public func updateWorkout(_ workout: LoggedWorkout) {
        if let index = loggedWorkouts.firstIndex(where: { $0.id == workout.id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                loggedWorkouts[index] = workout
            }
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
    
    public func deleteWorkout(id: UUID) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            loggedWorkouts.removeAll { $0.id == id }
        }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    public func selectIntensity(_ level: IntensityLevel) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if selectedIntensity == level {
                // Deselect if already selected
                selectedIntensity = nil
            } else {
                selectedIntensity = level
            }
        }
    }
    
    public func selectDay(at index: Int) {
        guard index >= 0 && index < days.count else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedDayIndex = index
            sleepModel.selectDay(at: index)
            evaluateRecovery()
        }
    }
    
    public func selectTab(_ tab: AppTab) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTab = tab
        }
    }
    
    public func setReadinessScore(_ score: Double) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            readinessScore = max(0, min(100, score))
            // Reset custom text so debug slider and presets demonstrate each tier smoothly
            customRecoveryRecommendation = nil
        }
    }
    
    // MARK: - Recovery & Readiness Algorithm Evaluation
    /// Evaluates recovery based on HealthKit data or current sleep duration, checkmarks, and workout logs.
    public func evaluateRecovery() {
        let workoutsAsHealth = loggedWorkouts.map { $0.toHealthWorkout() }
        let currentNight = sleepModel.currentDaySleepNight()
        let recentNights = sleepModel.toSleepNights()
        
        let input = RecoveryInput(
            currentNight: currentNight,
            recentNights: recentNights,
            targetSleepHours: sleepModel.targetSleepHours,
            checkmarks: sleepModel.checkmarks,
            restingHeartRate: nil,
            restingHeartRateBaseline: nil,
            heartRateVariability: nil,
            heartRateVariabilityBaseline: nil,
            recentWorkouts: workoutsAsHealth,
            evaluationDate: dateForDay(at: selectedDayIndex)
        )
        
        let result = RecoveryAlgorithm.evaluate(input: input)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.readinessScore = result.readinessScore
            self.qualityScore = result.qualityScore
            self._customQualityValue = nil
            self.sleepDebtValue = result.sleepDebtFormatted
            self.regularityMetric = SecondaryMetric(title: "Regularity", value: result.regularityStatus)
            self.customRecoveryRecommendation = result.recoveryRecommendation
            
            // Keep weekly quality bars synchronized for the summary screen
            if selectedDayIndex >= 0 && selectedDayIndex < weeklyQualityPercentages.count {
                self.weeklyQualityPercentages[selectedDayIndex] = result.qualityScore
            }
        }
    }
    
    // MARK: - Profile Editing Actions
    public func updateUserName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userName = trimmed
        UserDefaults.standard.set(trimmed, forKey: "AppleIDUserName")
        triggerSelectionHaptic()
    }
    
    public func updateSportType(_ newSport: String) {
        sportType = newSport
        triggerSelectionHaptic()
    }
    
    public func addCustomSport(_ sport: String) {
        let trimmed = sport.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if !customSports.contains(trimmed) && !ProfileOptions.sports.contains(trimmed) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                customSports.append(trimmed)
            }
        }
        updateSportType(trimmed)
    }
    
    public func updateTrainingLevel(_ newLevel: String) {
        trainingLevel = newLevel
        triggerSelectionHaptic()
    }
    
    public func updateWeeklyFrequency(_ newFrequency: String) {
        weeklyFrequency = newFrequency
        triggerSelectionHaptic()
    }
    
    public func updateGender(_ newGender: String) {
        gender = newGender
        triggerSelectionHaptic()
    }
    
    public func updateWeight(_ newWeight: String) {
        weight = newWeight
        triggerSelectionHaptic()
    }
    
    public func updateHeight(_ newHeight: String) {
        height = newHeight
        triggerSelectionHaptic()
    }
    
    public func updateProfileAvatar(icon: String, color: Color) {
        profileAvatarIcon = icon
        profileAvatarColor = color
        triggerSelectionHaptic()
    }
    
    public func updateProfileCustomImageData(_ data: Data?) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            profileCustomImageData = data
        }
        triggerSelectionHaptic()
    }
    
    // MARK: - Native Sign in with Apple Authentication Handlers
    public func startAppleSignIn() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.isAppleIdSignedIn = true
        }
        
        let notif = UINotificationFeedbackGenerator()
        notif.prepare()
        notif.notificationOccurred(.success)
    }
    public static func resolveUserDisplayName() -> String {
        if let saved = UserDefaults.standard.string(forKey: "AppleIDUserName")?.trimmingCharacters(in: .whitespaces),
           !saved.isEmpty, saved != "-" {
            return saved
        }
        return "User"
    }
    
    public func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                if let fullName = appleIDCredential.fullName {
                    let given = fullName.givenName ?? ""
                    let family = fullName.familyName ?? ""
                    let combined = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
                    if !combined.isEmpty {
                        UserDefaults.standard.set(combined, forKey: "AppleIDUserName")
                        self.userName = combined
                    }
                }
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.isAppleIdSignedIn = true
                }
                
                let generator = UINotificationFeedbackGenerator()
                generator.prepare()
                generator.notificationOccurred(.success)
            }
        case .failure(let error):
            print("Sign in with Apple notice: \(error.localizedDescription)")
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                self.isAppleIdSignedIn = true
            }
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
    
    public func removeHealthSync() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isAppleIdSignedIn = false
            isAppleHealthConnected = false
        }
        health.stopObserving()
        health.resetAuthorization()
        
        let notif = UINotificationFeedbackGenerator()
        notif.prepare()
        notif.notificationOccurred(.warning)
    }
    
    public func signOutAppleId() {
        removeHealthSync()
    }
    
    public func toggleAppleSignIn() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isAppleIdSignedIn.toggle()
            isAppleHealthConnected = isAppleIdSignedIn
        }
        
        if isAppleIdSignedIn {
            generator.notificationOccurred(.success)
        } else {
            generator.notificationOccurred(.warning)
        }
    }
    
    private func triggerSelectionHaptic() {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
