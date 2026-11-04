import SwiftUI

public struct SummaryDetailChartView: View {
    @Environment(\.appHighContrast) private var appHighContrast
    @Environment(\.appReduceMotion) private var appReduceMotion
    public let selectedMetric: SummaryMetricTab
    
    // Quality dynamic data
    public var qualityAverage: Int = 88
    public var qualityTarget: Int = 85
    public var qualityPercentages: [Int] = [86, 72, 92, 80, 90, 96, 88]
    
    // Sleep dynamic data (synchronized with SleepModel)
    public var sleepAverageFormatted: String = "7h 45m"
    public var sleepTargetFormatted: String = "8h"
    public var sleepMinutesPerDay: [Int] = [465, 390, 465, 480, 435, 510, 480]
    public var sleepTargetMinutes: Int = 480
    
    // Training dynamic data (calculated from logged workouts)
    public var trainingAverageFormatted: String = "31m"
    public var trainingTargetFormatted: String = "21m"
    public var trainingMinutesPerDay: [Int] = [50, 30, 60, 30, 50, 0, 0]
    public var trainingDailyTargetMinutes: Int = 21
    
    public var onEditTarget: (() -> Void)? = nil
    
    // MARK: - Theme Colors
    private var themeColor: Color {
        switch selectedMetric {
        case .quality:
            return Color(red: 3/255.0, green: 199/255.0, blue: 190/255.0)  // Teal / Mint
        case .sleep:
            return Color(red: 88/255.0, green: 86/255.0, blue: 215/255.0)    // Indigo / Purple
        case .training:
            return Color(red: 1/255.0, green: 113/255.0, blue: 227/255.0) // System Blue
        }
    }
    
    // MARK: - Header Titles & Subtitles
    private var headerSubtitle: String {
        return "DAILY AVERAGE"
    }
    
    private var primaryValueText: String {
        switch selectedMetric {
        case .quality: return "\(qualityAverage)%"
        case .sleep: return sleepAverageFormatted
        case .training: return trainingAverageFormatted
        }
    }
    
    private var targetValueText: String {
        switch selectedMetric {
        case .quality: return "target \(qualityTarget)%"
        case .sleep: return "target \(sleepTargetFormatted)"
        case .training: return "target \(trainingTargetFormatted)"
        }
    }
    
