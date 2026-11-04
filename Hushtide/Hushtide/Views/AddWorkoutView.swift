import SwiftUI

public struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var viewModel: TrainingModel
    public var editingWorkout: LoggedWorkout?
    
    @State private var selectedSport: String = "Running"
    @State private var selectedIntensity: IntensityLevel = .hard
    @State private var durationHours: Int = 0
    @State private var durationMinutes: Int = 5
    @State private var scheduledTime: Date = Date()
    @State private var rpeScore: Double = 8.0
    @State private var notesText: String = ""
    @FocusState private var isNotesFocused: Bool
    
    private let selectableIntensities: [IntensityLevel] = [.light, .medium, .hard]
    private let hoursOptions: [Int] = [0, 1, 2, 3, 4, 5]
    private let minutesOptions: [Int] = Array(stride(from: 0, through: 55, by: 5))
    
    private var isEditing: Bool {
        editingWorkout != nil
    }
    
    private var totalDurationMinutes: Int {
        let total = (durationHours * 60) + durationMinutes
        return total > 0 ? total : 5
    }
    
    private var durationFormattedString: String {
        String(format: "%02dh %02dm", durationHours, durationMinutes)
    }
    
    private var availableSports: [(name: String, icon: String)] {
        var sports = viewModel.allAvailableSports
        let profileSport = viewModel.sportType
        if profileSport != "-" && !profileSport.isEmpty && sports.contains(profileSport) {
            sports.removeAll(where: { $0 == profileSport })
            sports.insert(profileSport, at: 0)
        }
        return sports.map { ($0, ProfileOptions.icon(for: $0)) }
    }
    
    private var formattedRecoveryStatusTitle: String {
        switch viewModel.recoveryStatusTitle {
        case "Ready to push":
            return "Ready\nto push"
        case "Take it easy":
            return "Take it\neasy"
        case "Needs rest":
            return "Needs\nrest"
        case "Moderate readiness":
            return "Moderate\nreadiness"
        default:
            return viewModel.recoveryStatusTitle
        }
    }
    
    public init(viewModel: TrainingModel, editingWorkout: LoggedWorkout? = nil) {
        self.viewModel = viewModel
        self.editingWorkout = editingWorkout
        
        if let editing = editingWorkout {
            _selectedSport = State(initialValue: editing.sportType)
            let safeIntensity = editing.intensity == .rest ? .light : editing.intensity
            _selectedIntensity = State(initialValue: safeIntensity)
            _durationHours = State(initialValue: editing.durationMinutes / 60)
            _durationMinutes = State(initialValue: editing.durationMinutes % 60)
            _scheduledTime = State(initialValue: editing.scheduledDate)
            _rpeScore = State(initialValue: Double(editing.rpe))
            _notesText = State(initialValue: editing.notes)
        } else {
            let rec = viewModel.recommendedIntensityLevel
            let safeRec = rec == .rest ? .light : rec
            _selectedIntensity = State(initialValue: safeRec)
            
            let profileSport = viewModel.sportType
            let defaultSport: String
            if profileSport != "-" && !profileSport.isEmpty {
                defaultSport = profileSport
            } else {
                defaultSport = ProfileOptions.sports.first ?? "Running"
            }
            _selectedSport = State(initialValue: defaultSport)
            _durationHours = State(initialValue: 0)
            _durationMinutes = State(initialValue: 5)
            
            let targetDay = viewModel.dateForDay(at: viewModel.selectedDayIndex)
            let now = Date()
            if Calendar.current.isDate(targetDay, inSameDayAs: now) {
                _scheduledTime = State(initialValue: now)
            } else {
                let hour = Calendar.current.component(.hour, from: now)
                let minute = Calendar.current.component(.minute, from: now)
                let resolved = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: targetDay) ?? targetDay
                _scheduledTime = State(initialValue: resolved)
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        intensitySection
                        intensityGuidanceNote
                        activitySection
                        durationSection
                        notesSection
                        saveActionButton
                        
                        Spacer().frame(height: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(isEditing ? "Edit Workout" : "Add Your Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            if !isEditing {
                let profileSport = viewModel.sportType
                if profileSport != "-" && !profileSport.isEmpty {
                    selectedSport = profileSport
                }
            }
        }
    }
    
    private var intensityGuidanceNote: some View {
        HStack {
            Text(
                viewModel.recommendedIntensityLevel == .rest
                    ? "Readiness suggests rest. If active, Light intensity is advised."
                    : "Recommended Intensity is \(viewModel.recommendedIntensityLevel.rawValue). Feel free to adapt."
            )
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, -6)
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVITY TYPE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableSports, id: \.name) { sport in
                        let isSelected = (selectedSport == sport.name)
                        
                        Button {
                            HapticManager.impact(.light)
                            withAppAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSport = sport.name
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: sport.icon)
                                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                
                                Text(sport.name)
                                    .font(.system(size: 13.5, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundColor(isSelected ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground))
                                    .shadow(color: isSelected ? Color.blue.opacity(0.25) : Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SESSION INTENSITY RECOMMENDED")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if selectedIntensity == viewModel.recommendedIntensityLevel {
                    Text("✓ Matches Readiness")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(viewModel.dynamicThemeColor)
                }
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 8) {
                ForEach(selectableIntensities) { level in
                    let isSelected = (selectedIntensity == level)
                    
                    Button {
                        HapticManager.impact(.light)
                        withAppAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedIntensity = level
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: level.iconName)
                                .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? viewModel.dynamicThemeColor : .primary)
                            
                            Text(level.rawValue)
                                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? viewModel.dynamicThemeColor : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 66)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                .shadow(
                                    color: isSelected ? viewModel.dynamicThemeColor.opacity(0.18) : Color.black.opacity(0.03),
                                    radius: isSelected ? 8 : 4,
                                    x: 0,
                                    y: 2
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            isSelected ? viewModel.dynamicThemeColor : Color.clear,
                                            lineWidth: 1.8
                                        )
                                    )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Text(formattedRecoveryStatusTitle)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(viewModel.dynamicThemeColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity)
                    .frame(height: 66)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    )
            }
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DURATION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(durationFormattedString)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 0) {
                Picker("Hours", selection: $durationHours) {
                    ForEach(hoursOptions, id: \.self) { h in
                        Text(String(format: "%02dh", h))
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                
                Picker("Minutes", selection: $durationMinutes) {
                    ForEach(minutesOptions, id: \.self) { m in
                        Text(String(format: "%02dm", m))
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 105)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NOTES (OPTIONAL)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(height: 34)
            .padding(.horizontal, 4)
            .overlay(alignment: .trailing) {
                if isNotesFocused {
                    Button {
                        HapticManager.impact(.light)
                        isNotesFocused = false
                    } label: {
                        Text("Done")
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.85))
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 1.5)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isNotesFocused)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notesText)
                    .focused($isNotesFocused)
                    .font(.system(size: 14.5, weight: .regular))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                
                if notesText.isEmpty {
                    Text("e.g. 5x3 Squats at 120kg, focus on bar speed, felt energetic throughout the session...")
                        .font(.system(size: 14.5, weight: .regular))
                        .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .padding(.top, 14)
    }
    
    private var saveActionButton: some View {
        Button {
            saveAndDismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                
                Text(isEditing ? "Save Changes" : "Save Workout")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(Color.blue)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 24)
    }
    
    private func saveAndDismiss() {
        if let editing = editingWorkout {
            let updated = LoggedWorkout(
                id: editing.id,
                sportType: selectedSport,
                intensity: selectedIntensity,
                durationMinutes: totalDurationMinutes,
                focusArea: "",
                scheduledDate: scheduledTime,
                dayIndex: editing.dayIndex,
                rpe: Int(rpeScore),
                notes: notesText
            )
            viewModel.updateWorkout(updated)
        } else {
            viewModel.addWorkout(
                sportType: selectedSport,
                intensity: selectedIntensity,
                durationMinutes: totalDurationMinutes,
                focusArea: "",
                scheduledDate: scheduledTime,
                dayIndex: viewModel.selectedDayIndex,
                rpe: Int(rpeScore),
                notes: notesText
            )
        }
        dismiss()
    }
}

#Preview {
    AddWorkoutView(viewModel: TrainingModel())
}
