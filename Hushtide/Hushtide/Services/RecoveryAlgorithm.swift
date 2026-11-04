import Foundation
import HealthKit

public struct RecoveryInput {
    public var currentNight: SleepNight?
    
    public var recentNights: [SleepNight]
    
    public var targetSleepHours: Double
    
    public var checkmarks: [SleepCheckmarkItem]
    
    public var restingHeartRate: Double?
    
    public var restingHeartRateBaseline: Double?
    
    public var heartRateVariability: Double?
    
    public var heartRateVariabilityBaseline: Double?
    
    public var recentWorkouts: [HealthWorkout]
    
    public var evaluationDate: Date
    
    public init(
        currentNight: SleepNight? = nil,
        recentNights: [SleepNight] = [],
        targetSleepHours: Double = 8.0,
        checkmarks: [SleepCheckmarkItem] = [],
        restingHeartRate: Double? = nil,
        restingHeartRateBaseline: Double? = nil,
        heartRateVariability: Double? = nil,
        heartRateVariabilityBaseline: Double? = nil,
        recentWorkouts: [HealthWorkout] = [],
        evaluationDate: Date = Date()
    ) {
        self.currentNight = currentNight
        self.recentNights = recentNights
        self.targetSleepHours = targetSleepHours
        self.checkmarks = checkmarks
        self.restingHeartRate = restingHeartRate
        self.restingHeartRateBaseline = restingHeartRateBaseline
        self.heartRateVariability = heartRateVariability
        self.heartRateVariabilityBaseline = heartRateVariabilityBaseline
        self.recentWorkouts = recentWorkouts
        self.evaluationDate = evaluationDate
    }
}

public struct RecoveryResult: Equatable {
    public let readinessScore: Double
    
    public let qualityScore: Int
    
    public var qualityFormatted: String { "\(qualityScore)%" }
    
    public let sleepDebtMinutes: Int
    
    public let sleepDebtFormatted: String
    
    public let regularityStatus: String
    
    public let regularityScore: Int
    
    public let recommendedIntensity: IntensityLevel
    
    public let recoveryStatusTitle: String
    
    public let recoveryRecommendation: String
}

public enum RecoveryAlgorithm {
    
    // Evaluates recovery inputs to generate readiness, quality, sleep debt, regularity, and recommendations
    public static func evaluate(input: RecoveryInput) -> RecoveryResult {
        let (debtMinutes, debtFormatted, debtScore) = calculateSleepDebt(
            currentNight: input.currentNight,
            recentNights: input.recentNights,
            targetSleepHours: input.targetSleepHours
        )
        
        let (qualityScore, restLevelScore, checkmarksScore, checkmarksMet) = calculateRestQuality(
            currentNight: input.currentNight,
            targetSleepHours: input.targetSleepHours,
            checkmarks: input.checkmarks,
            restingHeartRate: input.restingHeartRate,
            restingHeartRateBaseline: input.restingHeartRateBaseline
        )
        
        let (regularityStatus, regularityScore) = calculateRegularity(
            recentNights: input.recentNights
        )
        
        let readinessScore = calculateReadinessScore(
            sleepDebtScore: debtScore,
            restLevelScore: restLevelScore,
            checkmarksScore: checkmarksScore,
            regularityScore: regularityScore,
            hrv: input.heartRateVariability,
            hrvBaseline: input.heartRateVariabilityBaseline,
            workouts: input.recentWorkouts,
            evaluationDate: input.evaluationDate
        )
        
        let (intensity, title, recommendation) = makeRecommendations(
            readinessScore: readinessScore,
            debtMinutes: debtMinutes,
            debtFormatted: debtFormatted,
            qualityScore: qualityScore,
            regularityStatus: regularityStatus,
            checkmarksMet: checkmarksMet
        )
        
        return RecoveryResult(
            readinessScore: readinessScore,
            qualityScore: qualityScore,
            sleepDebtMinutes: debtMinutes,
            sleepDebtFormatted: debtFormatted,
            regularityStatus: regularityStatus,
            regularityScore: regularityScore,
            recommendedIntensity: intensity,
            recoveryStatusTitle: title,
            recoveryRecommendation: recommendation
        )
    }
    
