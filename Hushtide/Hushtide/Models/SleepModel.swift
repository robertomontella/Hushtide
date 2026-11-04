import SwiftUI
import Observation

public enum MeridiemPeriod: String, CaseIterable, Identifiable, Codable {
    case am = "AM"
    case pm = "PM"
    
    public var id: String { rawValue }
}

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

@Observable
public final class SleepModel {
    
    public var onStateChanged: (() -> Void)? = nil
    
    public var calendarModel: CalendarModel? = nil
    
    public var isAppleHealthSynced: Bool = false {
        didSet {
            if isAppleHealthSynced {
                weeklySleepMinutes = currentWeeklySleepMinutes
            }
        }
    }
    
    public var title: String = "Sleep"
    public var currentDaySubtitle: String {
        calendarModel?.currentDaySubtitle ?? "Today"
    }
    public var selectedDayIndex: Int = 0
    
    // Checks whether the weekday index represents a future calendar day
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
    
    public var accentColor: Color = Color(red: 0.33, green: 0.36, blue: 1.0)
    public var trackColor: Color = Color(red: 0.83, green: 0.83, blue: 0.95)
    
    public var targetSleepHours: Double = 8.0
    
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
    
    public var weeklySleepMinutes: [Int] = [0, 0, 0, 0, 0, 0, 0]
    
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
    
    // Calculates total sleep duration in minutes for a specific weekday index
    public func durationMinutes(for dayIndex: Int) -> Int {
        guard dayIndex >= 0 && dayIndex < weeklyRecords.count else { return 0 }
        if isDayIndexInFuture(dayIndex) || !isAppleHealthSynced { return 0 }
        
        if dayIndex == selectedDayIndex {
            return durationMinutes
        }
        
        let record = weeklyRecords[dayIndex]
        if record.isManualSchedule {
            guard record.inBedHour > 0 || record.asleepHour > 0 else { return 0 }
            let bedMins = toMinutesFromMidnight(hour: record.inBedHour, minute: record.inBedMinute, period: record.inBedPeriod)
            let wakeMins = toMinutesFromMidnight(hour: record.asleepHour, minute: record.asleepMinute, period: record.asleepPeriod)
            if wakeMins >= bedMins {
                return wakeMins - bedMins
            } else {
                return (24 * 60 - bedMins) + wakeMins
            }
        }
        
        if let health = record.healthAsleepMinutes, health > 0 {
            return health
        }
        
        if record.inBedHour > 0 || record.asleepHour > 0 {
            let bedMins = toMinutesFromMidnight(hour: record.inBedHour, minute: record.inBedMinute, period: record.inBedPeriod)
            let wakeMins = toMinutesFromMidnight(hour: record.asleepHour, minute: record.asleepMinute, period: record.asleepPeriod)
            if wakeMins >= bedMins {
                return wakeMins - bedMins
            } else {
                return (24 * 60 - bedMins) + wakeMins
            }
        }
        
        if dayIndex < weeklySleepMinutes.count && weeklySleepMinutes[dayIndex] > 0 {
            return weeklySleepMinutes[dayIndex]
        }
        
        return 0
    }
    
    public var currentWeeklySleepMinutes: [Int] {
        guard isAppleHealthSynced else { return [0, 0, 0, 0, 0, 0, 0] }
        return (0..<weeklyRecords.count).map { durationMinutes(for: $0) }
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
    
    public var healthAsleepMinutes: Int? = nil
    public var isFromAppleHealth: Bool { healthAsleepMinutes != nil }
    
    // Populates bedtime, wake time, and duration from a HealthKit sleep night
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
    
    // Converts 24-hour time into 12-hour format with AM or PM period
    private static func to12h(_ hour24: Int) -> (Int, MeridiemPeriod) {
        let period: MeridiemPeriod = hour24 >= 12 ? .pm : .am
        let h = hour24 % 12
        return (h == 0 ? 12 : h, period)
    }
    
    public var durationMinutes: Int {
        if isSelectedDayInFuture || !isAppleHealthSynced { return 0 }
        
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
        
        if let healthAsleepMinutes, healthAsleepMinutes > 0 { return healthAsleepMinutes }
        if selectedDayIndex >= 0 && selectedDayIndex < weeklyRecords.count,
           let recordMins = weeklyRecords[selectedDayIndex].healthAsleepMinutes, recordMins > 0 {
            return recordMins
        }
        
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
    
    public var ringProgress: Double {
        guard isAppleHealthSynced && durationMinutes > 0 else { return 0.0 }
        let targetMins = targetSleepHours * 60.0
        guard targetMins > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(durationMinutes) / targetMins))
    }
    
