import SwiftUI
import Observation

// MARK: - Reusable Calendar Model
/// Reusable calendar and date selection model for SleepView, TrainingView, and across the app.
@Observable
public final class CalendarModel {
    
    // MARK: - Selected Date State
    public var selectedDate: Date {
        didSet {
            recalculateWeek(around: selectedDate)
        }
    }
    
    // MARK: - Weekdays State
    public var weekDays: [DayItem] = []
    public var selectedDayIndex: Int = 2
    
    // MARK: - Subtitles & Labels
    public var currentDaySubtitle: String {
        guard selectedDayIndex >= 0 && selectedDayIndex < weekDays.count else {
            return formattedDateDescription(for: selectedDate)
        }
        return weekDays[selectedDayIndex].fullDateDescription
    }
    
    public var formattedHeaderTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate).capitalized
    }
    
    // MARK: - Initializer
    public init(initialDate: Date = CalendarModel.defaultOctoberDate) {
        self.selectedDate = initialDate
        recalculateWeek(around: initialDate)
    }
    
    // MARK: - User Intent Actions
    public func selectDay(at index: Int) {
        guard index >= 0 && index < weekDays.count else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedDayIndex = index
            // Calculate corresponding date from Monday start of week
            var calendar = Calendar.current
            calendar.firstWeekday = 2 // Monday
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
            if let newDate = calendar.date(byAdding: .day, value: index, to: startOfWeek) {
                self.selectedDate = newDate
            }
        }
    }
    
    public func selectDate(_ newDate: Date) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedDate = newDate
        }
    }
    
    public func goToToday() {
        selectDate(Date())
    }
    
    public func moveToPreviousWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        if let prevWeek = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
            selectDate(prevWeek)
        }
    }
    
    public func moveToNextWeek() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: selectedDate) {
            selectDate(nextWeek)
        }
    }
    
    // MARK: - Dynamic Week Calculation
    public func recalculateWeek(around baseDate: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday is 1st weekday
        
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: baseDate)) ?? baseDate
        
        let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]
        var items: [DayItem] = []
        var matchIndex = 2
        
        for i in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            
            let dayNumber = calendar.component(.day, from: dayDate)
            let isCurrentSelection = calendar.isDate(dayDate, inSameDayAs: baseDate)
            if isCurrentSelection {
                matchIndex = i
            }
            
            let fullDesc = formattedDateDescription(for: dayDate)
            
            items.append(
                DayItem(
                    id: i,
                    letter: dayLetters[i],
                    dayNumber: dayNumber,
                    fullDateDescription: fullDesc,
                    isSelectedDefault: isCurrentSelection
                )
            )
        }
        
        self.weekDays = items
        self.selectedDayIndex = matchIndex
    }
    
    private func formattedDateDescription(for date: Date) -> String {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, d MMMM"
        dayFormatter.locale = Locale(identifier: "en_US")
        
        let formatted = dayFormatter.string(from: date)
        
        if calendar.isDateInToday(date) {
            return "Today, \(formatted)"
        } else {
            return formatted
        }
    }
    
    // Fallback date matching the original mockups (Wednesday, October 28, 2026)
    public static var defaultOctoberDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 28
        components.hour = 9
        components.minute = 41
        return Calendar.current.date(from: components) ?? Date()
    }
}
