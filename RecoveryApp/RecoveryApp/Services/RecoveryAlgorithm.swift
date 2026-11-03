//
//  RecoveryAlgorithm.swift
//  RecoveryApp
//
//  Clean and modular algorithm that computes Sleep Debt, Rest Levels (Quality),
//  Sleep Regularity, and overall Readiness based on Apple Health (HealthKit) data.
//  Also provides tailored recommendations for training intensity.
//

import Foundation
import HealthKit

// MARK: - Recovery Input
/// Encapsulates the inputs required by the recovery and readiness engine.
public struct RecoveryInput {
    /// Sleep night ending on the evaluated day (e.g. today / selected day)
    public var currentNight: SleepNight?
    
    /// Recent nights of sleep (past 7 days)
    public var recentNights: [SleepNight]
    
    /// User's target sleep goal in hours (e.g. 8.0)
    public var targetSleepHours: Double
    
    /// Sleep hygiene checkmarks status for the day (e.g. bedtime, caffeine cutoff)
    public var checkmarks: [SleepCheckmarkItem]
    
    /// Today's resting heart rate in bpm (from HealthKit)
    public var restingHeartRate: Double?
    
    /// 30-day baseline average resting heart rate in bpm (from HealthKit)
    public var restingHeartRateBaseline: Double?
    
    /// Today's HRV SDNN in ms (from HealthKit)
    public var heartRateVariability: Double?
    
    /// 30-day baseline average HRV SDNN in ms (from HealthKit)
    public var heartRateVariabilityBaseline: Double?
    
    /// Recent workouts (from HealthKit or app logs)
    public var recentWorkouts: [HealthWorkout]
    
    /// Reference evaluation date (defaults to current time)
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

// MARK: - Recovery Result
/// Output returned by the recovery algorithm.
public struct RecoveryResult: Equatable {
    /// Overall Readiness score: 0 to 100
    public let readinessScore: Double
    
    /// Rest Quality percentage: 0 to 100 (%)
    public let qualityScore: Int
    
    /// Formatted Quality metric value (e.g. "88%")
    public var qualityFormatted: String { "\(qualityScore)%" }
    
    /// Sleep Debt in minutes (negative = deficit, positive = surplus)
    public let sleepDebtMinutes: Int
    
    /// Formatted Sleep Debt string (e.g. "-15m", "+30m", "0m")
    public let sleepDebtFormatted: String
    
    /// Sleep Regularity classification (e.g. "On time", "Slightly off", "Irregular")
    public let regularityStatus: String
    
    /// Sleep Regularity consistency score: 0 to 100
    public let regularityScore: Int
    
    /// Recommended Training Intensity (.rest, .light, .medium, .hard)
    public let recommendedIntensity: IntensityLevel
    
    /// Recovery status title (e.g. "Ready to push", "Moderate readiness", "Take it easy", "Needs rest")
    public let recoveryStatusTitle: String
    
    /// Actionable recommendation explaining the recovery status and workout guidance
    public let recoveryRecommendation: String
}

// MARK: - Recovery Algorithm
/// Simple, clean, and modular recovery engine.
public enum RecoveryAlgorithm {
    
    // MARK: - Main Evaluation Entry Point
    
