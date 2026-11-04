import SwiftUI
import Observation

@Observable
public final class CalendarModel {
    
    public var selectedDate: Date {
        didSet {
            recalculateWeek(around: selectedDate)
        }
    }
    
    public var weekDays: [DayItem] = []
    public var selectedDayIndex: Int = 0
    
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
    
    public init(initialDate: Date = Date()) {
        self.selectedDate = initialDate
        recalculateWeek(around: initialDate)
    }
    
    public var isSelectedDateInFuture: Bool {
        isDateInFuture(selectedDate)
    }
    
    // Checks if a given date is in the future
    public func isDateInFuture(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
    }
    
    // Checks if a weekday index is in the future
    public func isDayIndexInFuture(_ index: Int) -> Bool {
        let dayDate = dateForDay(at: index)
        return isDateInFuture(dayDate)
    }
    
    // Calculates the calendar date for a weekday index relative to Monday
    public func dateForDay(at index: Int) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday + 5) % 7
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: startOfDay) ?? startOfDay
        return calendar.date(byAdding: .day, value: index, to: monday) ?? selectedDate
    }
    
    // Selects a day by its index in the current week
    public func selectDay(at index: Int) {
        guard index >= 0 && index < weekDays.count else { return }
        HapticManager.impact(.light)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedDayIndex = index
            let newDate = dateForDay(at: index)
            self.selectedDate = newDate
        }
    }
    
    // Selects an arbitrary date and updates the active week
    public func selectDate(_ newDate: Date) {
        HapticManager.impact(.medium)
        
        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedDate = newDate
        }
    }
    
    // Resets the calendar selection to today
    public func goToToday() {
        selectDate(Date())
    }
    
    // Moves the active calendar view to the previous week
    public func moveToPreviousWeek() {
        let calendar = Calendar.current
        if let prevWeek = calendar.date(byAdding: .day, value: -7, to: selectedDate) {
            selectDate(prevWeek)
        }
    }
    
    // Moves the active calendar view to the next week
    public func moveToNextWeek() {
        let calendar = Calendar.current
        if let nextWeek = calendar.date(byAdding: .day, value: 7, to: selectedDate) {
            selectDate(nextWeek)
        }
    }
    
    // Recalculates the seven days of the week surrounding a base date
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
    
    // Formats a date into a localized descriptive string
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
