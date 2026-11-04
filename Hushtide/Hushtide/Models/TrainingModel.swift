import SwiftUI
import Observation
import AuthenticationServices

@Observable
public final class TrainingModel {
    
    public var selectedTab: AppTab = .summary
    public var isProfilePresented: Bool = false
    public var isDebugSliderExpanded: Bool = false
    
    public var summaryTitle: String = "Summary"
    public var sleepTitle: String = "Sleep"
    public var trainingTitle: String = "Training"
    public var profileTitle: String = "Personalize your Profile"
    public var intensitySectionLabel: String = "INTENSITY"
    public var readinessLabel: String = "READINESS"
    
    public var calendarModel = CalendarModel()
    public var sleepModel = SleepModel()
    
    public var selectedSummaryMetric: SummaryMetricTab = .sleep
    
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
    private var _weeklyQualityPercentages: [Int] = [0, 0, 0, 0, 0, 0, 0]
    
    public var weeklyReadinessScores: [Double] {
        get {
            var list = _weeklyReadinessScores
            for i in 0..<list.count {
                if calendarModel.isDayIndexInFuture(i) {
                    list[i] = 0.0
                }
            }
            return list
        }
        set {
            _weeklyReadinessScores = newValue
        }
    }
    private var _weeklyReadinessScores: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    
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
    
