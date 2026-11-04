import SwiftUI

// MARK: - Navigation Tabs
public enum AppTab: Int, CaseIterable, Identifiable {
    case summary = 0
    case sleep = 1
    case training = 2
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .summary: return "Summary"
        case .sleep: return "Sleep"
        case .training: return "Training"
        }
    }
    
    public var iconName: String {
        switch self {
        case .summary: return "list.bullet"
        case .sleep: return "moon.fill"
        case .training: return "bolt.fill"
        }
    }
}

// MARK: - Summary Metric Tabs (Quality, Sleep, Training)
public enum SummaryMetricTab: String, CaseIterable, Identifiable {
    case quality = "Quality"
    case sleep = "Sleep"
    case training = "Training"
    
    public var id: String { rawValue }
}

// MARK: - Day Item
public struct DayItem: Identifiable, Hashable {
    public let id: Int
    public let letter: String
    public let dayNumber: Int
    public let fullDateDescription: String
    public let isSelectedDefault: Bool
    
    public init(id: Int, letter: String, dayNumber: Int, fullDateDescription: String, isSelectedDefault: Bool = false) {
        self.id = id
        self.letter = letter
        self.dayNumber = dayNumber
        self.fullDateDescription = fullDateDescription
        self.isSelectedDefault = isSelectedDefault
    }
}

// MARK: - Intensity Level
public enum IntensityLevel: String, CaseIterable, Identifiable, Codable {
    case rest = "Rest"
    case light = "Light"
    case medium = "Medium"
    case hard = "Hard"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .rest: return "bed.double.fill"
        case .light: return "figure.walk"
        case .medium: return "figure.run"
        case .hard: return "flame.fill"
        }
    }
    
    public var intensityRank: Int {
        switch self {
        case .rest: return 1
        case .light: return 2
        case .medium: return 3
        case .hard: return 4
        }
    }
}

// MARK: - Profile Option Catalogs
public struct ProfileOptions {
    /// The main sports categories (applied across Profile and Add Workout)
    public static let sports = [
        "Running",
        "Cycling",
        "Swimming",
        "Strength Training",
        "Walking",
        "HIIT",
        "Yoga"
    ]
    
    public static let trainingLevels = [
        "Beginner",
        "Intermediate",
        "Advanced",
        "Elite",
        "Professional"
    ]
    
    public static let frequencies = [
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "Everyday (7/7)"
    ]
    
    public static let genders = [
        "Female",
        "Male",
        "Non-binary",
        "Prefer not to say"
    ]
    
    public static let avatarIcons = [
        "person.crop.circle.fill",
        "figure.run",
        "figure.strengthtraining.traditional",
        "flame.fill",
        "bolt.heart.fill",
        "heart.circle.fill",
        "dumbbell.fill",
        "star.circle.fill"
    ]
    
    public static func icon(for sport: String) -> String {
        let lower = sport.lowercased()
        if lower.contains("run") { return "figure.run" }
        if lower.contains("cycl") || lower.contains("bike") { return "figure.outdoor.cycle" }
        if lower.contains("swim") { return "figure.pool.swim" }
        if lower.contains("strength") || lower.contains("lift") || lower.contains("weight") || lower.contains("gym") || lower.contains("bodybuilding") { return "figure.strengthtraining.traditional" }
        if lower.contains("walk") || lower.contains("hike") { return "figure.walk" }
        if lower.contains("hiit") || lower.contains("cardio") || lower.contains("crossfit") { return "bolt.fill" }
        if lower.contains("yoga") || lower.contains("stretch") || lower.contains("mobility") { return "figure.mind.and.body" }
        if lower.contains("box") || lower.contains("combat") || lower.contains("martial") { return "figure.boxing" }
        if lower.contains("tennis") || lower.contains("padel") { return "figure.tennis" }
        if lower.contains("basket") { return "figure.basketball" }
        if lower.contains("soccer") || lower.contains("football") { return "figure.soccer" }
        if lower.contains("climb") { return "figure.climbing" }
        if lower.contains("pilates") { return "figure.pilates" }
        if lower.contains("row") { return "figure.rower" }
        if lower.contains("ski") { return "figure.skiing.downhill" }
        if lower.contains("golf") { return "figure.golf" }
        if lower.contains("skat") { return "figure.skating" }
        return "figure.run"
    }
}

// MARK: - Metric Item
public struct SecondaryMetric: Identifiable {
    public let id = UUID()
    public var title: String
    public var value: String
    
    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }
}

// MARK: - Logged Workout Item
public struct LoggedWorkout: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    /// UUID of the matching HKWorkout in Apple Health (nil = only stored in the app)
    public var healthKitUUID: UUID?
    public var sportType: String
    public var intensity: IntensityLevel
    public var durationMinutes: Int
    public var focusArea: String
    public var scheduledDate: Date
    public var dayIndex: Int
    public var rpe: Int
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        sportType: String,
        intensity: IntensityLevel,
        durationMinutes: Int = 60,
        focusArea: String = "",
        scheduledDate: Date = Date(),
        dayIndex: Int? = nil,
        rpe: Int = 8,
        notes: String = "",
        healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.sportType = sportType
        self.intensity = intensity
        self.durationMinutes = durationMinutes
        self.focusArea = focusArea
        self.scheduledDate = scheduledDate
        if let day = dayIndex {
            self.dayIndex = day
        } else {
            let weekday = Calendar.current.component(.weekday, from: scheduledDate)
            self.dayIndex = (weekday + 5) % 7
        }
        self.rpe = rpe
        self.notes = notes
    }
    
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledDate)
    }
    
    public var sportIcon: String {
        ProfileOptions.icon(for: sportType)
    }
}
