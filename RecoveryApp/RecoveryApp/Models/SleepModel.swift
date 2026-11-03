import SwiftUI
import Observation

// MARK: - Meridiem Period (AM / PM)
public enum MeridiemPeriod: String, CaseIterable, Identifiable, Codable {
    case am = "AM"
    case pm = "PM"
    
    public var id: String { rawValue }
}

// MARK: - Sleep Checkmark Item
public struct SleepCheckmarkItem: Identifiable, Hashable, Codable {
    public let id: UUID
    public var title: String
    public var isChecked: Bool
    public var isManuallySet: Bool
    
    public init(id: UUID = UUID(), title: String, isChecked: Bool = false, isManuallySet: Bool = false) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
        self.isManuallySet = isManuallySet
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, isChecked, isManuallySet
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.isChecked = try container.decode(Bool.self, forKey: .isChecked)
        self.isManuallySet = try container.decodeIfPresent(Bool.self, forKey: .isManuallySet) ?? false
    }
}

// MARK: - Day Sleep Record
public struct DaySleepRecord: Hashable, Codable {
    public var inBedHour: Int
    public var inBedMinute: Int
    public var inBedPeriod: MeridiemPeriod
    public var asleepHour: Int
    public var asleepMinute: Int
    public var asleepPeriod: MeridiemPeriod
    public var checkmarks: [SleepCheckmarkItem]
    public var healthAsleepMinutes: Int? = nil
    public var isManualSchedule: Bool = false
    
    public init(
        inBedHour: Int,
        inBedMinute: Int,
        inBedPeriod: MeridiemPeriod,
        asleepHour: Int,
        asleepMinute: Int,
        asleepPeriod: MeridiemPeriod,
        checkmarks: [SleepCheckmarkItem],
        healthAsleepMinutes: Int? = nil,
        isManualSchedule: Bool = false
    ) {
        self.inBedHour = inBedHour
        self.inBedMinute = inBedMinute
        self.inBedPeriod = inBedPeriod
        self.asleepHour = asleepHour
        self.asleepMinute = asleepMinute
        self.asleepPeriod = asleepPeriod
        self.checkmarks = checkmarks
        self.healthAsleepMinutes = healthAsleepMinutes
        self.isManualSchedule = isManualSchedule
    }
    
    enum CodingKeys: String, CodingKey {
        case inBedHour, inBedMinute, inBedPeriod, asleepHour, asleepMinute, asleepPeriod, checkmarks, healthAsleepMinutes, isManualSchedule
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inBedHour = try container.decode(Int.self, forKey: .inBedHour)
        self.inBedMinute = try container.decode(Int.self, forKey: .inBedMinute)
        self.inBedPeriod = try container.decode(MeridiemPeriod.self, forKey: .inBedPeriod)
        self.asleepHour = try container.decode(Int.self, forKey: .asleepHour)
        self.asleepMinute = try container.decode(Int.self, forKey: .asleepMinute)
        self.asleepPeriod = try container.decode(MeridiemPeriod.self, forKey: .asleepPeriod)
        self.checkmarks = try container.decode([SleepCheckmarkItem].self, forKey: .checkmarks)
        self.healthAsleepMinutes = try container.decodeIfPresent(Int.self, forKey: .healthAsleepMinutes)
        self.isManualSchedule = try container.decodeIfPresent(Bool.self, forKey: .isManualSchedule) ?? false
    }
}

// MARK: - Sleep Model Observable State
@Observable
public final class SleepModel {
    
    // Callback invoked whenever sleep duration, bedtime, goal, or checkmarks are modified
    public var onStateChanged: (() -> Void)? = nil
    
    // MARK: - Shared Calendar Model Reference
    public var calendarModel: CalendarModel? = nil
    
    // MARK: - Apple Health Sync State
    public var isAppleHealthSynced: Bool = false
    