    // Calculates sleep debt based on daily sleep and weekly average against target hours
    public static func calculateSleepDebt(
        currentNight: SleepNight?,
        recentNights: [SleepNight],
        targetSleepHours: Double
    ) -> (debtMinutes: Int, formatted: String, score: Double) {
        let targetMinutes = Int((targetSleepHours * 60.0).rounded())
        
        let todayAsleep = currentNight?.asleepMinutes ?? 465
        let todayDebt = todayAsleep - targetMinutes
        
        let weeklyAverageMinutes: Int
        if !recentNights.isEmpty {
            let total = recentNights.reduce(0) { $0 + $1.asleepMinutes }
            weeklyAverageMinutes = total / recentNights.count
        } else {
            weeklyAverageMinutes = todayAsleep
        }
        let weeklyDebt = weeklyAverageMinutes - targetMinutes
        
        let effectiveDebt = Int(round(Double(todayDebt) * 0.65 + Double(weeklyDebt) * 0.35))
        
        let formatted = formatDebt(minutes: todayDebt)
        
        let score: Double
        if effectiveDebt >= 0 {
            score = 100.0
        } else {
            let deficit = Double(abs(effectiveDebt))
            let calculated = 100.0 - (deficit / 60.0) * 18.0
            score = max(15.0, min(100.0, calculated))
        }
        
        return (todayDebt, formatted, score)
    }
    
    // Formats sleep debt minutes into a signed display string
    public static func formatDebt(minutes: Int) -> String {
        let sign = minutes < 0 ? "-" : "+"
        let absVal = abs(minutes)
        if absVal == 0 { return "0m" }
        if absVal < 60 {
            return "\(sign)\(absVal)m"
        } else {
            let h = absVal / 60
            let m = absVal % 60
            return m == 0 ? "\(sign)\(h)h" : "\(sign)\(h)h \(m)m"
        }
    }
    
    // Computes sleep quality score from duration sufficiency, efficiency, checkmarks compliance, and resting heart rate
    public static func calculateRestQuality(
        currentNight: SleepNight?,
        targetSleepHours: Double = 8.0,
        checkmarks: [SleepCheckmarkItem] = [],
        restingHeartRate: Double? = nil,
        restingHeartRateBaseline: Double? = nil
    ) -> (qualityScore: Int, restLevelScore: Double, checkmarksScore: Double, checkmarksMet: Bool) {
        guard let currentNight = currentNight, currentNight.asleepMinutes > 0 else {
            return (0, 0.0, 0.0, false)
        }
        
        let targetMinutes = max(60.0, targetSleepHours * 60.0)
        let actualAsleep = Double(currentNight.asleepMinutes)
        let actualInBed = Double(max(currentNight.inBedMinutes, Int(actualAsleep)))
        
        let durationRatio = actualAsleep / targetMinutes
        let durationScore: Double
        if durationRatio >= 1.0 {
            durationScore = 100.0
        } else {
            durationScore = max(0.0, pow(durationRatio, 1.5) * 100.0)
        }
        
        let checkmarksScore: Double
        let checkmarksMet: Bool
        if !checkmarks.isEmpty {
            let checkedCount = checkmarks.filter { $0.isChecked }.count
            let ratio = Double(checkedCount) / Double(checkmarks.count)
            checkmarksMet = (ratio >= 0.99)
            checkmarksScore = ratio * 100.0
        } else {
            checkmarksScore = 100.0
            checkmarksMet = true
        }
        
        let rawEff = (actualAsleep / max(1.0, actualInBed)) * 100.0
        let efficiencyScore = max(0.0, min(100.0, (rawEff / 90.0) * 100.0))
        
        let physioScore: Double
        if let rhr = restingHeartRate, let baseline = restingHeartRateBaseline, rhr > 0, baseline > 0 {
            let ratio = baseline / rhr
            physioScore = max(30.0, min(100.0, 75.0 + (ratio - 1.0) * 200.0))
        } else {
            physioScore = 90.0
        }
        
        let restFactor = (efficiencyScore * 0.5) + (physioScore * 0.5)
        let weighted = (durationScore * 0.60) + (checkmarksScore * 0.30) + (restFactor * 0.10)
        let finalQuality = max(0, min(100, Int(round(weighted))))
        
        return (finalQuality, Double(finalQuality), checkmarksScore, checkmarksMet)
    }
    
    // Computes sleep quality score without checkmark compliance metrics
    public static func calculateRestQuality(
        currentNight: SleepNight?,
        restingHeartRate: Double?,
        restingHeartRateBaseline: Double?
    ) -> (qualityScore: Int, restLevelScore: Double) {
        let res = calculateRestQuality(
            currentNight: currentNight,
            targetSleepHours: 8.0,
            checkmarks: [],
            restingHeartRate: restingHeartRate,
            restingHeartRateBaseline: restingHeartRateBaseline
        )
        return (res.qualityScore, res.restLevelScore)
    }
    
