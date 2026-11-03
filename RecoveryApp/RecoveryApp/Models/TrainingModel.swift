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
    
    // MARK: - Shared Calendar & Sleep Model State
    public var calendarModel = CalendarModel()
    public var sleepModel = SleepModel()
    
    // MARK: - Summary Screen Metrics (Dynamic & Synchronized)
    public var selectedSummaryMetric: SummaryMetricTab = .sleep
    
    // Quality target and daily scores
    public var qualityTargetPercentage: Int = 85
    public var weeklyQualityPercentages: [Int] {
        get {
            var list = _weeklyQualityPercentages
            for i in 0..<list.count {
                if calendarModel.isDayIndexInFuture(i) {
                    list[i] = 0
                }
            }
            return list
        }
        set {
            _weeklyQualityPercentages = newValue
        }
    }
    // All values default to zero until Apple Health data is synchronized with Face ID / PIN
    private var _weeklyQualityPercentages: [Int] = [0, 0, 0, 0, 0, 0, 0]
    
    public var weeklyQualityAverage: Int {
        guard isAppleHealthSynced else { return 0 }
        let nonFuture = (0..<weeklyQualityPercentages.count).filter { !calendarModel.isDayIndexInFuture($0) }
        guard !nonFuture.isEmpty else { return 0 }
        let sum = nonFuture.map { weeklyQualityPercentages[$0] }.reduce(0, +)
        return sum / nonFuture.count
    }
    
    public var summaryQualityValue: String {
        "\(weeklyQualityAverage)%"
    }
    
    public var summaryQualitySubtitle: String {
        "average\nrating"
    }
    
    public var summaryQualityProgress: Double {
        guard isAppleHealthSynced && weeklyQualityAverage > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(weeklyQualityAverage) / 100.0))
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
        guard isAppleHealthSynced else { return 0.0 }
        return sleepModel.weeklySleepProgress
    }
    
    // Training target and calculations based on daily target and weekly logged workouts
    public var trainingDailyMinutesTarget: Int = 30 {
        didSet {
            trainingWeeklyMinutesTarget = trainingDailyMinutesTarget * 7
        }
    }
    public var trainingWeeklyMinutesTarget: Int = 210
    
    public var weeklyLoggedTrainingMinutes: Int {
        guard isAppleHealthSynced else { return 0 }
        return loggedWorkouts.reduce(0) { $0 + $1.durationMinutes }
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
        guard isAppleHealthSynced && trainingWeeklyMinutesTarget > 0 && weeklyLoggedTrainingMinutes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(weeklyLoggedTrainingMinutes) / Double(max(1, trainingWeeklyMinutesTarget))))
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
        HapticManager.impact(.light)
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            qualityTargetPercentage = max(10, min(100, target))
        }
    }
    
    public func setTrainingDailyTarget(_ dailyMinutes: Int) {
        HapticManager.impact(.light)
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let clamped = max(5, min(180, dailyMinutes))
            trainingDailyMinutesTarget = clamped
            trainingWeeklyMinutesTarget = clamped * 7
        }
    }
    
    public func setTrainingWeeklyTarget(_ minutes: Int) {
        let daily = max(1, minutes / 7)
        setTrainingDailyTarget(daily)
    }
    
    public func selectSummaryMetric(_ metric: SummaryMetricTab) {
        HapticManager.impact(.light)
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedSummaryMetric = metric
        }
    }
    
    // MARK: - Weekdays Selector
    public var days: [DayItem] {
        calendarModel.weekDays
    }
    
    public var selectedDayIndex: Int {
        get { calendarModel.selectedDayIndex }
        set { calendarModel.selectedDayIndex = newValue }
    }
    
    public var currentDaySubtitle: String {
        calendarModel.currentDaySubtitle
    }
    
    public var isSelectedDayInFuture: Bool {
        calendarModel.isSelectedDateInFuture
    }
    
    // MARK: - Training Screen Metrics (Centralized & Customizable)
    // When opened without syncing Apple Health, all values default to zero
    public var readinessScore: Double = 0.0
    
    // Rest Levels & Sleep Quality (Computed from HealthKit data)
    public var qualityScore: Int = 0
    public var qualityValue: String {
        if let custom = _customQualityValue {
            return custom
        }
        return "\(qualityScore)%"
    }
    private var _customQualityValue: String? = nil
    
    // Sleep Debt (difference between actual sleep and target)
    public var sleepDebtValue: String = "0m"
    
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
    
    public var regularityMetric: SecondaryMetric = SecondaryMetric(title: "Regularity", value: "-")
    
    // Custom recommendation message dynamically generated by the recovery algorithm
    public var customRecoveryRecommendation: String? = nil
    
    // Backwards-compatible aliases
    public var sleepMetric: SecondaryMetric {
        get { sleepDebtMetric }
        set { sleepDebtMetric = newValue }
    }
    
    // MARK: - Intensity Selector State
    public var selectedIntensity: IntensityLevel? = nil
    
    // MARK: - Storage Keys
    public enum StorageKeys {
        public static let savedWorkouts = "RecoveryApp_savedWorkouts"
        public static let deletedWorkoutUUIDs = "RecoveryApp_deletedWorkoutUUIDs"
        public static let isHapticsEnabled = "RecoveryApp_isHapticsEnabled"
        public static let isReduceMotionEnabled = "RecoveryApp_isReduceMotionEnabled"
        public static let isHighContrastEnabled = "RecoveryApp_isHighContrastEnabled"
        public static let hasInitializedBaseline = "RecoveryApp_hasInitializedBaseline"
        public static let isAppleHealthConnected = "RecoveryApp_isAppleHealthConnected"
        public static let isAppleHealthSynced = "RecoveryApp_isAppleHealthSynced"
        public static let isAppleIdSignedIn = "RecoveryApp_isAppleIdSignedIn"
    }
    
    // MARK: - Settings & Accessibility State
    public var isHapticsEnabled: Bool = true {
        didSet {
            HapticManager.isHapticsEnabled = isHapticsEnabled
            UserDefaults.standard.set(isHapticsEnabled, forKey: StorageKeys.isHapticsEnabled)
        }
    }
    public var isReduceMotionEnabled: Bool = false {
        didSet {
            HapticManager.isReduceMotionEnabled = isReduceMotionEnabled
            UserDefaults.standard.set(isReduceMotionEnabled, forKey: StorageKeys.isReduceMotionEnabled)
        }
    }
    public var isHighContrastEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isHighContrastEnabled, forKey: StorageKeys.isHighContrastEnabled)
        }
    }
    public var isAnalyticsOptOut: Bool = true
    
    // MARK: - Logged Workouts State & Persistence
    public var loggedWorkouts: [LoggedWorkout] = [] {
        didSet {
            saveWorkoutsToStorage()
        }
    }
    public var deletedWorkoutUUIDs: Set<UUID> = [] {
        didSet {
            saveDeletedWorkoutUUIDsToStorage()
        }
    }
    
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
    public var isAppleHealthConnected: Bool = false {
        didSet {
            UserDefaults.standard.set(isAppleHealthConnected, forKey: StorageKeys.isAppleHealthConnected)
        }
    }
    public var isAppleIdSignedIn: Bool = false {
        didSet {
            UserDefaults.standard.set(isAppleIdSignedIn, forKey: StorageKeys.isAppleIdSignedIn)
        }
    }
    public var isAppleHealthSynced: Bool = false {
        didSet {
            UserDefaults.standard.set(isAppleHealthSynced, forKey: StorageKeys.isAppleHealthSynced)
            sleepModel.isAppleHealthSynced = isAppleHealthSynced
        }
    }
    
    // Cached heart metrics for continuous recovery algorithm evaluation
    public var latestHRV: Double? = nil
    public var baselineHRV: Double? = nil
    public var latestRHR: Double? = nil
    public var baselineRHR: Double? = nil
    
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
        // Restore accessibility settings
        let hapticsStored = UserDefaults.standard.object(forKey: StorageKeys.isHapticsEnabled) != nil
            ? UserDefaults.standard.bool(forKey: StorageKeys.isHapticsEnabled)
            : true
        self.isHapticsEnabled = hapticsStored
        HapticManager.isHapticsEnabled = hapticsStored

        let reduceMotionStored = UserDefaults.standard.bool(forKey: StorageKeys.isReduceMotionEnabled)
        self.isReduceMotionEnabled = reduceMotionStored
        HapticManager.isReduceMotionEnabled = reduceMotionStored

        let highContrastStored = UserDefaults.standard.bool(forKey: StorageKeys.isHighContrastEnabled)
        self.isHighContrastEnabled = highContrastStored

        // Restore deleted workout UUIDs
        if let deletedList = UserDefaults.standard.stringArray(forKey: StorageKeys.deletedWorkoutUUIDs) {
            self.deletedWorkoutUUIDs = Set(deletedList.compactMap { UUID(uuidString: $0) })
        }

        // Restore saved workouts from persistent storage
        if let data = UserDefaults.standard.data(forKey: StorageKeys.savedWorkouts),
           let decoded = try? JSONDecoder().decode([LoggedWorkout].self, from: data) {
            let activeDeleted = self.deletedWorkoutUUIDs
            self.loggedWorkouts = decoded.filter {
                !activeDeleted.contains($0.id) && ($0.healthKitUUID == nil || !activeDeleted.contains($0.healthKitUUID!))
            }
        } else {
            self.loggedWorkouts = []
        }

        // Restore persistent Apple Health synchronization states
        let connectedStored = UserDefaults.standard.bool(forKey: StorageKeys.isAppleHealthConnected)
        let syncedStored = UserDefaults.standard.bool(forKey: StorageKeys.isAppleHealthSynced)
        let appleIdStored = UserDefaults.standard.bool(forKey: StorageKeys.isAppleIdSignedIn)
        self.isAppleHealthConnected = connectedStored
        self.isAppleHealthSynced = syncedStored
        self.isAppleIdSignedIn = appleIdStored

        self.sleepModel.calendarModel = self.calendarModel
        self.sleepModel.isAppleHealthSynced = syncedStored
        self.sleepModel.checkAndPerformDailyResetIfNeeded()
        self.sleepModel.selectDay(at: self.calendarModel.selectedDayIndex)
        self.sleepModel.onStateChanged = { [weak self] in
            self?.evaluateRecovery()
        }
        evaluateRecovery()
    }
    
    // MARK: - Workout Storage Helpers
    public func saveWorkoutsToStorage() {
        if let encoded = try? JSONEncoder().encode(loggedWorkouts) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.savedWorkouts)
        }
    }
    
    public func saveDeletedWorkoutUUIDsToStorage() {
        let array = deletedWorkoutUUIDs.map { $0.uuidString }
        UserDefaults.standard.set(array, forKey: StorageKeys.deletedWorkoutUUIDs)
    }
    
    // MARK: - Dynamic Color Logic (0–39%: Red, 40–59%: Orange, 60–79%: Yellow, 80–100%: Green)
    public var dynamicThemeColor: Color {
        guard isAppleHealthSynced && readinessScore > 0 else {
            return Color(uiColor: .systemGray)
        }
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
        guard isAppleHealthSynced && readinessScore > 0 else { return "No data" }
        switch readinessScore {
        case ..<40.0: return "Red (0–39%)"
        case 40.0..<60.0: return "Orange (40–59%)"
        case 60.0..<80.0: return "Yellow (60–79%)"
        default: return "Green (80–100%)"
        }
    }
    
    // MARK: - Dynamic Recovery Status & Recommendation
    public var recoveryStatusTitle: String {
        if isSelectedDayInFuture || !isAppleHealthSynced || readinessScore <= 0 {
            return "No data"
        }
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
        guard isAppleHealthSynced && readinessScore > 0 else {
            return "circle"
        }
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
        if isSelectedDayInFuture {
            return "No recovery data recorded for future days."
        }
        if !isAppleHealthSynced || readinessScore <= 0 {
            return "No recovery data recorded. Sync Apple Health to calculate readiness."
        }
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
        if isSelectedDayInFuture {
            return .rest
        }
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
        calendarModel.dateForDay(at: index)
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
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            loggedWorkouts.append(workout)
            evaluateRecovery()
        }
        HapticManager.notification(.success)
        saveWorkoutsToStorage()
        
        // Write the workout to Apple Health in background if authorized
        // Direct insertion: absolutely NO biometric authentication or Face ID prompt is triggered.
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
                    saveWorkoutsToStorage()
                }
                // Background non-authenticating data refresh to keep metrics in sync
                await performHealthDataSync()
            } catch {
                print("Saving workout to Apple Health failed: \(error.localizedDescription)")
            }
        }
    }
    
    public func updateWorkout(_ workout: LoggedWorkout) {
        if let index = loggedWorkouts.firstIndex(where: { $0.id == workout.id }) {
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                loggedWorkouts[index] = workout
                evaluateRecovery()
            }
            saveWorkoutsToStorage()
            HapticManager.notification(.success)
        }
    }
    
    public func deleteWorkout(id: UUID) {
        // Track ID and any associated HealthKit UUID as permanently deleted
        var healthKitUUIDToDelete: UUID? = nil
        if let workout = loggedWorkouts.first(where: { $0.id == id }) {
            healthKitUUIDToDelete = workout.healthKitUUID
        }
        
        deletedWorkoutUUIDs.insert(id)
        if let hkUUID = healthKitUUIDToDelete {
            deletedWorkoutUUIDs.insert(hkUUID)
        }
        saveDeletedWorkoutUUIDsToStorage()
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            loggedWorkouts.removeAll {
                $0.id == id || ($0.healthKitUUID != nil && $0.healthKitUUID == healthKitUUIDToDelete)
            }
            evaluateRecovery()
        }
        saveWorkoutsToStorage()
        HapticManager.notification(.success)
        
        // Delete permanently from HealthKit in background if applicable
        if let hkUUID = healthKitUUIDToDelete, health.isAuthorized && health.canSaveWorkouts {
            Task { [weak self] in
                try? await self?.health.deleteWorkout(uuid: hkUUID)
            }
        }
    }
    
    public func selectIntensity(_ level: IntensityLevel) {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
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
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            calendarModel.selectDay(at: index)
            sleepModel.selectDay(at: index)
            evaluateRecovery()
        }
    }
    
    public func selectTab(_ tab: AppTab) {
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTab = tab
        }
    }
    
    public func setReadinessScore(_ score: Double) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            readinessScore = max(0, min(100, score))
            // Reset custom text so debug slider and presets demonstrate each tier smoothly
            customRecoveryRecommendation = nil
        }
    }
    
    // MARK: - Recovery & Readiness Algorithm Evaluation
    /// Evaluates recovery based on HealthKit data or current sleep duration, checkmarks, and workout logs.
    public func evaluateRecovery() {
        if isSelectedDayInFuture || !isAppleHealthSynced {
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.readinessScore = 0.0
                self.qualityScore = 0
                self._customQualityValue = nil
                self.sleepDebtValue = "0m"
                self.regularityMetric = SecondaryMetric(title: "Regularity", value: "-")
                if isSelectedDayInFuture {
                    self.customRecoveryRecommendation = "No recovery data recorded for future days."
                } else {
                    self.customRecoveryRecommendation = "No recovery data recorded. Sync Apple Health to calculate readiness."
                }
                if !isAppleHealthSynced {
                    self._weeklyQualityPercentages = [0, 0, 0, 0, 0, 0, 0]
                } else if selectedDayIndex >= 0 && selectedDayIndex < _weeklyQualityPercentages.count {
                    self._weeklyQualityPercentages[selectedDayIndex] = 0
                }
            }
            return
        }
        
        let workoutsAsHealth = loggedWorkouts.map { $0.toHealthWorkout() }
        let currentNight = sleepModel.currentDaySleepNight()
        let recentNights = sleepModel.toSleepNights()
        
        let input = RecoveryInput(
            currentNight: currentNight,
            recentNights: recentNights,
            targetSleepHours: sleepModel.targetSleepHours,
            checkmarks: sleepModel.checkmarks,
            restingHeartRate: latestRHR,
            restingHeartRateBaseline: baselineRHR,
            heartRateVariability: latestHRV,
            heartRateVariabilityBaseline: baselineHRV,
            recentWorkouts: workoutsAsHealth,
            evaluationDate: dateForDay(at: selectedDayIndex)
        )
        
        let result = RecoveryAlgorithm.evaluate(input: input)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.readinessScore = result.readinessScore
            self.qualityScore = result.qualityScore
            self._customQualityValue = nil
            self.sleepDebtValue = result.sleepDebtFormatted
            self.regularityMetric = SecondaryMetric(title: "Regularity", value: result.regularityStatus)
            self.customRecoveryRecommendation = result.recoveryRecommendation
            
            // Keep weekly quality bars synchronized for the summary screen
            if selectedDayIndex >= 0 && selectedDayIndex < _weeklyQualityPercentages.count {
                self._weeklyQualityPercentages[selectedDayIndex] = result.qualityScore
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
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            profileCustomImageData = data
        }
        triggerSelectionHaptic()
    }
    
    // MARK: - Native Sign in with Apple Authentication Handlers
    public func startAppleSignIn() {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.isAppleIdSignedIn = true
        }
        
        HapticManager.notification(.success)
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
                
                withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.isAppleIdSignedIn = true
                }
                
                HapticManager.notification(.success)
            }
        case .failure(let error):
            print("Sign in with Apple notice: \(error.localizedDescription)")
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                self.isAppleIdSignedIn = true
            }
            HapticManager.notification(.success)
        }
    }
    
    public func removeHealthSync() {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isAppleIdSignedIn = false
            isAppleHealthConnected = false
            isAppleHealthSynced = false
            latestHRV = nil
            baselineHRV = nil
            latestRHR = nil
            baselineRHR = nil
            sleepModel.resetToZero()
            loggedWorkouts = []
            evaluateRecovery()
        }
        health.stopObserving()
        health.resetAuthorization()
        
        HapticManager.notification(.warning)
    }
    
    public func signOutAppleId() {
        removeHealthSync()
    }
    
    public func toggleAppleSignIn() {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isAppleIdSignedIn.toggle()
            isAppleHealthConnected = isAppleIdSignedIn
        }
        
        if isAppleIdSignedIn {
            HapticManager.notification(.success)
        } else {
            HapticManager.notification(.warning)
        }
    }
    
    private func triggerSelectionHaptic() {
        HapticManager.impact(.light)
    }
}