    // MARK: - Theme & Header
    public var title: String = "Sleep"
    public var currentDaySubtitle: String {
        calendarModel?.currentDaySubtitle ?? "Today"
    }
    public var selectedDayIndex: Int = 0
    
    // MARK: - Future Day Check Helpers
    public func isDayIndexInFuture(_ index: Int) -> Bool {
        if let calendarModel {
            return calendarModel.isDayIndexInFuture(index)
        }
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let todayIndex = (weekday + 5) % 7
        return index > todayIndex
    }
    
    public var isSelectedDayInFuture: Bool {
        isDayIndexInFuture(selectedDayIndex)
    }
    
    public var isSelectedDayManualSchedule: Bool {
        guard selectedDayIndex >= 0 && selectedDayIndex < weeklyRecords.count else { return false }
        return weeklyRecords[selectedDayIndex].isManualSchedule
    }
    
    // Accent Color: royal indigo (#535DFF) matching design mockup
    public var accentColor: Color = Color(red: 0.33, green: 0.36, blue: 1.0)
    public var trackColor: Color = Color(red: 0.83, green: 0.83, blue: 0.95)
    
    // MARK: - Sleep Goal / Target (Configurable by user)
    public var targetSleepHours: Double = 8.0 // in hours (e.g. 7.5 = 7h 30m, 8.0 = 8h)
    
    public var targetDurationFormatted: String {
        let targetH = Int(targetSleepHours)
        let targetM = Int(round((targetSleepHours - Double(targetH)) * 60))
        if targetM == 0 {
            return "of \(targetH)h"
        } else {
            return "of \(targetH)h \(targetM)m"
        }
    }
    
    public var targetDurationSimpleFormatted: String {
        let targetH = Int(targetSleepHours)
        let targetM = Int(round((targetSleepHours - Double(targetH)) * 60))
        if targetM == 0 {
            return "\(targetH)h"
        } else {
            return "\(targetH)h \(targetM)m"
        }
    }
    
    // MARK: - Weekly Sleep Tracking (Current Week: Mon - Sun)
    // When opened without syncing Apple Health, all values default to zero
    public var weeklySleepMinutes: [Int] = [0, 0, 0, 0, 0, 0, 0]
    
