import SwiftUI

public struct SummaryView: View {
    @Bindable public var viewModel: TrainingModel
    
    // Target Editing Sheet State
    @State private var editingTargetMetric: SummaryMetricTab? = nil
    @State private var temporaryQualityTarget: Double = 85.0
    @State private var temporarySleepGoal: Double = 8.0
    @State private var temporaryTrainingDailyTarget: Double = 30.0
    
    // Metric Accent Colors matching the rings and design specifications
    private let qualityColor = Color(red: 3/255.0, green: 199/255.0, blue: 190/255.0)  // Mint / Teal
    private let sleepColor = Color(red: 88/255.0, green: 86/255.0, blue: 215/255.0)    // Indigo / Purple
    private let trainingColor = Color(red: 1/255.0, green: 113/255.0, blue: 227/255.0) // System Electric Blue
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. Top Header Section
            // Includes "Summary" title, current date subtitle, and profile avatar button.
            // The weekday pill selector is hidden in Summary as shown in design.
            StandardHeaderView(
                title: viewModel.summaryTitle,
                dateSubtitle: viewModel.currentDaySubtitle,
                showProfileButton: true,
                showDaySelector: false,
                profileIconName: viewModel.profileAvatarIcon,
                profileIconColor: viewModel.profileAvatarColor,
                onProfileTap: {
                    viewModel.isProfilePresented = true
                }
            )
            .padding(.top, 4)
            .padding(.bottom, 2)
            
            // MARK: - 2. Scrollable Body Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Concentric Circular Rings (Quality, Sleep, Training)
                    SummaryRingsView(
                        qualityProgress: viewModel.summaryQualityProgress,
                        sleepProgress: viewModel.summarySleepProgress,
                        trainingProgress: viewModel.summaryTrainingProgress
                    )
                    .padding(.top, 0)
                    
                    // 3 Metric Cards Row (Quality, Sleep, Training) - Interactive Buttons
                    metricCardsRow
                    
                    // Dynamic Detail Chart (Quality %, Sleep Target, Training Minutes)
                    SummaryDetailChartView(
                        viewModel: viewModel
                    )
                    