    // Updates target sleep quality percentage
    public func setQualityTarget(_ target: Int) {
        HapticManager.impact(.light)
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            qualityTargetPercentage = max(10, min(100, target))
        }
    }
    
    // Updates daily training goal in minutes
    public func setTrainingDailyTarget(_ dailyMinutes: Int) {
        HapticManager.impact(.light)
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let clamped = max(5, min(180, dailyMinutes))
            trainingDailyMinutesTarget = clamped
            trainingWeeklyMinutesTarget = clamped * 7
        }
    }
    
    // Updates weekly training goal in minutes
    public func setTrainingWeeklyTarget(_ minutes: Int) {
        let daily = max(1, minutes / 7)
        setTrainingDailyTarget(daily)
    }
    
    // Switches the active metric tab on the summary screen
    public func selectSummaryMetric(_ metric: SummaryMetricTab) {
        HapticManager.impact(.light)
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedSummaryMetric = metric
        }
    }
    
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
    
    public var readinessScore: Double = 0.0
    
    public var qualityScore: Int = 0
    public var qualityValue: String {
        if let custom = _customQualityValue {
            return custom
        }
        return "\(qualityScore)%"
    }
    private var _customQualityValue: String? = nil
    
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
    
    public var customRecoveryRecommendation: String? = nil
    
    public var sleepMetric: SecondaryMetric {
        get { sleepDebtMetric }
        set { sleepDebtMetric = newValue }
    }
    
    public var selectedIntensity: IntensityLevel? = nil
    
    public enum StorageKeys {
        public static let savedWorkouts = "RecoveryApp_savedWorkouts"
        public static let deletedWorkoutUUIDs = "RecoveryApp_deletedWorkoutUUIDs"
        public static let deletedWorkoutSignatures = "RecoveryApp_deletedWorkoutSignatures"
        public static let savedReadinessScore = "RecoveryApp_savedReadinessScore"
        public static let savedWeeklyReadinessScores = "RecoveryApp_savedWeeklyReadinessScores"
        public static let savedQualityScore = "RecoveryApp_savedQualityScore"
        public static let savedWeeklyQualityScores = "RecoveryApp_savedWeeklyQualityScores"
        public static let savedSleepDebtValue = "RecoveryApp_savedSleepDebtValue"
        public static let savedRegularityValue = "RecoveryApp_savedRegularityValue"
        public static let savedRecoveryRecommendation = "RecoveryApp_savedRecoveryRecommendation"
        public static let isHapticsEnabled = "RecoveryApp_isHapticsEnabled"
        public static let isReduceMotionEnabled = "RecoveryApp_isReduceMotionEnabled"
        public static let isHighContrastEnabled = "RecoveryApp_isHighContrastEnabled"
        public static let hasInitializedBaseline = "RecoveryApp_hasInitializedBaseline"
        public static let isAppleHealthConnected = "RecoveryApp_isAppleHealthConnected"
        public static let isAppleHealthSynced = "RecoveryApp_isAppleHealthSynced"
        public static let isAppleIdSignedIn = "RecoveryApp_isAppleIdSignedIn"
    }
    
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
    public var deletedWorkoutSignatures: Set<String> = [] {
        didSet {
            saveDeletedWorkoutSignaturesToStorage()
        }
    }
    
    // Generates a stable signature for a workout to prevent zombie re-import
    public static func workoutSignature(sport: String, start: Date, duration: Int) -> String {
        let roundedStart = Int(start.timeIntervalSince1970 / 60) * 60
        return "\(sport.trimmingCharacters(in: .whitespaces).lowercased())_\(roundedStart)_\(duration)"
    }
    
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
    
    public var latestHRV: Double? = nil
    public var baselineHRV: Double? = nil
    public var latestRHR: Double? = nil
    public var baselineRHR: Double? = nil
    
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

        if let deletedList = UserDefaults.standard.stringArray(forKey: StorageKeys.deletedWorkoutUUIDs) {
            self.deletedWorkoutUUIDs = Set(deletedList.compactMap { UUID(uuidString: $0) })
        }
        if let deletedSigs = UserDefaults.standard.stringArray(forKey: StorageKeys.deletedWorkoutSignatures) {
            self.deletedWorkoutSignatures = Set(deletedSigs)
        }

        if let data = UserDefaults.standard.data(forKey: StorageKeys.savedWorkouts),
           let decoded = try? JSONDecoder().decode([LoggedWorkout].self, from: data) {
            let activeDeleted = self.deletedWorkoutUUIDs
            let activeSigs = self.deletedWorkoutSignatures
            self.loggedWorkouts = decoded.filter {
                let sig = Self.workoutSignature(sport: $0.sportType, start: $0.scheduledDate, duration: $0.durationMinutes)
                let isDeleted = activeDeleted.contains($0.id) ||
                    ($0.healthKitUUID != nil && activeDeleted.contains($0.healthKitUUID!)) ||
                    activeSigs.contains(sig)
                return !isDeleted
            }
        } else {
            self.loggedWorkouts = []
        }

        // Restore persisted readiness metrics if available
        if let savedScore = UserDefaults.standard.object(forKey: StorageKeys.savedReadinessScore) as? Double {
            self.readinessScore = savedScore
        }
        if let savedWeeklyReadiness = UserDefaults.standard.array(forKey: StorageKeys.savedWeeklyReadinessScores) as? [Double],
           savedWeeklyReadiness.count == 7 {
            self._weeklyReadinessScores = savedWeeklyReadiness
        }
        if let savedQuality = UserDefaults.standard.object(forKey: StorageKeys.savedQualityScore) as? Int {
            self.qualityScore = savedQuality
        }
        if let savedWeeklyQuality = UserDefaults.standard.array(forKey: StorageKeys.savedWeeklyQualityScores) as? [Int],
           savedWeeklyQuality.count == 7 {
            self._weeklyQualityPercentages = savedWeeklyQuality
        }
        if let savedDebt = UserDefaults.standard.string(forKey: StorageKeys.savedSleepDebtValue) {
            self.sleepDebtValue = savedDebt
        }
        if let savedReg = UserDefaults.standard.string(forKey: StorageKeys.savedRegularityValue) {
            self.regularityMetric = SecondaryMetric(title: "Regularity", value: savedReg)
        }
        if let savedRec = UserDefaults.standard.string(forKey: StorageKeys.savedRecoveryRecommendation) {
            self.customRecoveryRecommendation = savedRec
        }

        let connectedStored = UserDefaults.standard.object(forKey: StorageKeys.isAppleHealthConnected) != nil
            ? UserDefaults.standard.bool(forKey: StorageKeys.isAppleHealthConnected)
            : true
        let syncedStored = UserDefaults.standard.object(forKey: StorageKeys.isAppleHealthSynced) != nil
            ? UserDefaults.standard.bool(forKey: StorageKeys.isAppleHealthSynced)
            : true
        let appleIdStored = UserDefaults.standard.object(forKey: StorageKeys.isAppleIdSignedIn) != nil
            ? UserDefaults.standard.bool(forKey: StorageKeys.isAppleIdSignedIn)
            : true
        self.isAppleHealthConnected = connectedStored
        self.isAppleHealthSynced = syncedStored
        self.isAppleIdSignedIn = appleIdStored

        self.sleepModel.calendarModel = self.calendarModel
        self.sleepModel.isAppleHealthSynced = syncedStored
        if syncedStored {
            self.sleepModel.weeklySleepMinutes = self.sleepModel.currentWeeklySleepMinutes
        }
        self.sleepModel.checkAndPerformDailyResetIfNeeded()
        self.sleepModel.selectDay(at: self.calendarModel.selectedDayIndex)
        self.sleepModel.onStateChanged = { [weak self] in
            self?.evaluateRecovery()
        }
        evaluateRecovery()
    }
    
    // Persists logged workouts to UserDefaults
    public func saveWorkoutsToStorage() {
        if let encoded = try? JSONEncoder().encode(loggedWorkouts) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.savedWorkouts)
        }
    }
    
    // Persists deleted workout identifiers to UserDefaults
    public func saveDeletedWorkoutUUIDsToStorage() {
        let array = deletedWorkoutUUIDs.map { $0.uuidString }
        UserDefaults.standard.set(array, forKey: StorageKeys.deletedWorkoutUUIDs)
    }

    // Persists deleted workout signatures to UserDefaults
    public func saveDeletedWorkoutSignaturesToStorage() {
        let array = Array(deletedWorkoutSignatures)
        UserDefaults.standard.set(array, forKey: StorageKeys.deletedWorkoutSignatures)
    }

    // Persists evaluated readiness status to UserDefaults
    public func saveReadinessToStorage() {
        UserDefaults.standard.set(readinessScore, forKey: StorageKeys.savedReadinessScore)
        UserDefaults.standard.set(_weeklyReadinessScores, forKey: StorageKeys.savedWeeklyReadinessScores)
        UserDefaults.standard.set(qualityScore, forKey: StorageKeys.savedQualityScore)
        UserDefaults.standard.set(_weeklyQualityPercentages, forKey: StorageKeys.savedWeeklyQualityScores)
        UserDefaults.standard.set(sleepDebtValue, forKey: StorageKeys.savedSleepDebtValue)
        UserDefaults.standard.set(regularityMetric.value, forKey: StorageKeys.savedRegularityValue)
        if let rec = customRecoveryRecommendation {
            UserDefaults.standard.set(rec, forKey: StorageKeys.savedRecoveryRecommendation)
        }
    }
    
    public var dynamicThemeColor: Color {
        guard isAppleHealthSynced && readinessScore > 0 else {
            return Color(uiColor: .systemGray)
        }
        switch readinessScore {
        case ..<40.0:
            return Color(red: 0.95, green: 0.26, blue: 0.21)
        case 40.0..<60.0:
            return Color(red: 1.0, green: 0.58, blue: 0.0)
        case 60.0..<80.0:
            return Color(red: 0.96, green: 0.72, blue: 0.0)
        default:
            return Color(red: 0.20, green: 0.78, blue: 0.35)
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
    
    // Returns the date corresponding to a weekday index
    public func dateForDay(at index: Int) -> Date {
        calendarModel.dateForDay(at: index)
    }
    
    // Adds a new workout and syncs it with Apple Health if connected
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
        
        guard health.isAuthorized && isAppleHealthConnected, health.canSaveWorkouts else { return }
        let localID = workout.id
        Task { [weak self] in
            guard let self else { return }
            do {
                let uuid = try await health.saveWorkout(
                    localID: localID,
                    sport: sportType,
                    intensity: intensity,
                    start: scheduledDate,
                    durationMinutes: durationMinutes,
                    focusArea: focusArea,
                    rpe: rpe,
                    notes: notes
                )
                if deletedWorkoutUUIDs.contains(localID) {
                    if let uuid {
                        deletedWorkoutUUIDs.insert(uuid)
                        saveDeletedWorkoutUUIDsToStorage()
                        try? await health.deleteWorkout(uuid: uuid)
                    }
                    return
                }
                if let uuid, let index = loggedWorkouts.firstIndex(where: { $0.id == localID }) {
                    loggedWorkouts[index].healthKitUUID = uuid
                    saveWorkoutsToStorage()
                }
                await performHealthDataSync()
            } catch {
                print("Saving workout to Apple Health failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Updates an existing workout record and refreshes recovery
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
    
    // Deletes a workout locally and removes it from Apple Health
    public func deleteWorkout(id: UUID) {
        var healthKitUUIDToDelete: UUID? = nil
        var signatureToDelete: String? = nil
        if let workout = loggedWorkouts.first(where: { $0.id == id }) {
            healthKitUUIDToDelete = workout.healthKitUUID
            signatureToDelete = Self.workoutSignature(
                sport: workout.sportType,
                start: workout.scheduledDate,
                duration: workout.durationMinutes
            )
        }
        
        deletedWorkoutUUIDs.insert(id)
        if let hkUUID = healthKitUUIDToDelete {
            deletedWorkoutUUIDs.insert(hkUUID)
        }
        saveDeletedWorkoutUUIDsToStorage()
        
        if let sig = signatureToDelete {
            deletedWorkoutSignatures.insert(sig)
            saveDeletedWorkoutSignaturesToStorage()
        }
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            loggedWorkouts.removeAll {
                let sig = Self.workoutSignature(sport: $0.sportType, start: $0.scheduledDate, duration: $0.durationMinutes)
                let isMatch = $0.id == id ||
                    ($0.healthKitUUID != nil && $0.healthKitUUID == healthKitUUIDToDelete) ||
                    (signatureToDelete != nil && sig == signatureToDelete)
                return isMatch
            }
            evaluateRecovery()
        }
        saveWorkoutsToStorage()
        HapticManager.notification(.success)
        
        if health.isAuthorized && health.canSaveWorkouts {
            let hkUUID = healthKitUUIDToDelete
            Task { [weak self] in
                if let hkUUID {
                    try? await self?.health.deleteWorkout(uuid: hkUUID)
                }
                try? await self?.health.deleteWorkout(localID: id)
            }
        }
    }
    
    // Toggles selection for a training intensity level
    public func selectIntensity(_ level: IntensityLevel) {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if selectedIntensity == level {
                selectedIntensity = nil
            } else {
                selectedIntensity = level
            }
        }
    }
    
    // Selects a calendar day and re-evaluates recovery metrics
    public func selectDay(at index: Int) {
        guard index >= 0 && index < days.count else { return }
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            calendarModel.selectDay(at: index)
            sleepModel.selectDay(at: index)
            if index >= 0 && index < _weeklyReadinessScores.count && _weeklyReadinessScores[index] > 0 {
                self.readinessScore = _weeklyReadinessScores[index]
            }
            if index >= 0 && index < _weeklyQualityPercentages.count && _weeklyQualityPercentages[index] > 0 {
                self.qualityScore = _weeklyQualityPercentages[index]
            }
            evaluateRecovery()
        }
    }
    
    // Switches the active navigation tab
    public func selectTab(_ tab: AppTab) {
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedTab = tab
        }
    }
    
    // Manually sets the readiness score
    public func setReadinessScore(_ score: Double) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            readinessScore = max(0, min(100, score))
            customRecoveryRecommendation = nil
        }
    }
    
    // Evaluates recovery and readiness using current sleep, checkmarks, and workouts
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
                    self._weeklyReadinessScores = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
                } else if selectedDayIndex >= 0 && selectedDayIndex < _weeklyQualityPercentages.count {
                    self._weeklyQualityPercentages[selectedDayIndex] = 0
                    self._weeklyReadinessScores[selectedDayIndex] = 0.0
                }
                saveReadinessToStorage()
            }
            return
        }
        
        let workoutsAsHealth = loggedWorkouts.map { $0.toHealthWorkout() }
        let currentNight = sleepModel.currentDaySleepNight()
        let recentNights = sleepModel.toSleepNights()
        
        let targetDate = dateForDay(at: selectedDayIndex)
        let evalDate: Date
        if Calendar.current.isDateInToday(targetDate) {
            evalDate = Date()
        } else {
            let cal = Calendar.current
            evalDate = cal.date(bySettingHour: 23, minute: 59, second: 59, of: targetDate) ?? targetDate
        }
        
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
            evaluationDate: evalDate
        )
        
        let result = RecoveryAlgorithm.evaluate(input: input)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.readinessScore = result.readinessScore
            self.qualityScore = result.qualityScore
            self._customQualityValue = nil
            self.sleepDebtValue = result.sleepDebtFormatted
            self.regularityMetric = SecondaryMetric(title: "Regularity", value: result.regularityStatus)
            self.customRecoveryRecommendation = result.recoveryRecommendation
            
            if selectedDayIndex >= 0 && selectedDayIndex < _weeklyReadinessScores.count {
                self._weeklyReadinessScores[selectedDayIndex] = result.readinessScore
            }
            if selectedDayIndex >= 0 && selectedDayIndex < _weeklyQualityPercentages.count {
                self._weeklyQualityPercentages[selectedDayIndex] = result.qualityScore
            }
            saveReadinessToStorage()
        }
    }
    
    // Evaluates recovery output for a specific weekday index
    public func evaluateRecovery(for dayIndex: Int) -> RecoveryResult? {
        guard dayIndex >= 0 && dayIndex < days.count else { return nil }
        guard !calendarModel.isDayIndexInFuture(dayIndex) && isAppleHealthSynced else { return nil }
        
        let workoutsAsHealth = loggedWorkouts.map { $0.toHealthWorkout() }
        let targetDate = dateForDay(at: dayIndex)
        let evalDate: Date
        if Calendar.current.isDateInToday(targetDate) {
            evalDate = Date()
        } else {
            let cal = Calendar.current
            evalDate = cal.date(bySettingHour: 23, minute: 59, second: 59, of: targetDate) ?? targetDate
        }
        
        let recordChecks = (dayIndex < sleepModel.weeklyRecords.count)
            ? sleepModel.weeklyRecords[dayIndex].checkmarks
            : sleepModel.checkmarks
        
        let currentNight = sleepModel.sleepNight(for: dayIndex)
        let recentNights = sleepModel.toSleepNights()
        
        let input = RecoveryInput(
            currentNight: currentNight,
            recentNights: recentNights,
            targetSleepHours: sleepModel.targetSleepHours,
            checkmarks: recordChecks,
            restingHeartRate: latestRHR,
            restingHeartRateBaseline: baselineRHR,
            heartRateVariability: latestHRV,
            heartRateVariabilityBaseline: baselineHRV,
            recentWorkouts: workoutsAsHealth,
            evaluationDate: evalDate
        )
        return RecoveryAlgorithm.evaluate(input: input)
    }
    
    // Evaluates recovery and readiness for all days in the current week
    public func evaluateAllDaysRecovery() {
        guard isAppleHealthSynced else {
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                _weeklyReadinessScores = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
                _weeklyQualityPercentages = [0, 0, 0, 0, 0, 0, 0]
                readinessScore = 0.0
                qualityScore = 0
                saveReadinessToStorage()
            }
            return
        }
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            for i in 0..<7 {
                if calendarModel.isDayIndexInFuture(i) {
                    _weeklyReadinessScores[i] = 0.0
                    _weeklyQualityPercentages[i] = 0
                } else if let result = evaluateRecovery(for: i) {
                    _weeklyReadinessScores[i] = result.readinessScore
                    _weeklyQualityPercentages[i] = result.qualityScore
                }
            }
            evaluateRecovery()
        }
    }
    
    // Updates profile user name and persists it
    public func updateUserName(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userName = trimmed
        UserDefaults.standard.set(trimmed, forKey: "AppleIDUserName")
        triggerSelectionHaptic()
    }
    
    // Updates user preferred sport type
    public func updateSportType(_ newSport: String) {
        sportType = newSport
        triggerSelectionHaptic()
    }
    
    // Adds a custom sport option to profile settings
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
    
    // Updates user training experience level
    public func updateTrainingLevel(_ newLevel: String) {
        trainingLevel = newLevel
        triggerSelectionHaptic()
    }
    
    // Updates weekly workout frequency goal
    public func updateWeeklyFrequency(_ newFrequency: String) {
        weeklyFrequency = newFrequency
        triggerSelectionHaptic()
    }
    
    // Updates user gender selection
    public func updateGender(_ newGender: String) {
        gender = newGender
        triggerSelectionHaptic()
    }
    
    // Updates user body weight
    public func updateWeight(_ newWeight: String) {
        weight = newWeight
        triggerSelectionHaptic()
    }
    
    // Updates user body height
    public func updateHeight(_ newHeight: String) {
        height = newHeight
        triggerSelectionHaptic()
    }
    
    // Updates user profile icon and background color
    public func updateProfileAvatar(icon: String, color: Color) {
        profileAvatarIcon = icon
        profileAvatarColor = color
        triggerSelectionHaptic()
    }
    
    // Updates custom profile avatar image data
    public func updateProfileCustomImageData(_ data: Data?) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            profileCustomImageData = data
        }
        triggerSelectionHaptic()
    }
    
    // Initiates Sign in with Apple flow
    public func startAppleSignIn() {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.isAppleIdSignedIn = true
        }
        
        HapticManager.notification(.success)
    }
    // Resolves stored user display name or fallback default
    public static func resolveUserDisplayName() -> String {
        if let saved = UserDefaults.standard.string(forKey: "AppleIDUserName")?.trimmingCharacters(in: .whitespaces),
           !saved.isEmpty, saved != "-" {
            return saved
        }
        return "User"
    }
    
    // Handles Apple ID credential completion and extracts user details
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
    
    // Disconnects Apple Health synchronization and clears stored metrics
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
    
    // Signs out of Apple ID and restores default profile name
    public func signOutAppleId() {
        removeHealthSync()
    }
    
    // Toggles Apple ID authentication status
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
    
    // Triggers haptic feedback on selection change
    private func triggerSelectionHaptic() {
        HapticManager.impact(.light)
    }
}