    // 7-day individual records for full schedule and checkmark persistence (defaults to all unchecked)
    public var weeklyRecords: [DaySleepRecord] = [
        DaySleepRecord(inBedHour: 0, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 0, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false)
        ]),
        DaySleepRecord(inBedHour: 0, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 0, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false)
        ]),
        DaySleepRecord(inBedHour: 0, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 0, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false)
        ]),
        DaySleepRecord(inBedHour: 0, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 0, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false)
        ]),
        DaySleepRecord(inBedHour: 0, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 0, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false)
        ]),
        DaySleepRecord(inBedHour: 0, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 0, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false)
        ]),
        DaySleepRecord(inBedHour: 0, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 0, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false)
        ])
    ]
    
    public var currentWeeklySleepMinutes: [Int] {
        guard isAppleHealthSynced else { return [0, 0, 0, 0, 0, 0, 0] }
        var list = weeklySleepMinutes
        for i in 0..<list.count {
            if isDayIndexInFuture(i) {
                list[i] = 0
            }
        }
        if selectedDayIndex >= 0 && selectedDayIndex < list.count {
            if durationMinutes > 0 {
                list[selectedDayIndex] = durationMinutes
            }
        }
        return list
    }
    
    public var weeklyAverageMinutes: Int {
        guard isAppleHealthSynced else { return 0 }
        let nonFuture = (0..<currentWeeklySleepMinutes.count).filter { !isDayIndexInFuture($0) }
        guard !nonFuture.isEmpty else { return durationMinutes }
        let sum = nonFuture.map { currentWeeklySleepMinutes[$0] }.reduce(0, +)
        return sum / nonFuture.count
    }
    
    public var weeklyAverageFormatted: String {
        guard isAppleHealthSynced && weeklyAverageMinutes > 0 else { return "0h 00m" }
        let h = weeklyAverageMinutes / 60
        let m = weeklyAverageMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
    
    public var daysMeetingTargetCount: Int {
        guard isAppleHealthSynced else { return 0 }
        let targetMins = Int(targetSleepHours * 60.0)
        guard targetMins > 0 else { return 0 }
        let nonFuture = (0..<currentWeeklySleepMinutes.count).filter { !isDayIndexInFuture($0) }
        return nonFuture.filter { currentWeeklySleepMinutes[$0] >= targetMins }.count
    }
    
    public var weeklySleepProgress: Double {
        guard isAppleHealthSynced && weeklyAverageMinutes > 0 else { return 0.0 }
        let targetMins = targetSleepHours * 60.0
        guard targetMins > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(weeklyAverageMinutes) / targetMins))
    }
    
    // MARK: - Bedtime & Wakeup Schedule (Defaults to uninitialized / 0 until synced)
    public var inBedHour: Int = 0
    public var inBedMinute: Int = 0
    public var inBedPeriod: MeridiemPeriod = .pm
    
    public var asleepHour: Int = 0
    public var asleepMinute: Int = 0
    public var asleepPeriod: MeridiemPeriod = .am
    
    public var inBedTimeFormatted: String {
        guard inBedHour > 0 || inBedMinute > 0 else { return "--:--" }
        return String(format: "%d:%02d", inBedHour, inBedMinute)
    }
    
    public var asleepTimeFormatted: String {
        guard asleepHour > 0 || asleepMinute > 0 else { return "--:--" }
        return String(format: "%d:%02d", asleepHour, asleepMinute)
    }
    
    public var inBedFullTimeFormatted: String {
        guard inBedHour > 0 || inBedMinute > 0 else { return "--:--" }
        return "\(inBedTimeFormatted) \(inBedPeriod.rawValue)"
    }
    
    public var asleepFullTimeFormatted: String {
        guard asleepHour > 0 || asleepMinute > 0 else { return "--:--" }
        return "\(asleepTimeFormatted) \(asleepPeriod.rawValue)"
    }
    
    // MARK: - Apple Health Data
    /// Real minutes asleep read from Apple Health (nil = computed from the schedule)
    public var healthAsleepMinutes: Int? = nil
    public var isFromAppleHealth: Bool { healthAsleepMinutes != nil }
    
    /// Fills bedtime / wake-up time and duration with a night read from HealthKit.
    public func apply(night: SleepNight?) {
        guard let night else { return }
        let calendar = Calendar.current
        let bed = calendar.dateComponents([.hour, .minute], from: night.bedtime)
        let wake = calendar.dateComponents([.hour, .minute], from: night.wakeTime)
        let (bedH, bedP) = Self.to12h(bed.hour ?? 0)
        let (wakeH, wakeP) = Self.to12h(wake.hour ?? 0)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            inBedHour = bedH
            inBedMinute = bed.minute ?? 0
            inBedPeriod = bedP
            asleepHour = wakeH
            asleepMinute = wake.minute ?? 0
            asleepPeriod = wakeP
            healthAsleepMinutes = night.asleepMinutes
            updateBedtimeCheckmarkCompliance()
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    private static func to12h(_ hour24: Int) -> (Int, MeridiemPeriod) {
        let period: MeridiemPeriod = hour24 >= 12 ? .pm : .am
        let h = hour24 % 12
        return (h == 0 ? 12 : h, period)
    }
    
    // MARK: - Dynamic Sleep Duration Calculations
    public var durationMinutes: Int {
        if isSelectedDayInFuture || !isAppleHealthSynced { return 0 }
        
        // If the user manually edited this day's schedule, calculate duration directly from bedtime & wake time
        if selectedDayIndex >= 0 && selectedDayIndex < weeklyRecords.count && weeklyRecords[selectedDayIndex].isManualSchedule {
            guard inBedHour > 0 || asleepHour > 0 else { return 0 }
            let bedMins = toMinutesFromMidnight(hour: inBedHour, minute: inBedMinute, period: inBedPeriod)
            let wakeMins = toMinutesFromMidnight(hour: asleepHour, minute: asleepMinute, period: asleepPeriod)
            if wakeMins >= bedMins {
                return wakeMins - bedMins
            } else {
                return (24 * 60 - bedMins) + wakeMins
            }
        }
        
        // Untouched Apple Health measured sleep stage minutes (asleep time)
        if let healthAsleepMinutes, healthAsleepMinutes > 0 { return healthAsleepMinutes }
        if selectedDayIndex >= 0 && selectedDayIndex < weeklyRecords.count,
           let recordMins = weeklyRecords[selectedDayIndex].healthAsleepMinutes, recordMins > 0 {
            return recordMins
        }
        
        // Bedtime & wake time schedule calculation
        guard inBedHour > 0 || asleepHour > 0 else {
            if selectedDayIndex >= 0 && selectedDayIndex < weeklySleepMinutes.count,
               weeklySleepMinutes[selectedDayIndex] > 0 {
                return weeklySleepMinutes[selectedDayIndex]
            }
            return 0
        }
        let bedMins = toMinutesFromMidnight(hour: inBedHour, minute: inBedMinute, period: inBedPeriod)
        let wakeMins = toMinutesFromMidnight(hour: asleepHour, minute: asleepMinute, period: asleepPeriod)
        
        if wakeMins >= bedMins {
            return wakeMins - bedMins
        } else {
            return (24 * 60 - bedMins) + wakeMins
        }
    }
    
    public var hoursSlept: Int {
        durationMinutes / 60
    }
    
    public var minutesSlept: Int {
        durationMinutes % 60
    }
    
    public var sleepDurationFormatted: String {
        if hoursSlept == 0 && minutesSlept == 0 {
            return "0h 00m"
        } else if minutesSlept == 0 {
            return "\(hoursSlept)h 00m"
        } else {
            return "\(hoursSlept)h \(minutesSlept)m"
        }
    }
    
    /// Visual fraction of the ring (0.0 ... 1.0) proportional to user target sleep
    public var ringProgress: Double {
        guard isAppleHealthSynced && durationMinutes > 0 else { return 0.0 }
        let targetMins = targetSleepHours * 60.0
        guard targetMins > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(durationMinutes) / targetMins))
    }
    
    // MARK: - Storage Keys
    private enum StorageKeys {
        static let lastCheckmarksResetDate = "RecoveryApp_lastCheckmarksResetDate"
        static let savedWeeklyRecords = "RecoveryApp_savedWeeklySleepRecords"
    }
    
    // MARK: - Persistent Storage Helpers
    public func saveWeeklyRecordsToStorage() {
        if let encoded = try? JSONEncoder().encode(weeklyRecords) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.savedWeeklyRecords)
        }
    }
    
    @discardableResult
    public func restoreWeeklyRecordsFromStorage() -> Bool {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.savedWeeklyRecords),
           let decoded = try? JSONDecoder().decode([DaySleepRecord].self, from: data),
           decoded.count == 7 {
            self.weeklyRecords = decoded
            return true
        }
        return false
    }
    
    // MARK: - Recommendations & Checkmarks (Defaults to false: refreshed fresh each day)
    public var checkmarksSectionTitle: String = "Checkmarks"
    public var checkmarksSubtitle: String = "Based on your weekly workouts and daily routine, we recommend that you:"
    
    public var checkmarks: [SleepCheckmarkItem] = [
        SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false, isManuallySet: false),
        SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false, isManuallySet: false)
    ]
    
    // MARK: - Daily Checkmarks Reset
    public var lastCheckmarksResetDate: Date? {
        get {
            UserDefaults.standard.object(forKey: StorageKeys.lastCheckmarksResetDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: StorageKeys.lastCheckmarksResetDate)
        }
    }
    
    /// Verifies if a new day has started; if so, resets all checkmarks to false.
    public func checkAndPerformDailyResetIfNeeded() {
        let calendar = Calendar.current
        if let lastReset = lastCheckmarksResetDate {
            if !calendar.isDateInToday(lastReset) {
                resetCheckmarksForNewDay()
            }
        } else {
            resetCheckmarksForNewDay()
        }
    }
    
    /// Forces resetting all checkmarks to false and updates timestamp to today.
    public func resetCheckmarksForNewDay() {
        for i in 0..<checkmarks.count {
            checkmarks[i].isChecked = false
            checkmarks[i].isManuallySet = false
        }
        for d in 0..<weeklyRecords.count {
            for c in 0..<weeklyRecords[d].checkmarks.count {
                weeklyRecords[d].checkmarks[c].isChecked = false
                weeklyRecords[d].checkmarks[c].isManuallySet = false
            }
        }
        lastCheckmarksResetDate = Date()
        syncCurrentToRecord()
        onStateChanged?()
    }
    
    // MARK: - Bedtime Checkmark Auto-Evaluation
    /// If sleep data indicates going to bed late (at 23:00 or after 22:15), uncheck the box unless manually set by the user.
    public func updateBedtimeCheckmarkCompliance() {
        guard let index = checkmarks.firstIndex(where: {
            $0.title.localizedCaseInsensitiveContains("22:00") ||
            $0.title.localizedCaseInsensitiveContains("bed at 22")
        }) else { return }
        
        // Never override a checkmark that was explicitly toggled by the user
        guard !checkmarks[index].isManuallySet else { return }
        
        // If uninitialized / 0 / no bedtime set, do not force checkmark to true
        guard inBedHour > 0 || asleepHour > 0 else { return }
        
        var hour24 = inBedHour % 12
        if inBedPeriod == .pm { hour24 += 12 }
        
        // Bedtime at 23:00 or later (including past midnight) does NOT meet 22:00 target
        let isLateBedtime = (hour24 >= 23 || (hour24 == 22 && inBedMinute > 15) || hour24 < 12)
        if isLateBedtime {
            checkmarks[index].isChecked = false
        }
    }
    
    // MARK: - Reset to Zero State
    public func resetToZero() {
        isAppleHealthSynced = false
        healthAsleepMinutes = nil
        weeklySleepMinutes = [0, 0, 0, 0, 0, 0, 0]
        inBedHour = 0
        inBedMinute = 0
        asleepHour = 0
        asleepMinute = 0
        checkmarks = [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false, isManuallySet: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false, isManuallySet: false)
        ]
        weeklyRecords = (0..<7).map { _ in
            DaySleepRecord(
                inBedHour: 0,
                inBedMinute: 0,
                inBedPeriod: .pm,
                asleepHour: 0,
                asleepMinute: 0,
                asleepPeriod: .am,
                checkmarks: [
                    SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false, isManuallySet: false),
                    SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false, isManuallySet: false)
                ]
            )
        }
        UserDefaults.standard.removeObject(forKey: StorageKeys.savedWeeklyRecords)
    }
    
    // MARK: - Initializer
    public init() {
        _ = restoreWeeklyRecordsFromStorage()
        checkAndPerformDailyResetIfNeeded()
        updateBedtimeCheckmarkCompliance()
    }
    
    // MARK: - Schedule & Goal Actions
    public func setInBed(hour: Int, minute: Int, period: MeridiemPeriod) {
        healthAsleepMinutes = nil
        inBedHour = max(1, min(12, hour))
        inBedMinute = max(0, min(59, minute))
        inBedPeriod = period
        if asleepHour == 0 {
            asleepHour = 7
            asleepMinute = 0
            asleepPeriod = .am
        }
        updateBedtimeCheckmarkCompliance()
        syncCurrentToRecord(manual: true)
        onStateChanged?()
    }
    
    public func setAsleep(hour: Int, minute: Int, period: MeridiemPeriod) {
        healthAsleepMinutes = nil
        asleepHour = max(1, min(12, hour))
        asleepMinute = max(0, min(59, minute))
        asleepPeriod = period
        if inBedHour == 0 {
            inBedHour = 10
            inBedMinute = 0
            inBedPeriod = .pm
        }
        syncCurrentToRecord(manual: true)
        onStateChanged?()
    }
    
    public func setInBedPeriod(_ period: MeridiemPeriod) {
        guard inBedPeriod != period else { return }
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            inBedPeriod = period
            healthAsleepMinutes = nil
            updateBedtimeCheckmarkCompliance()
            syncCurrentToRecord(manual: true)
        }
        onStateChanged?()
    }
    
    public func setAsleepPeriod(_ period: MeridiemPeriod) {
        guard asleepPeriod != period else { return }
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            asleepPeriod = period
            healthAsleepMinutes = nil
            syncCurrentToRecord(manual: true)
        }
        onStateChanged?()
    }
    
    public func toggleInBedPeriod() {
        setInBedPeriod((inBedPeriod == .am) ? .pm : .am)
    }
    
    public func toggleAsleepPeriod() {
        setAsleepPeriod((asleepPeriod == .am) ? .pm : .am)
    }
    
    public func setTargetSleepHours(_ hours: Double) {
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            targetSleepHours = max(4.0, min(14.0, hours))
        }
        onStateChanged?()
    }
    
    // MARK: - Checkmark Actions
    public func toggleCheckmark(id: UUID) {
        HapticManager.impact(.light)
        
        if let index = checkmarks.firstIndex(where: { $0.id == id }) {
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                checkmarks[index].isChecked.toggle()
                checkmarks[index].isManuallySet = true
                syncCurrentToRecord()
            }
            onStateChanged?()
        }
    }
    
    public func addCheckmark(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        HapticManager.notification(.success)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.append(SleepCheckmarkItem(title: trimmed, isChecked: true, isManuallySet: true))
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    public func updateCheckmark(id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let index = checkmarks.firstIndex(where: { $0.id == id }) {
            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                checkmarks[index].title = trimmed
                syncCurrentToRecord()
            }
            onStateChanged?()
        }
    }
    
    public func deleteCheckmark(id: UUID) {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.removeAll(where: { $0.id == id })
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    public func deleteCheckmarks(at offsets: IndexSet) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.remove(atOffsets: offsets)
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    public func selectDay(at index: Int) {
        guard index >= 0 && index < weeklyRecords.count else { return }
        selectedDayIndex = index
        let record = weeklyRecords[index]
        inBedHour = record.inBedHour
        inBedMinute = record.inBedMinute
        inBedPeriod = record.inBedPeriod
        asleepHour = record.asleepHour
        asleepMinute = record.asleepMinute
        asleepPeriod = record.asleepPeriod
        checkmarks = record.checkmarks
        healthAsleepMinutes = record.isManualSchedule ? nil : record.healthAsleepMinutes
        
        // If times are 0 but we have sleep minutes, construct sensible bedtime & wake-up time
        if (inBedHour == 0 && asleepHour == 0), let minutes = (healthAsleepMinutes ?? (weeklySleepMinutes[index] > 0 ? weeklySleepMinutes[index] : nil)), minutes > 0 {
            let wakeHour = 7
            let wakeMinute = 0
            let wakeTotal = wakeHour * 60 + wakeMinute
            var bedTotal = wakeTotal - minutes
            if bedTotal < 0 { bedTotal += 24 * 60 }
            let bH = bedTotal / 60
            let bM = bedTotal % 60
            let (bHour12, bPeriod) = Self.to12h(bH)
            inBedHour = bHour12
            inBedMinute = bM
            inBedPeriod = bPeriod
            asleepHour = wakeHour
            asleepMinute = wakeMinute
            asleepPeriod = .am
            syncCurrentToRecord()
        }
    }
    
    private func syncCurrentToRecord(manual: Bool = false) {
        guard selectedDayIndex >= 0 && selectedDayIndex < weeklyRecords.count else { return }
        let isManual = manual || weeklyRecords[selectedDayIndex].isManualSchedule
        weeklyRecords[selectedDayIndex] = DaySleepRecord(
            inBedHour: inBedHour,
            inBedMinute: inBedMinute,
            inBedPeriod: inBedPeriod,
            asleepHour: asleepHour,
            asleepMinute: asleepMinute,
            asleepPeriod: asleepPeriod,
            checkmarks: checkmarks,
            healthAsleepMinutes: isManual ? nil : healthAsleepMinutes,
            isManualSchedule: isManual
        )
        let mins = durationMinutes
        if selectedDayIndex < weeklySleepMinutes.count {
            weeklySleepMinutes[selectedDayIndex] = mins
        }
        saveWeeklyRecordsToStorage()
    }
    
    /// Constructs a valid SleepNight for the currently selected day to evaluate recovery dynamically.
    public func currentDaySleepNight() -> SleepNight {
        let asleepMins = durationMinutes
        let day = calendarModel?.selectedDate ?? Date()
        if isSelectedDayInFuture || asleepMins <= 0 {
            return SleepNight(
                day: day,
                bedtime: day,
                wakeTime: day,
                asleepMinutes: 0,
                inBedMinutes: 0,
                deepMinutes: 0,
                remMinutes: 0
            )
        }
        
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let resolvedDay = calendar.date(byAdding: .day, value: selectedDayIndex, to: monday) ?? today
        let previousDay = calendar.date(byAdding: .day, value: -1, to: resolvedDay) ?? resolvedDay
        
        var bedHour24 = inBedHour
        if inBedPeriod == .pm && bedHour24 < 12 { bedHour24 += 12 }
        if inBedPeriod == .am && bedHour24 == 12 { bedHour24 = 0 }
        
        var wakeHour24 = asleepHour
        if asleepPeriod == .pm && wakeHour24 < 12 { wakeHour24 += 12 }
        if asleepPeriod == .am && wakeHour24 == 12 { wakeHour24 = 0 }
        
        // If times are unconfigured but we have sleep minutes, anchor to standard 7:00 AM wake time
        if bedHour24 == 0 && wakeHour24 == 0 && asleepMins > 0 {
            wakeHour24 = 7
            let wakeTotal = 7 * 60
            var bedTotal = wakeTotal - asleepMins
            if bedTotal < 0 { bedTotal += 24 * 60 }
            bedHour24 = bedTotal / 60
        }
        
        let bedtime = calendar.date(bySettingHour: bedHour24, minute: inBedMinute, second: 0, of: previousDay) ?? previousDay
        let wakeTime = calendar.date(bySettingHour: wakeHour24, minute: asleepMinute, second: 0, of: resolvedDay) ?? resolvedDay
        
        let inBedMins = Int((Double(asleepMins) / 0.90).rounded())
        let deepMins = Int((Double(asleepMins) * 0.18).rounded())
        let remMins = Int((Double(asleepMins) * 0.20).rounded())
        
        return SleepNight(
            day: resolvedDay,
            bedtime: bedtime,
            wakeTime: wakeTime,
            asleepMinutes: asleepMins,
            inBedMinutes: inBedMins,
            deepMinutes: deepMins,
            remMinutes: remMins
        )
    }
    
    // MARK: - Private Time Utilities
    private func toMinutesFromMidnight(hour: Int, minute: Int, period: MeridiemPeriod) -> Int {
        var h = hour % 12
        if period == .pm {
            h += 12
        }
        return h * 60 + minute
    }
}
