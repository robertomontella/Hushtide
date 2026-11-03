//
//  SleepModel.swift
//  RecoveryApp
//
//  Created by Antigravity on 30/10/2026.
//

import SwiftUI
import Observation

// MARK: - Meridiem Period (AM / PM)
public enum MeridiemPeriod: String, CaseIterable, Identifiable {
    case am = "AM"
    case pm = "PM"
    
    public var id: String { rawValue }
}

// MARK: - Sleep Checkmark Item
public struct SleepCheckmarkItem: Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var isChecked: Bool
    
    public init(id: UUID = UUID(), title: String, isChecked: Bool = true) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
    }
}

// MARK: - Day Sleep Record
public struct DaySleepRecord: Hashable {
    public var inBedHour: Int
    public var inBedMinute: Int
    public var inBedPeriod: MeridiemPeriod
    public var asleepHour: Int
    public var asleepMinute: Int
    public var asleepPeriod: MeridiemPeriod
    public var checkmarks: [SleepCheckmarkItem]
    public var healthAsleepMinutes: Int? = nil
    
    public init(
        inBedHour: Int,
        inBedMinute: Int,
        inBedPeriod: MeridiemPeriod,
        asleepHour: Int,
        asleepMinute: Int,
        asleepPeriod: MeridiemPeriod,
        checkmarks: [SleepCheckmarkItem],
        healthAsleepMinutes: Int? = nil
    ) {
        self.inBedHour = inBedHour
        self.inBedMinute = inBedMinute
        self.inBedPeriod = inBedPeriod
        self.asleepHour = asleepHour
        self.asleepMinute = asleepMinute
        self.asleepPeriod = asleepPeriod
        self.checkmarks = checkmarks
        self.healthAsleepMinutes = healthAsleepMinutes
    }
}

// MARK: - Sleep Model Observable State
@Observable
public final class SleepModel {
    
    // Callback invoked whenever sleep duration, bedtime, goal, or checkmarks are modified
    public var onStateChanged: (() -> Void)? = nil
    
    // MARK: - Theme & Header
    public var title: String = "Sleep"
    public var currentDaySubtitle: String = "Today, Wednesday 28 October"
    public var selectedDayIndex: Int = 2
    
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
    public var weeklySleepMinutes: [Int] = [465, 390, 465, 480, 435, 510, 480]
    