    // Evaluates bedtime schedule consistency across recent nights
    public static func calculateRegularity(
        recentNights: [SleepNight]
    ) -> (status: String, score: Int) {
        guard recentNights.count >= 2 else {
            return ("On time", 90)
        }
        
        let calendar = Calendar.current
        let bedtimeOffsets: [Double] = recentNights.map { night in
            let hour = calendar.component(.hour, from: night.bedtime)
            let minute = calendar.component(.minute, from: night.bedtime)
            var offset = Double(hour * 60 + minute) - (18.0 * 60.0)
            if offset < 0 { offset += 24.0 * 60.0 }
            return offset
        }
        
        let mean = bedtimeOffsets.reduce(0, +) / Double(bedtimeOffsets.count)
        let variance = bedtimeOffsets.reduce(0) { $0 + pow($1 - mean, 2) } / Double(bedtimeOffsets.count)
        let standardDeviation = variance.squareRoot()
        
        if standardDeviation < 30.0 {
            return ("On time", 95)
        } else if standardDeviation < 60.0 {
            return ("Slightly off", 75)
        } else {
            return ("Irregular", 55)
        }
    }
    
    // Computes overall readiness score from sleep debt, rest quality, checkmarks, HRV, and workout fatigue
    public static func calculateReadinessScore(
        sleepDebtScore: Double,
        restLevelScore: Double,
        checkmarksScore: Double,
        regularityScore: Int,
        hrv: Double?,
        hrvBaseline: Double?,
        workouts: [HealthWorkout],
        evaluationDate: Date
    ) -> Double {
        var weightedParts: [(score: Double, weight: Double)] = []
        
        weightedParts.append((sleepDebtScore, 0.35))
        
        weightedParts.append((restLevelScore, 0.35))
        
        weightedParts.append((checkmarksScore, 0.15))
        
        weightedParts.append((Double(regularityScore), 0.15))
        
        if let hrv = hrv, let base = hrvBaseline, base > 0, hrv > 0 {
            let ratio = hrv / base
            let hrvScore = max(20.0, min(100.0, 75.0 + (ratio - 1.0) * 125.0))
            weightedParts.append((hrvScore, 0.15))
        }
        
        let totalWeight = weightedParts.reduce(0) { $0 + $1.weight }
        var score = weightedParts.reduce(0) { $0 + $1.score * $1.weight } / totalWeight
        
        for workout in workouts {
            let secondsAgo = evaluationDate.timeIntervalSince(workout.end)
            if workout.intensity == .hard && secondsAgo >= 0 && secondsAgo < 12 * 3600 {
                score -= 8.0
                break
            } else if workout.intensity == .hard && secondsAgo >= 12 * 3600 && secondsAgo < 24 * 3600 {
                score -= 4.0
                break
            }
        }
        
        return max(0.0, min(100.0, score.rounded()))
    }
    
    // Computes overall readiness score without explicit checkmarks score
    public static func calculateReadinessScore(
        sleepDebtScore: Double,
        restLevelScore: Double,
        regularityScore: Int,
        hrv: Double?,
        hrvBaseline: Double?,
        workouts: [HealthWorkout],
        evaluationDate: Date
    ) -> Double {
        calculateReadinessScore(
            sleepDebtScore: sleepDebtScore,
            restLevelScore: restLevelScore,
            checkmarksScore: restLevelScore,
            regularityScore: regularityScore,
            hrv: hrv,
            hrvBaseline: hrvBaseline,
            workouts: workouts,
            evaluationDate: evaluationDate
        )
    }
    
