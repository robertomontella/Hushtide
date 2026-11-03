//
//  TrainingView.swift
//  RecoveryApp
//
//  Created by AFP FED 019 on 28/10/2026.
//

import SwiftUI

public struct TrainingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable public var viewModel: TrainingModel
    @State private var isDebugSheetPresented: Bool = false
    @State private var isAddWorkoutPresented: Bool = false
    @State private var expandedWorkoutId: UUID? = nil
    @State private var editingWorkout: LoggedWorkout? = nil
    @State private var workoutToDelete: LoggedWorkout? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // MARK: - Header with Date & Weekday Selector
                headerSection
                
                // MARK: - Screen Content (Compact, Elegant & Feature-Complete)
                VStack(spacing: 16) {
                    // 1. Main Readiness Card (Compact)
                    mainReadinessCard
                    
                    // 2. Recommended Intensity (Badge as Title + Auto-selected Buttons)
                    recommendedIntensitySection
                    
                    // 3. Add Your Workout Feature
                    addWorkoutSection
                }
                .padding(.horizontal, 20)
                
                // Bottom breathing room above TabBar
                Spacer()
                    .frame(height: 120)
            }
            .padding(.top, 4)
        }
        .scrollBounceBehavior(.always, axes: .vertical)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            viewModel.evaluateRecovery()
        }
        .sheet(isPresented: $isDebugSheetPresented) {
            debugSliderSheet
                .presentationDetents([.height(230)])
                .presentationDragIndicator(.visible)
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title & Date Subtitle + Discreet Debug Lab Pill
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.trainingTitle)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(viewModel.currentDaySubtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Discreet Slider Debug Button (Liquid Glass Capsule)
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    isDebugSheetPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.dynamicThemeColor)
                            .frame(width: 7, height: 7)
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Readiness Debug Slider")
            }
            .padding(.horizontal, 20)
            
            // Day Selector Pill Container (M  T  W  T  F  S  S)
            HStack(spacing: 0) {
                ForEach(Array(viewModel.days.enumerated()), id: \.element.id) { index, day in
                    let isSelected = (index == viewModel.selectedDayIndex)
                    
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            expandedWorkoutId = nil
                        }
                        viewModel.selectDay(at: index)
                    } label: {
                        Text(day.letter)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundColor(
                                isSelected
                                    ? (colorScheme == .dark ? Color.black : Color.white)
                                    : (colorScheme == .dark ? Color.white.opacity(0.65) : Color(uiColor: .secondaryLabel))
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background {
                                if isSelected {
                                    Circle()
                                        .fill(colorScheme == .dark ? Color.white : Color.black)
                                        .frame(width: 32, height: 32)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.8)
                    )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
            )
            .padding(.horizontal, 20)
        }
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    // MARK: - Main Readiness Card (Compact & Reduced)
    private var mainReadinessCard: some View {
        VStack(spacing: 14) {
            // Semicircular Arc Gauge (Read-only display)
            ReadinessRingView(
                score: viewModel.readinessScore,
                dynamicColor: viewModel.dynamicThemeColor,
                readinessLabel: viewModel.readinessLabel
            )
            
            // Recovery Status & Description
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
            
            // Secondary Metrics Box (Compact, ends cleanly)
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
    
    // MARK: - Recommended Intensity Section (Badge as Title + Auto-selected Cards)
    private var recommendedIntensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Colored Pill Badge as the New Title (enlarged & prominent)
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
            
            // 4 Intensity Cards (Auto-activated, read-only)
            IntensitySelectorView(
                recommendedIntensity: viewModel.recommendedIntensityLevel,
                dynamicColor: viewModel.dynamicThemeColor
            )
        }
    }
    
    // MARK: - Add Your Workout Section
    private var addWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADD YOUR WORKOUT")
                .font(.system(size: 12.5, weight: .bold))
                .tracking(1.0)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            if viewModel.currentDayWorkouts.isEmpty {
                // Interactive Pill Card with Plus icon
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
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
                            // Top Row Card Header (Tappable, ZIndex: 2, Opaque)
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.prepare()
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
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
                            
                            // Expanded Workout Details & Action Buttons (ZIndex: 1, hides under header)
                            if isExpanded {
                                VStack(alignment: .leading, spacing: 12) {
                                    Divider()
                                        .padding(.horizontal, 2)
                                    
                                    // Detail Summary Badges (Duration & Intensity, evenly proportioned horizontally)
                                    HStack(spacing: 12) {
                                        detailPill(icon: "clock.fill", title: "Duration", value: "\(workout.durationMinutes)m")
                                        detailPill(icon: "flame.fill", title: "Intensity", value: workout.intensity.rawValue)
                                    }
                                    
                                    // Optional User Notes Display
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
                                    
                                    // Edit & Delete Action Buttons (Styled with readiness theme & soft iOS HIG tint)
                                    HStack(spacing: 12) {
                                        // Edit Button (Neutral Card Style with Blue Text & Icon)
                                        Button {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.prepare()
                                            generator.impactOccurred()
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
                                                    .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // Delete Button (Neutral Card Style - Matching unselected intensity card)
                                        Button {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.prepare()
                                            generator.impactOccurred()
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
                                                    .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
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
    
    // MARK: - Interactive Debug Sheet (0–100% Slider & Presets)
    private var debugSliderSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                HStack {
                    Circle()
                        .fill(viewModel.dynamicThemeColor)
                        .frame(width: 10, height: 10)
                    
                    Text("\(Int(viewModel.readinessScore))% Readiness • \(viewModel.dynamicColorName)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(viewModel.dynamicThemeColor)
                    
                    Spacer()
                    
                    Button("Done") {
                        isDebugSheetPresented = false
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
                .padding(.top, 6)
                
                // Continuous Slider (0 – 100)
                Slider(
                    value: Binding(
                        get: { viewModel.readinessScore },
                        set: { newValue in
                            viewModel.setReadinessScore(newValue)
                        }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(viewModel.dynamicThemeColor)
                
                // Quick Color Scenarios
                HStack(spacing: 8) {
                    presetButton(label: "Red (25%)", score: 25, color: Color(red: 0.95, green: 0.26, blue: 0.21))
                    presetButton(label: "Orange (50%)", score: 50, color: Color(red: 1.0, green: 0.58, blue: 0.0))
                    presetButton(label: "Yellow (75%)", score: 75, color: Color(red: 0.96, green: 0.72, blue: 0.0))
                    presetButton(label: "Green (90%)", score: 90, color: Color(red: 0.20, green: 0.78, blue: 0.35))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .navigationTitle("Readiness Test Lab")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func presetButton(label: String, score: Double, color: Color) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            viewModel.setReadinessScore(score)
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(color.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
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