    private enum StorageKeys {
        static let lastCheckmarksResetDate = "RecoveryApp_lastCheckmarksResetDate"
        static let savedWeeklyRecords = "RecoveryApp_savedWeeklySleepRecords"
        static let targetSleepHours = "RecoveryApp_targetSleepHours"
    }
    
    // Persists weekly sleep records to UserDefaults
    public func saveWeeklyRecordsToStorage() {
        if let encoded = try? JSONEncoder().encode(weeklyRecords) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.savedWeeklyRecords)
        }
    }
    
    @discardableResult
    // Loads saved weekly sleep records from UserDefaults
    public func restoreWeeklyRecordsFromStorage() -> Bool {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.savedWeeklyRecords),
           let decoded = try? JSONDecoder().decode([DaySleepRecord].self, from: data),
           decoded.count == 7 {
            self.weeklyRecords = decoded
            self.weeklySleepMinutes = (0..<7).map { durationMinutes(for: $0) }
            return true
        }
        return false
    }
    
    public var checkmarksSectionTitle: String = "Checkmarks"
    public var checkmarksSubtitle: String = "Based on your weekly workouts and daily routine, we recommend that you:"
    
    public var checkmarks: [SleepCheckmarkItem] = [
        SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false, isManuallySet: false),
        SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: false, isManuallySet: false)
    ]
    
    public var lastCheckmarksResetDate: Date? {
        get {
            UserDefaults.standard.object(forKey: StorageKeys.lastCheckmarksResetDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: StorageKeys.lastCheckmarksResetDate)
        }
    }
    
    // Resets sleep checkmarks if a new day has started
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
    
    // Clears all checkmarks for the current day and updates timestamp
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
    
    // Checks whether bedtime meets target and updates checkmark compliance
    public func updateBedtimeCheckmarkCompliance() {
        guard let index = checkmarks.firstIndex(where: {
            $0.title.localizedCaseInsensitiveContains("22:00") ||
            $0.title.localizedCaseInsensitiveContains("bed at 22")
        }) else { return }
        
        guard !checkmarks[index].isManuallySet else { return }
        
        guard inBedHour > 0 || asleepHour > 0 else { return }
        
        var hour24 = inBedHour % 12
        if inBedPeriod == .pm { hour24 += 12 }
        
        let isLateBedtime = (hour24 >= 23 || (hour24 == 22 && inBedMinute > 15) || hour24 < 12)
        if isLateBedtime {
            checkmarks[index].isChecked = false
        }
    }
    
    // Resets all sleep metrics, schedules, and checkmarks to zero
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
    
    public init() {
        if let savedGoal = UserDefaults.standard.object(forKey: StorageKeys.targetSleepHours) as? Double, savedGoal > 0 {
            self.targetSleepHours = savedGoal
        }
        _ = restoreWeeklyRecordsFromStorage()
        checkAndPerformDailyResetIfNeeded()
        updateBedtimeCheckmarkCompliance()
    }
    
    // Updates bedtime schedule and recalculates sleep duration
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
    
    // Updates wake-up schedule and recalculates sleep duration
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
    
    // Updates bedtime AM or PM period
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
    
    // Updates wake-up AM or PM period
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
    
    // Toggles bedtime between AM and PM
    public func toggleInBedPeriod() {
        setInBedPeriod((inBedPeriod == .am) ? .pm : .am)
    }
    
    // Toggles wake-up time between AM and PM
    public func toggleAsleepPeriod() {
        setAsleepPeriod((asleepPeriod == .am) ? .pm : .am)
    }
    
    // Updates sleep target hours and persists to storage
    public func setTargetSleepHours(_ hours: Double) {
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            targetSleepHours = max(4.0, min(14.0, hours))
            UserDefaults.standard.set(targetSleepHours, forKey: StorageKeys.targetSleepHours)
        }
        onStateChanged?()
    }
    
    // Toggles completion status of a sleep checkmark item
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
    
    // Adds a new custom sleep hygiene checkmark
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
    
    // Updates the title of an existing checkmark item
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
    
    // Removes a sleep checkmark item by identifier
    public func deleteCheckmark(id: UUID) {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.removeAll(where: { $0.id == id })
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    // Deletes sleep checkmarks at specified index offsets
    public func deleteCheckmarks(at offsets: IndexSet) {
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.remove(atOffsets: offsets)
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    // Switches the active day and loads its sleep schedule
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
    
    // Syncs currently displayed sleep times into the active day record
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
    
    // Builds a sleep night model for the selected day
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
        calendar.firstWeekday = 2
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
    
    // Converts 12-hour time components to total minutes from midnight
    private func toMinutesFromMidnight(hour: Int, minute: Int, period: MeridiemPeriod) -> Int {
        var h = hour % 12
        if period == .pm {
            h += 12
        }
        return h * 60 + minute
    }
}