    // Determines recommended training intensity and guidance based on recovery metrics
    public static func makeRecommendations(
        readinessScore: Double,
        debtMinutes: Int,
        debtFormatted: String,
        qualityScore: Int,
        regularityStatus: String,
        checkmarksMet: Bool = true
    ) -> (intensity: IntensityLevel, title: String, recommendation: String) {
        switch readinessScore {
        case 80.0...:
            let detail: String
            if !checkmarksMet {
                detail = "High readiness (\(Int(readinessScore))%): rest quality is \(qualityScore)% but some sleep habits were missed. You are ready for high intensity; stay hydrated."
            } else {
                detail = "Full recovery: your rest quality (\(qualityScore)%) and sleep habits are optimal. Great day for strength, high intensity, or a long session."
            }
            return (
                .hard,
                "Ready to push",
                detail
            )
            
        case 60.0..<80.0:
            let detail: String
            if debtMinutes <= -45 {
                detail = "Moderate recovery: sleep debt (\(debtFormatted)) is elevated. Ideal for tempo work, hypertrophy or light cardio."
            } else if !checkmarksMet {
                detail = "Moderate recovery: rest quality is \(qualityScore)% with unmet sleep checkmarks. Focus on steady volume and your bedtime routine."
            } else if regularityStatus == "Irregular" {
                detail = "Moderate recovery: schedule consistency was off. Suitable for standard volume or steady conditioning."
            } else {
                detail = "Moderate recovery: suitable for tempo work, hypertrophy or light cardio."
            }
            return (
                .medium,
                "Moderate readiness",
                detail
            )
            
        case 40.0..<60.0:
            let detail: String
            if debtMinutes <= -60 {
                detail = "Elevated sleep debt (\(debtFormatted)): prioritize early sleep. Suitable for active recovery or light mobility."
            } else if qualityScore < 75 {
                detail = "Rest quality is low (\(qualityScore)%): favor active recovery, light mobility, or aerobic zone 2."
            } else if !checkmarksMet {
                detail = "Take it easy today: sleep habits were not met and recovery is incomplete. Opt for light mobility."
            } else {
                detail = "Partial recovery: suitable for active recovery or light mobility."
            }
            return (
                .light,
                "Take it easy",
                detail
            )
            
        default:
            let detail: String
            if debtMinutes <= -120 {
                detail = "High fatigue detected: acute sleep debt (\(debtFormatted)) and reduced rest quality. Prioritize sleep and complete rest before strenuous training."
            } else {
                detail = "High fatigue detected: prioritize sleep, hydration, and light recovery before strenuous training."
            }
            return (
                .rest,
                "Needs rest",
                detail
            )
        }
    }
}

extension LoggedWorkout {
    // Converts a logged workout into a health workout for recovery evaluation
    public func toHealthWorkout() -> HealthWorkout {
        let end = scheduledDate.addingTimeInterval(TimeInterval(max(1, durationMinutes) * 60))
        return HealthWorkout(
            uuid: healthKitUUID ?? id,
            sportName: sportType,
            start: scheduledDate,
            end: end,
            durationMinutes: durationMinutes,
            activeKilocalories: nil,
            intensity: intensity,
            focusArea: focusArea,
            rpe: rpe,
            notes: notes
        )
    }
}

extension SleepModel {
    // Converts weekly sleep records into sleep night objects for algorithm evaluation
    public func toSleepNights() -> [SleepNight] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: now)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        
        var nights: [SleepNight] = []
        let minutesList = currentWeeklySleepMinutes
        
        for offset in 0..<minutesList.count {
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { continue }
            let asleepMins = minutesList[offset]
            guard asleepMins > 0 else { continue }
            
            let previousDay = calendar.date(byAdding: .day, value: -1, to: day) ?? day
            
            let record = (offset < weeklyRecords.count) ? weeklyRecords[offset] : nil
            let bedH = record?.inBedHour ?? inBedHour
            let bedM = record?.inBedMinute ?? inBedMinute
            let bedP = record?.inBedPeriod ?? inBedPeriod
            let wakeH = record?.asleepHour ?? asleepHour
            let wakeM = record?.asleepMinute ?? asleepMinute
            let wakeP = record?.asleepPeriod ?? asleepPeriod
            
            var bedHour24 = bedH
            if bedP == .pm && bedHour24 < 12 { bedHour24 += 12 }
            if bedP == .am && bedHour24 == 12 { bedHour24 = 0 }
            
            var wakeHour24 = wakeH
            if wakeP == .pm && wakeHour24 < 12 { wakeHour24 += 12 }
            if wakeP == .am && wakeHour24 == 12 { wakeHour24 = 0 }
            
            let bedtime = calendar.date(bySettingHour: bedHour24, minute: bedM, second: 0, of: previousDay) ?? previousDay
            let wakeTime = calendar.date(bySettingHour: wakeHour24, minute: wakeM, second: 0, of: day) ?? day
            
            let inBedMins = Int((Double(asleepMins) / 0.90).rounded())
            let deepMins = Int((Double(asleepMins) * 0.18).rounded())
            let remMins = Int((Double(asleepMins) * 0.20).rounded())
            
            nights.append(
                SleepNight(
                    day: day,
                    bedtime: bedtime,
                    wakeTime: wakeTime,
                    asleepMinutes: asleepMins,
                    inBedMinutes: inBedMins,
                    deepMinutes: deepMins,
                    remMinutes: remMins
                )
            )
        }
        return nights
    }
}