                    // Bottom spacing to ensure clean clearance above the tab bar
                    Spacer()
                        .frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 2)
            }
            .refreshable {
                if viewModel.isAppleHealthConnected {
                    await viewModel.syncHealthData(requireAuthentication: false)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        // MARK: - Target Editing Sheet
        .sheet(item: $editingTargetMetric) { metric in
            switch metric {
            case .quality:
                qualityTargetPickerSheet
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            case .sleep:
                sleepGoalPickerSheet
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            case .training:
                trainingTargetPickerSheet
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Metric Cards Row (Interactive Buttons)
    /// Displays Quality, Sleep, and Training metric cards side-by-side with equal width.
    /// Single click switches the detailed chart below; changes must only be made by double-clicking on the cards.
    private var metricCardsRow: some View {
        HStack(spacing: 12) {
            // Quality Card (Mint / Teal)
            SummaryMetricCardView(
                title: "Quality",
                titleColor: qualityColor,
                value: viewModel.summaryQualityValue,
                subtitle: viewModel.summaryQualitySubtitle,
                isSelected: viewModel.selectedSummaryMetric == .quality,
                onTap: {
                    viewModel.selectSummaryMetric(.quality)
                },
                onDoubleTap: {
                    viewModel.selectSummaryMetric(.quality)
                    openTargetEditor(for: .quality)
                }
            )
            
            // Sleep Card (Indigo / Purple)
            SummaryMetricCardView(
                title: "Sleep",
                titleColor: sleepColor,
                value: viewModel.summarySleepValue,
                subtitle: viewModel.summarySleepSubtitle,
                isSelected: viewModel.selectedSummaryMetric == .sleep,
                onTap: {
                    viewModel.selectSummaryMetric(.sleep)
                },
                onDoubleTap: {
                    viewModel.selectSummaryMetric(.sleep)
                    openTargetEditor(for: .sleep)
                }
            )
            
            // Training Card (Electric Blue)
            SummaryMetricCardView(
                title: "Training",
                titleColor: trainingColor,
                value: viewModel.summaryTrainingValue,
                subtitle: viewModel.summaryTrainingSubtitle,
                isSelected: viewModel.selectedSummaryMetric == .training,
                onTap: {
                    viewModel.selectSummaryMetric(.training)
                },
                onDoubleTap: {
                    viewModel.selectSummaryMetric(.training)
                    openTargetEditor(for: .training)
                }
            )
        }
    }
    
    // MARK: - Open Target Editor Action
    private func openTargetEditor(for metric: SummaryMetricTab) {
        switch metric {
        case .quality:
            temporaryQualityTarget = Double(viewModel.qualityTargetPercentage)
        case .sleep:
            temporarySleepGoal = viewModel.sleepModel.targetSleepHours
        case .training:
            temporaryTrainingDailyTarget = Double(viewModel.trainingDailyMinutesTarget)
        }
        editingTargetMetric = metric
    }
    
    // MARK: - Quality Target Picker Sheet
    private var qualityTargetPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 26))
                            .foregroundColor(qualityColor)
                        
                        Text("\(Int(temporaryQualityTarget))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Target Weekly Quality Score")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                // Presets
                HStack(spacing: 8) {
                    qualityPresetButton(percentage: 70)
                    qualityPresetButton(percentage: 75)
                    qualityPresetButton(percentage: 80)
                    qualityPresetButton(percentage: 85)
                    qualityPresetButton(percentage: 90)
                    qualityPresetButton(percentage: 95)
                }
                .padding(.horizontal, 8)
                
                // Slider
                VStack(spacing: 8) {
                    Slider(
                        value: $temporaryQualityTarget,
                        in: 50.0...100.0,
                        step: 1.0
                    )
                    .tint(qualityColor)
                    
                    HStack {
                        Text("50% min")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("100% max")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Set Quality Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingTargetMetric = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.setQualityTarget(Int(temporaryQualityTarget))
                        editingTargetMetric = nil
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(qualityColor)
                }
            }
        }
    }
    
    @ViewBuilder
    private func qualityPresetButton(percentage: Int) -> some View {
        let isSelected = (Int(temporaryQualityTarget) == percentage)
        
        Button {
            HapticManager.impact(.light)
            withAppAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                temporaryQualityTarget = Double(percentage)
            }
        } label: {
            Text("\(percentage)%")
                .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? qualityColor : Color(uiColor: .systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Sleep Goal Picker Sheet (Synchronized with SleepModel)
    private var sleepGoalPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    let hours = Int(temporarySleepGoal)
                    let minutes = Int(round((temporarySleepGoal - Double(hours)) * 60))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 26))
                            .foregroundColor(sleepColor)
                        
                        Text(minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Target Sleep Goal Per Night")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                // Presets
                HStack(spacing: 8) {
                    sleepPresetButton(hours: 7.0, label: "7h")
                    sleepPresetButton(hours: 7.5, label: "7h 30m")
                    sleepPresetButton(hours: 8.0, label: "8h")
                    sleepPresetButton(hours: 8.5, label: "8h 30m")
                    sleepPresetButton(hours: 9.0, label: "9h")
                }
                .padding(.horizontal, 8)
                
                // Slider
                VStack(spacing: 8) {
                    Slider(
                        value: $temporarySleepGoal,
                        in: 5.0...12.0,
                        step: 0.25
                    )
                    .tint(sleepColor)
                    
                    HStack {
                        Text("5h min")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("12h max")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Set Sleep Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingTargetMetric = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.sleepModel.setTargetSleepHours(temporarySleepGoal)
                        editingTargetMetric = nil
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(sleepColor)
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepPresetButton(hours: Double, label: String) -> some View {
        let isSelected = (abs(temporarySleepGoal - hours) < 0.05)
        
        Button {
            HapticManager.impact(.light)
            withAppAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                temporarySleepGoal = hours
            }
        } label: {
            Text(label)
                .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? sleepColor : Color(uiColor: .systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Training Target Picker Sheet
    private var trainingTargetPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 26))
                            .foregroundColor(trainingColor)
                        
                        Text("\(Int(temporaryTrainingDailyTarget))m / day")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Daily Target · Calculated Weekly: \(Int(temporaryTrainingDailyTarget) * 7)m")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                // Presets
                HStack(spacing: 8) {
                    trainingPresetButton(minutes: 15)
                    trainingPresetButton(minutes: 20)
                    trainingPresetButton(minutes: 30)
                    trainingPresetButton(minutes: 45)
                    trainingPresetButton(minutes: 60)
                    trainingPresetButton(minutes: 90)
                }
                .padding(.horizontal, 8)
                
                // Slider
                VStack(spacing: 8) {
                    Slider(
                        value: $temporaryTrainingDailyTarget,
                        in: 5.0...120.0,
                        step: 5.0
                    )
                    .tint(trainingColor)
                    
                    HStack {
                        Text("5m / day min")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("120m / day max")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Set Daily Training Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingTargetMetric = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.setTrainingDailyTarget(Int(temporaryTrainingDailyTarget))
                        editingTargetMetric = nil
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(trainingColor)
                }
            }
        }
    }
    
    @ViewBuilder
    private func trainingPresetButton(minutes: Int) -> some View {
        let isSelected = (Int(temporaryTrainingDailyTarget) == minutes)
        
        Button {
            HapticManager.impact(.light)
            withAppAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                temporaryTrainingDailyTarget = Double(minutes)
            }
        } label: {
            Text("\(minutes)m")
                .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? trainingColor : Color(uiColor: .systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SummaryView(viewModel: TrainingModel())
}