    // 7-day individual records for full schedule and checkmark persistence
    public var weeklyRecords: [DaySleepRecord] = [
        // 0: Monday (7h 45m = 465m)
        DaySleepRecord(inBedHour: 11, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 6, asleepMinute: 45, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ]),
        // 1: Tuesday (6h 30m = 390m)
        DaySleepRecord(inBedHour: 11, inBedMinute: 30, inBedPeriod: .pm, asleepHour: 6, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: false),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ]),
        // 2: Wednesday (Today - 7h 45m = 465m)
        DaySleepRecord(inBedHour: 11, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 6, asleepMinute: 45, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ]),
        // 3: Thursday (8h 00m = 480m)
        DaySleepRecord(inBedHour: 10, inBedMinute: 45, inBedPeriod: .pm, asleepHour: 6, asleepMinute: 45, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ]),
        // 4: Friday (7h 15m = 435m)
        DaySleepRecord(inBedHour: 11, inBedMinute: 15, inBedPeriod: .pm, asleepHour: 6, asleepMinute: 30, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ]),
        // 5: Saturday (8h 30m = 510m)
        DaySleepRecord(inBedHour: 11, inBedMinute: 30, inBedPeriod: .pm, asleepHour: 8, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ]),
        // 6: Sunday (8h 00m = 480m)
        DaySleepRecord(inBedHour: 11, inBedMinute: 0, inBedPeriod: .pm, asleepHour: 7, asleepMinute: 0, asleepPeriod: .am, checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ])
    ]
    
    public var currentWeeklySleepMinutes: [Int] {
        var list = weeklySleepMinutes
        if selectedDayIndex >= 0 && selectedDayIndex < list.count {
            list[selectedDayIndex] = durationMinutes
        }
        return list
    }
    
    public var weeklyAverageMinutes: Int {
        let list = currentWeeklySleepMinutes
        guard !list.isEmpty else { return durationMinutes }
        return list.reduce(0, +) / list.count
    }
    
    public var weeklyAverageFormatted: String {
        let h = weeklyAverageMinutes / 60
        let m = weeklyAverageMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
    
    public var daysMeetingTargetCount: Int {
        let targetMins = Int(targetSleepHours * 60.0)
        return currentWeeklySleepMinutes.filter { $0 >= targetMins }.count
    }
    
    public var weeklySleepProgress: Double {
        let targetMins = targetSleepHours * 60.0
        guard targetMins > 0 else { return 0 }
        return min(1.0, max(0.01, Double(weeklyAverageMinutes) / targetMins))
    }
    
    // MARK: - Bedtime & Wakeup Schedule
    public var inBedHour: Int = 11
    public var inBedMinute: Int = 0
    public var inBedPeriod: MeridiemPeriod = .pm
    
    public var asleepHour: Int = 6
    public var asleepMinute: Int = 45
    public var asleepPeriod: MeridiemPeriod = .am
    
    public var inBedTimeFormatted: String {
        String(format: "%d:%02d", inBedHour, inBedMinute)
    }
    
    public var asleepTimeFormatted: String {
        String(format: "%d:%02d", asleepHour, asleepMinute)
    }
    
    public var inBedFullTimeFormatted: String {
        "\(inBedTimeFormatted) \(inBedPeriod.rawValue)"
    }
    
    public var asleepFullTimeFormatted: String {
        "\(asleepTimeFormatted) \(asleepPeriod.rawValue)"
    }
    
    // MARK: - Apple Health Data
    /// Real minutes asleep read from Apple Health (nil = computed from the schedule)
    public var healthAsleepMinutes: Int? = nil
    public var isFromAppleHealth: Bool { healthAsleepMinutes != nil }
    
    /// Fills bedtime / wake-up time and duration with a night read from HealthKit.
    public func apply(night: SleepNight?) {
        guard let night else {
            healthAsleepMinutes = nil
            syncCurrentToRecord()
            onStateChanged?()
            return
        }
        let calendar = Calendar.current
        let bed = calendar.dateComponents([.hour, .minute], from: night.bedtime)
        let wake = calendar.dateComponents([.hour, .minute], from: night.wakeTime)
        let (bedH, bedP) = Self.to12h(bed.hour ?? 0)
        let (wakeH, wakeP) = Self.to12h(wake.hour ?? 0)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            inBedHour = bedH
            inBedMinute = bed.minute ?? 0
            inBedPeriod = bedP
            asleepHour = wakeH
            asleepMinute = wake.minute ?? 0
            asleepPeriod = wakeP
            healthAsleepMinutes = night.asleepMinutes
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
        if let healthAsleepMinutes { return healthAsleepMinutes }
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
        let targetMins = targetSleepHours * 60.0
        guard targetMins > 0 else { return 0 }
        return min(1.0, max(0.01, Double(durationMinutes) / targetMins))
    }
    
    // MARK: - Recommendations & Checkmarks
    public var checkmarksSectionTitle: String = "Checkmarks"
    public var checkmarksSubtitle: String = "Based on your weekly workouts and daily routine, we recommend that you:"
    
    public var checkmarks: [SleepCheckmarkItem] = [
        SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
        SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
    ]
    
    // MARK: - Initializer
    public init() {}
    
    // MARK: - Schedule & Goal Actions
    public func setInBed(hour: Int, minute: Int, period: MeridiemPeriod) {
        healthAsleepMinutes = nil
        inBedHour = max(1, min(12, hour))
        inBedMinute = max(0, min(59, minute))
        inBedPeriod = period
        syncCurrentToRecord()
        onStateChanged?()
    }
    
    public func setAsleep(hour: Int, minute: Int, period: MeridiemPeriod) {
        healthAsleepMinutes = nil
        asleepHour = max(1, min(12, hour))
        asleepMinute = max(0, min(59, minute))
        asleepPeriod = period
        syncCurrentToRecord()
        onStateChanged?()
    }
    
    public func setInBedPeriod(_ period: MeridiemPeriod) {
        guard inBedPeriod != period else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            inBedPeriod = period
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    public func setAsleepPeriod(_ period: MeridiemPeriod) {
        guard asleepPeriod != period else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            asleepPeriod = period
            syncCurrentToRecord()
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
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            targetSleepHours = max(4.0, min(14.0, hours))
        }
        onStateChanged?()
    }
    
    // MARK: - Checkmark Actions
    public func toggleCheckmark(id: UUID) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        if let index = checkmarks.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                checkmarks[index].isChecked.toggle()
                syncCurrentToRecord()
            }
            onStateChanged?()
        }
    }
    
    public func addCheckmark(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.append(SleepCheckmarkItem(title: trimmed, isChecked: false))
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    public func updateCheckmark(id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let index = checkmarks.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                checkmarks[index].title = trimmed
                syncCurrentToRecord()
            }
            onStateChanged?()
        }
    }
    
    public func deleteCheckmark(id: UUID) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.removeAll(where: { $0.id == id })
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    public func deleteCheckmarks(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            checkmarks.remove(atOffsets: offsets)
            syncCurrentToRecord()
        }
        onStateChanged?()
    }
    
    public func selectDay(at index: Int) {
        guard index >= 0 && index < weeklyRecords.count else { return }
        syncCurrentToRecord()
        selectedDayIndex = index
        let record = weeklyRecords[index]
        inBedHour = record.inBedHour
        inBedMinute = record.inBedMinute
        inBedPeriod = record.inBedPeriod
        asleepHour = record.asleepHour
        asleepMinute = record.asleepMinute
        asleepPeriod = record.asleepPeriod
        checkmarks = record.checkmarks
        healthAsleepMinutes = record.healthAsleepMinutes
    }
    
    private func syncCurrentToRecord() {
        guard selectedDayIndex >= 0 && selectedDayIndex < weeklyRecords.count else { return }
        weeklyRecords[selectedDayIndex] = DaySleepRecord(
            inBedHour: inBedHour,
            inBedMinute: inBedMinute,
            inBedPeriod: inBedPeriod,
            asleepHour: asleepHour,
            asleepMinute: asleepMinute,
            asleepPeriod: asleepPeriod,
            checkmarks: checkmarks,
            healthAsleepMinutes: healthAsleepMinutes
        )
        let mins = durationMinutes
        if selectedDayIndex < weeklySleepMinutes.count {
            weeklySleepMinutes[selectedDayIndex] = mins
        }
    }
    
    /// Constructs a valid SleepNight for the currently selected day to evaluate recovery dynamically.
    public func currentDaySleepNight() -> SleepNight {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        let day = calendar.date(byAdding: .day, value: selectedDayIndex, to: monday) ?? today
        let previousDay = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        
        var bedHour24 = inBedHour
        if inBedPeriod == .pm && bedHour24 < 12 { bedHour24 += 12 }
        if inBedPeriod == .am && bedHour24 == 12 { bedHour24 = 0 }
        
        var wakeHour24 = asleepHour
        if asleepPeriod == .pm && wakeHour24 < 12 { wakeHour24 += 12 }
        if asleepPeriod == .am && wakeHour24 == 12 { wakeHour24 = 0 }
        
        let bedtime = calendar.date(bySettingHour: bedHour24, minute: inBedMinute, second: 0, of: previousDay) ?? previousDay
        let wakeTime = calendar.date(bySettingHour: wakeHour24, minute: asleepMinute, second: 0, of: day) ?? day
        
        let asleepMins = durationMinutes
        let inBedMins = Int((Double(asleepMins) / 0.90).rounded())
        let deepMins = Int((Double(asleepMins) * 0.18).rounded())
        let remMins = Int((Double(asleepMins) * 0.20).rounded())
        
        return SleepNight(
            day: day,
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