    /// Evaluates all recovery inputs and produces readiness, quality, sleep debt, regularity, and intensity recommendations.
    public static func evaluate(input: RecoveryInput) -> RecoveryResult {
        // Step 1: Compute Sleep Debt (target sleep vs actual sleep for selected day & weekly average)
        let (debtMinutes, debtFormatted, debtScore) = calculateSleepDebt(
            currentNight: input.currentNight,
            recentNights: input.recentNights,
            targetSleepHours: input.targetSleepHours
        )
        
        // Step 2: Compute Rest Levels & Sleep Quality (duration sufficiency, efficiency, checkmarks compliance, resting HR)
        let (qualityScore, restLevelScore, checkmarksScore, checkmarksMet) = calculateRestQuality(
            currentNight: input.currentNight,
            targetSleepHours: input.targetSleepHours,
            checkmarks: input.checkmarks,
            restingHeartRate: input.restingHeartRate,
            restingHeartRateBaseline: input.restingHeartRateBaseline
        )
        
        // Step 3: Compute Schedule Regularity (consistency of bedtime schedules)
        let (regularityStatus, regularityScore) = calculateRegularity(
            recentNights: input.recentNights
        )
        
        // Step 4: Compute Overall Readiness Score (weighted combination + checkmarks + HRV + workout fatigue)
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
        
        // Step 5: Determine Recommended Training Intensity & Tailored Guidance
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
    
    // MARK: - 1. Sleep Debt Calculation
    
    /// Compares actual sleep duration against the user's sleep need (target sleep hours).
    /// Accurately reflects both acute today deficit/surplus and recent days accumulated debt.
    public static func calculateSleepDebt(
        currentNight: SleepNight?,
        recentNights: [SleepNight],
        targetSleepHours: Double
    ) -> (debtMinutes: Int, formatted: String, score: Double) {
        let targetMinutes = Int((targetSleepHours * 60.0).rounded())
        
        // Acute today sleep:
        let todayAsleep = currentNight?.asleepMinutes ?? 465
        let todayDebt = todayAsleep - targetMinutes
        
        // Weekly average sleep:
        let weeklyAverageMinutes: Int
        if !recentNights.isEmpty {
            let total = recentNights.reduce(0) { $0 + $1.asleepMinutes }
            weeklyAverageMinutes = total / recentNights.count
        } else {
            weeklyAverageMinutes = todayAsleep
        }
        let weeklyDebt = weeklyAverageMinutes - targetMinutes
        
        // Effective debt blends acute day (65%) with weekly accumulated debt (35%):
        let effectiveDebt = Int(round(Double(todayDebt) * 0.65 + Double(weeklyDebt) * 0.35))
        
        // Formatted display on UI directly reflects today's acute deficit/surplus:
        let formatted = formatDebt(minutes: todayDebt)
        
        // Convert debt into a 0 to 100 score:
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
    
    /// Formats minutes into a signed human-readable string (e.g. "-15m", "+30m", "0m")
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
    
    // MARK: - 2. Rest Level & Sleep Quality Calculation
    
    /// Evaluates restfulness through duration sufficiency, sleep efficiency,
    /// sleep hygiene checkmarks compliance, and physiological rest indicators.
    /// Formula rewritten to be highly responsive to sleep duration and checkmarks status.
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
        
        // Component A: Sleep Duration Sufficiency (responsive power curve)
        // 100% on target -> 100.0, 7h/8h -> 81.8, 6h/8h -> 64.9, 5h/8h -> 49.4, 4h/8h -> 35.3
        let durationRatio = actualAsleep / targetMinutes
        let durationScore: Double
        if durationRatio >= 1.0 {
            durationScore = 100.0
        } else {
            durationScore = max(0.0, pow(durationRatio, 1.5) * 100.0)
        }
        
        // Component B: Sleep Hygiene Checkmarks Compliance (strong direct impact)
        // Full completion gives 100%, each unchecked checkmark significantly lowers the score
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
        
        // Component C: Sleep Efficiency (asleep time / time in bed)
        let rawEff = (actualAsleep / max(1.0, actualInBed)) * 100.0
        let efficiencyScore = max(0.0, min(100.0, (rawEff / 90.0) * 100.0))
        
        // Component D: Physiological Rest (RHR recovery or baseline fallback)
        let physioScore: Double
        if let rhr = restingHeartRate, let baseline = restingHeartRateBaseline, rhr > 0, baseline > 0 {
            let ratio = baseline / rhr
            physioScore = max(30.0, min(100.0, 75.0 + (ratio - 1.0) * 200.0))
        } else {
            physioScore = 90.0
        }
        
        // Rewritten Weighted Synthesis:
        // Duration Sufficiency: 60%
        // Checkmarks Compliance: 30%
        // Sleep Efficiency & Rest Factor: 10%
        let restFactor = (efficiencyScore * 0.5) + (physioScore * 0.5)
        let weighted = (durationScore * 0.60) + (checkmarksScore * 0.30) + (restFactor * 0.10)
        let finalQuality = max(0, min(100, Int(round(weighted))))
        
        return (finalQuality, Double(finalQuality), checkmarksScore, checkmarksMet)
    }
    
    /// Backwards-compatible convenience overload for callers expecting a 2-tuple.
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
    
    // MARK: - 3. Sleep Regularity Calculation
    
    /// Evaluates the consistency of bedtime schedules across recent nights.
    /// Returns:
    /// - `status`: classification label ("On time", "Slightly off", "Irregular")
    /// - `score`: 0 to 100 consistency score
    public static func calculateRegularity(
        recentNights: [SleepNight]
    ) -> (status: String, score: Int) {
        guard recentNights.count >= 2 else {
            return ("On time", 90)
        }
        
        let calendar = Calendar.current
        // Convert bedtimes to minutes from 18:00 (6 PM) to handle midnight wrap smoothly
        let bedtimeOffsets: [Double] = recentNights.map { night in
            let hour = calendar.component(.hour, from: night.bedtime)
            let minute = calendar.component(.minute, from: night.bedtime)
            var offset = Double(hour * 60 + minute) - (18.0 * 60.0)
            if offset < 0 { offset += 24.0 * 60.0 }
            return offset
        }
        
        // Compute standard deviation of bedtime offsets
        let mean = bedtimeOffsets.reduce(0, +) / Double(bedtimeOffsets.count)
        let variance = bedtimeOffsets.reduce(0) { $0 + pow($1 - mean, 2) } / Double(bedtimeOffsets.count)
        let standardDeviation = variance.squareRoot()
        
        // Classify consistency:
        // Under 30 min variation -> "On time" (score: 95)
        // 30 to 60 min variation -> "Slightly off" (score: 75)
        // Over 60 min variation  -> "Irregular" (score: 55)
        if standardDeviation < 30.0 {
            return ("On time", 95)
        } else if standardDeviation < 60.0 {
            return ("Slightly off", 75)
        } else {
            return ("Irregular", 55)
        }
    }
    
    // MARK: - 4. Overall Readiness Score Calculation
    
    /// Combines Sleep Debt, Rest Quality, Checkmarks Compliance, Regularity, and Heart Rate Variability (HRV),
    /// factoring in recent high-intensity workout fatigue.
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
        
        // 1. Sleep Debt & Duration Factor (35% weight)
        weightedParts.append((sleepDebtScore, 0.35))
        
        // 2. Rest Level & Sleep Quality Factor (35% weight)
        weightedParts.append((restLevelScore, 0.35))
        
        // 3. Sleep Hygiene Checkmarks Compliance (15% weight)
        weightedParts.append((checkmarksScore, 0.15))
        
        // 4. Regularity Factor (15% weight)
        weightedParts.append((Double(regularityScore), 0.15))
        
        // 5. Autonomic Recovery / Heart Rate Variability (15% weight)
        if let hrv = hrv, let base = hrvBaseline, base > 0, hrv > 0 {
            // Ratio > 1.0 indicates higher parasympathetic activity
            let ratio = hrv / base
            let hrvScore = max(20.0, min(100.0, 75.0 + (ratio - 1.0) * 125.0))
            weightedParts.append((hrvScore, 0.15))
        }
        
        let totalWeight = weightedParts.reduce(0) { $0 + $1.weight }
        var score = weightedParts.reduce(0) { $0 + $1.score * $1.weight } / totalWeight
        
        // Workout Recovery Load Modifier:
        // If an intense/hard workout was logged recently, apply recovery buffer
        for workout in workouts {
            let secondsAgo = evaluationDate.timeIntervalSince(workout.end)
            if workout.intensity == .hard && secondsAgo >= 0 && secondsAgo < 12 * 3600 {
                // Acute fatigue (workout finished within last 12 hours)
                score -= 8.0
                break
            } else if workout.intensity == .hard && secondsAgo >= 12 * 3600 && secondsAgo < 24 * 3600 {
                // Residual fatigue (workout was 12 to 24 hours ago)
                score -= 4.0
                break
            }
        }
        
        return max(0.0, min(100.0, score.rounded()))
    }
    
    /// Backwards-compatible convenience overload for callers without explicit checkmarksScore.
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
    
    // MARK: - 5. Training Intensity Recommendations
    
    /// Generates the recommended training intensity (.rest, .light, .medium, .hard),
    /// recovery status title, and personalized advice addressing sleep debt, rest levels, checkmarks, or regularity.
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

// MARK: - Model Integration Bridges

extension LoggedWorkout {
    /// Bridges LoggedWorkout into HealthWorkout so the algorithm can evaluate recent workout load.
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
    /// Bridges weekly sleep records & bedtime schedules into SleepNight objects for algorithm evaluation.
    public func toSleepNights() -> [SleepNight] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
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
