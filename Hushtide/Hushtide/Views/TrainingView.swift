import SwiftUI

public struct TrainingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appHighContrast) private var appHighContrast
    @Bindable public var viewModel: TrainingModel
    @State private var isCalendarOpen: Bool = false
    @State private var isAddWorkoutPresented: Bool = false
    @State private var expandedWorkoutId: UUID? = nil
    @State private var editingWorkout: LoggedWorkout? = nil
    @State private var workoutToDelete: LoggedWorkout? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    StandardHeaderView(
                        title: viewModel.trainingTitle,
                        dateSubtitle: viewModel.currentDaySubtitle,
                        days: viewModel.days,
                        selectedDayIndex: viewModel.selectedDayIndex,
                        showProfileButton: true,
                        profileIconName: "calendar",
                        onSelectDay: { index in
                            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                expandedWorkoutId = nil
                            }
                            viewModel.selectDay(at: index)
                        },
                        onProfileTap: {
                            HapticManager.impact(.light)
                            withAppAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                isCalendarOpen.toggle()
                            }
                        }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.height > 40 && abs(value.translation.width) < 50 && !isCalendarOpen {
                                    HapticManager.impact(.medium)
                                    withAppAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        isCalendarOpen = true
                                    }
                                }
                            }
                    )
                    
                    VStack(spacing: 16) {
                        mainReadinessCard
                        
                        recommendedIntensitySection
                        
                        addWorkoutSection
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 20)
                }
                .padding(.top, 4)
            }
            .scrollBounceBehavior(.always, axes: .vertical)
            .refreshable {
                if viewModel.isAppleHealthConnected {
                    await viewModel.syncHealthData(requireAuthentication: false)
                }
            }
            
            if isCalendarOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            isCalendarOpen = false
                        }
                    }
                    .transition(.opacity)
                
                calendarDropDownView
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .zIndex(100)
            }
        }
        .onAppear {
            viewModel.evaluateRecovery()
        }
        .sheet(isPresented: $isAddWorkoutPresented) {
            AddWorkoutView(viewModel: viewModel)
        }
        .sheet(item: $editingWorkout) { workout in
            AddWorkoutView(viewModel: viewModel, editingWorkout: workout)
        }
        .alert("Delete Workout", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    viewModel.deleteWorkout(id: workout.id)
                }
                workoutToDelete = nil
            }
        } message: {
            if let workout = workoutToDelete {
                Text("Are you sure you want to delete this \(workout.sportType) workout? This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this workout? This action cannot be undone.")
            }
        }
    }
    
    private var calendarDropDownView: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Date")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(viewModel.calendarModel.formattedHeaderTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    HapticManager.impact(.light)
                    viewModel.calendarModel.goToToday()
                    viewModel.selectDay(at: viewModel.calendarModel.selectedDayIndex)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .bold))
                        Text("Today")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(viewModel.dynamicThemeColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.dynamicThemeColor.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticManager.impact(.light)
                    withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isCalendarOpen = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            
            DatePicker(
                "Select Date",
                selection: Binding(
                    get: { viewModel.calendarModel.selectedDate },
                    set: { newDate in
                        viewModel.calendarModel.selectDate(newDate)
                        viewModel.selectDay(at: viewModel.calendarModel.selectedDayIndex)
                    }
                ),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(viewModel.dynamicThemeColor)
            .padding(.horizontal, 14)
            
            VStack(spacing: 4) {
                Capsule()
                    .fill(Color(uiColor: .systemGray3))
                    .frame(width: 40, height: 5)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height < -15 || value.translation.height > 35 {
                            HapticManager.impact(.light)
                            withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                isCalendarOpen = false
                            }
                        }
                    }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.14), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }
    
    private var mainReadinessCard: some View {
        VStack(spacing: 14) {
            ReadinessRingView(
                score: viewModel.readinessScore,
                dynamicColor: viewModel.dynamicThemeColor,
                readinessLabel: viewModel.readinessLabel
            )
            
            VStack(spacing: 4) {
                Text(viewModel.recoveryStatusTitle)
                    .font(.system(size: 20.5, weight: .bold))
                    .foregroundColor(viewModel.dynamicThemeColor)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.dynamicThemeColor)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.recoveryStatusTitle)
                
                Text(viewModel.recoveryStatusDescription)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.recoveryStatusDescription)
            }
            .padding(.top, -4)
            
            MetricsBoxView(
                sleepDebtMetric: viewModel.sleepDebtMetric,
                restedMetric: viewModel.qualityMetric,
                regularityMetric: viewModel.regularityMetric
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
        )
    }
    
    private var recommendedIntensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Circle()
                    .fill(viewModel.dynamicThemeColor)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.recommendedIntensityBadgeText)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(viewModel.dynamicThemeColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(viewModel.dynamicThemeColor.opacity(0.15))
            )
            .animation(.easeInOut(duration: 0.25), value: viewModel.dynamicThemeColor)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.recommendedIntensityLevel)
            
            IntensitySelectorView(
                recommendedIntensity: viewModel.recommendedIntensityLevel,
                dynamicColor: viewModel.dynamicThemeColor
            )
        }
    }
    
    private var addWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADD YOUR WORKOUT")
                .font(.system(size: 12.5, weight: .bold))
                .tracking(1.0)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            if viewModel.currentDayWorkouts.isEmpty {
                Button {
                    HapticManager.impact(.light)
                    isAddWorkoutPresented = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 38, height: 38)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Your Workout")
                                .font(.system(size: 15.5, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Discipline, target intensity & duration")
                                .font(.system(size: 12.5, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.currentDayWorkouts) { workout in
                        let isExpanded = (expandedWorkoutId == workout.id)
                        
                        VStack(spacing: 0) {
                            Button {
                                HapticManager.impact(.light)
                                withAppAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    if expandedWorkoutId == workout.id {
                                        expandedWorkoutId = nil
                                    } else {
                                        expandedWorkoutId = workout.id
                                    }
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(viewModel.dynamicThemeColor.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: workout.sportIcon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(viewModel.dynamicThemeColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(workout.sportType)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            Text("• \(workout.intensity.rawValue)")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(viewModel.dynamicThemeColor)
                                        }
                                        
                                        Text("\(workout.durationMinutes) min • \(workout.timeString)")
                                            .font(.system(size: 12.5, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 19))
                                            .foregroundColor(viewModel.dynamicThemeColor)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .zIndex(2)
                            
                            if isExpanded {
                                VStack(alignment: .leading, spacing: 12) {
                                    Divider()
                                        .padding(.horizontal, 2)
                                    
                                    HStack(spacing: 12) {
                                        detailPill(icon: "clock.fill", title: "Duration", value: "\(workout.durationMinutes)m")
                                        detailPill(icon: "flame.fill", title: "Intensity", value: workout.intensity.rawValue)
                                    }
                                    
                                    if !workout.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 5) {
                                                Image(systemName: "note.text")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.secondary)
                                                Text("NOTES")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Text(workout.notes)
                                                .font(.system(size: 13.5, weight: .regular))
                                                .foregroundColor(.primary)
                                                .padding(10)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                                                )
                                        }
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            HapticManager.impact(.light)
                                            editingWorkout = workout
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 13, weight: .semibold))
                                                Text("Edit")
                                                    .font(.system(size: 13.5, weight: .semibold))
                                            }
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 38)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1.5)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        appHighContrast
                                                            ? (colorScheme == .dark ? Color.white : Color.black)
                                                            : Color(uiColor: .separator).opacity(0.4),
                                                        lineWidth: appHighContrast ? 2 : 1
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button {
                                            HapticManager.impact(.medium)
                                            workoutToDelete = workout
                                            showDeleteConfirmation = true
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "trash.fill")
                                                    .font(.system(size: 13, weight: .semibold))
                                                Text("Delete")
                                                    .font(.system(size: 13.5, weight: .semibold))
                                            }
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 38)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1.5)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        appHighContrast
                                                            ? (colorScheme == .dark ? Color.white : Color.black)
                                                            : Color(uiColor: .separator).opacity(0.4),
                                                        lineWidth: appHighContrast ? 2 : 1
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.top, 4)
                                    .id("actionButtons")
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 14)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .zIndex(1)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            appHighContrast
                                                ? (colorScheme == .dark ? Color.white : Color.black)
                                                : Color.clear,
                                            lineWidth: appHighContrast ? 2 : 0
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        )
                    }
                    
                    Button {
                        isAddWorkoutPresented = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add Another Workout")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailPill(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        )
    }
}

#Preview {
    TrainingView(viewModel: TrainingModel())
}
