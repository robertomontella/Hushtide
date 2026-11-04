import SwiftUI
import Observation

// MARK: - Reusable Calendar Model
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
    public var selectedDayIndex: Int = 0
    
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
    
    // MARK: - Initializer (defaults to current date across the app)
    public init(initialDate: Date = Date()) {
        self.selectedDate = initialDate
        recalculateWeek(around: initialDate)
    }
    
    // MARK: - Future Date Helpers
    public var isSelectedDateInFuture: Bool {
        isDateInFuture(selectedDate)
    }
    
    public func isDateInFuture(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
    }
    
    public func isDayIndexInFuture(_ index: Int) -> Bool {
        let dayDate = dateForDay(at: index)
        return isDateInFuture(dayDate)
    }
    
    public func dateForDay(at index: Int) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday + 5) % 7
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
        return calendar.date(byAdding: .day, value: index, to: monday) ?? selectedDate
    }
    
    // MARK: - User Intent Actions
    public func selectDay(at index: Int) {
        guard index >= 0 && index < weekDays.count else { return }
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedDayIndex = index
            let newDate = dateForDay(at: index)
            self.selectedDate = newDate
        }
    }
    
    public func selectDate(_ newDate: Date) {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedDate = newDate
        }
    }
    
    public func goToToday() {
        selectDate(Date())
    }
    
    public func moveToPreviousWeek() {
        let calendar = Calendar.current
        if let prevWeek = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
            selectDate(prevWeek)
        }
    }
    
    public func moveToNextWeek() {
        let calendar = Calendar.current
        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: selectedDate) {
            selectDate(nextWeek)
        }
    }
    
    // MARK: - Dynamic Week Calculation (Monday to Sunday)
    public func recalculateWeek(around baseDate: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: baseDate)
        let daysFromMonday = (weekday + 5) % 7
        let startOfDay = calendar.startOfDay(for: baseDate)
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
        
        let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]
        var items: [DayItem] = []
        var matchIndex = 0
        
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
}