    // MARK: - 7 Days Data (Monday to Sunday)
    private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]
    
    // Target dashed line height (from bottom of chart)
    private var targetLineYOffset: CGFloat {
        switch selectedMetric {
        case .quality: return 75
        case .sleep: return 75
        case .training: return 50
        }
    }
    
    public init(
        selectedMetric: SummaryMetricTab = .sleep,
        qualityAverage: Int = 88,
        qualityTarget: Int = 85,
        qualityPercentages: [Int] = [86, 72, 92, 80, 90, 96, 88],
        sleepAverageFormatted: String = "7h 45m",
        sleepTargetFormatted: String = "8h",
        sleepMinutesPerDay: [Int] = [465, 390, 465, 480, 435, 510, 480],
        sleepTargetMinutes: Int = 480,
        trainingAverageFormatted: String = "31m",
        trainingTargetFormatted: String = "21m",
        trainingMinutesPerDay: [Int] = [50, 30, 60, 30, 50, 0, 0],
        trainingDailyTargetMinutes: Int = 21,
        onEditTarget: (() -> Void)? = nil
    ) {
        self.selectedMetric = selectedMetric
        self.qualityAverage = qualityAverage
        self.qualityTarget = qualityTarget
        self.qualityPercentages = qualityPercentages
        self.sleepAverageFormatted = sleepAverageFormatted
        self.sleepTargetFormatted = sleepTargetFormatted
        self.sleepMinutesPerDay = sleepMinutesPerDay
        self.sleepTargetMinutes = sleepTargetMinutes
        self.trainingAverageFormatted = trainingAverageFormatted
        self.trainingTargetFormatted = trainingTargetFormatted
        self.trainingMinutesPerDay = trainingMinutesPerDay
        self.trainingDailyTargetMinutes = trainingDailyTargetMinutes
        self.onEditTarget = onEditTarget
    }
    
    public init(
        viewModel: TrainingModel,
        onEditTarget: (() -> Void)? = nil
    ) {
        self.selectedMetric = viewModel.selectedSummaryMetric
        self.qualityAverage = viewModel.weeklyQualityAverage
        self.qualityTarget = viewModel.qualityTargetPercentage
        self.qualityPercentages = viewModel.weeklyQualityPercentages
        
        self.sleepAverageFormatted = viewModel.sleepModel.weeklyAverageFormatted
        self.sleepTargetFormatted = viewModel.sleepModel.targetDurationSimpleFormatted
        self.sleepMinutesPerDay = viewModel.sleepModel.currentWeeklySleepMinutes
        self.sleepTargetMinutes = Int(viewModel.sleepModel.targetSleepHours * 60.0)
        
        self.trainingAverageFormatted = "\(viewModel.dailyTrainingAverageMinutes)m"
        self.trainingTargetFormatted = "\(viewModel.trainingDailyMinutesTarget)m"
        self.trainingMinutesPerDay = viewModel.dailyTrainingMinutes
        self.trainingDailyTargetMinutes = viewModel.trainingDailyMinutesTarget
        
        self.onEditTarget = onEditTarget
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Header Information
            VStack(alignment: .leading, spacing: 4) {
                Text(headerSubtitle)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .center, spacing: 10) {
                    Text(primaryValueText)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // Static Target Capsule (Not clickable, target changes made via double-clicking cards)
                    HStack(spacing: 5) {
                        Text(targetValueText)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: .systemGray6))
                    )
                }
            }
            
            // MARK: - Bar Chart Area
            ZStack(alignment: .bottom) {
                // Horizontal Target Dashed Line
                targetDashedLine
                    .padding(.bottom, targetLineYOffset + 24) // offset above day labels
                
                // 7 Vertical Day Columns
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        dayBarColumn(index: index)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 140)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        // Accent border matching the active metric
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeColor, lineWidth: appHighContrast ? 3.0 : 2.0)
        )
        .animation(appReduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: selectedMetric)
    }
    
    // MARK: - Column for a single day (Bar + Day Letter + Optional Percentage)
    @ViewBuilder
    private func dayBarColumn(index: Int) -> some View {
        let height: CGFloat = {
            switch selectedMetric {
            case .quality:
                guard index < qualityPercentages.count else { return 60 }
                let val = CGFloat(qualityPercentages[index])
                let target = CGFloat(max(1, qualityTarget))
                let computed = (val / target) * targetLineYOffset
                return min(max(computed, 15), 115)
                
            case .sleep:
                guard index < sleepMinutesPerDay.count else { return 60 }
                let val = CGFloat(sleepMinutesPerDay[index])
                let target = CGFloat(max(1, sleepTargetMinutes))
                let computed = (val / target) * targetLineYOffset
                return min(max(computed, 15), 115)
                
            case .training:
                guard index < trainingMinutesPerDay.count else { return 8 }
                let val = CGFloat(trainingMinutesPerDay[index])
                if val <= 0 {
                    return 8 // Subtle resting capsule height
                }
                let target = CGFloat(max(1, trainingDailyTargetMinutes))
                let computed = (val / target) * targetLineYOffset
                return min(max(computed, 16), 115)
            }
        }()
        
        VStack(spacing: 6) {
            // If Quality is selected, display percentage label above the bar
            if selectedMetric == .quality && index < qualityPercentages.count {
                Text("\(qualityPercentages[index])%")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(themeColor)
                    .transition(.opacity.combined(with: .scale))
            } else {
                Spacer()
                    .frame(height: 12)
            }
            
            // Vertical Rounded Bar
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(themeColor)
                .frame(width: 22, height: height)
                .animation(appReduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.78), value: height)
                .animation(appReduceMotion ? nil : .easeInOut(duration: 0.25), value: themeColor)
            
            // Day Letter Label
            Text(dayLetters[index])
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Horizontal Dashed Target Line
    private var targetDashedLine: some View {
        Line()
            .stroke(
                Color.secondary.opacity(0.35),
                style: StrokeStyle(lineWidth: 1, dash: [4, 4])
            )
            .frame(height: 1)
    }
}

// MARK: - Simple Horizontal Line Shape for Target
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        SummaryDetailChartView(selectedMetric: .sleep)
        SummaryDetailChartView(selectedMetric: .quality)
        SummaryDetailChartView(selectedMetric: .training)
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
