//
//  StandardHeaderView.swift
//  WorkoutRecoveryApp
//
//  Created by Senior iOS Developer on 29/10/2026.
//

import SwiftUI

public struct StandardHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let title: String
    public let dateSubtitle: String
    public let days: [DayItem]
    public let selectedDayIndex: Int
    public let showProfileButton: Bool
    public let showDaySelector: Bool
    public let profileIconName: String
    public let profileIconColor: Color
    public let onSelectDay: (Int) -> Void
    public let onProfileTap: (() -> Void)?
    
    public init(
        title: String,
        dateSubtitle: String,
        days: [DayItem] = [],
        selectedDayIndex: Int = 0,
        showProfileButton: Bool = false,
        showDaySelector: Bool = true,
        profileIconName: String = "person.crop.circle.fill",
        profileIconColor: Color = .primary,
        onSelectDay: @escaping (Int) -> Void = { _ in },
        onProfileTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.dateSubtitle = dateSubtitle
        self.days = days
        self.selectedDayIndex = selectedDayIndex
        self.showProfileButton = showProfileButton
        self.showDaySelector = showDaySelector
        self.profileIconName = profileIconName
        self.profileIconColor = profileIconColor
        self.onSelectDay = onSelectDay
        self.onProfileTap = onProfileTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Title Bar & Optional Profile Icon
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                    
                    Text(dateSubtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Profile button EXCLUSIVELY in Summary screen (Liquid Glass style)
                if showProfileButton {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        onProfileTap?()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                                )
                                .frame(width: 38, height: 38)
                            
                            Image(systemName: profileIconName)
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(profileIconName == "calendar" ? "Open calendar" : "Personalize your Profile")
                }
            }
            .padding(.horizontal, 20)
            
            // MARK: - Day Selector Pill Container (M  T  W  T  F  S  S)
            if showDaySelector {
                HStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        let isSelected = (index == selectedDayIndex)
                        
                        Button {
                            onSelectDay(index)
                        } label: {
                            Text(day.letter)
                                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(
                                    isSelected
                                        ? (colorScheme == .dark ? Color.black : Color.white)
                                        : (colorScheme == .dark ? Color.white.opacity(0.65) : Color(uiColor: .secondaryLabel))
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background {
                                    if isSelected {
                                        Circle()
                                            .fill(colorScheme == .dark ? Color.white : Color.black)
                                            .frame(width: 30, height: 30)
                                            .matchedGeometryEffect(id: "ActiveDayPill", in: dayNamespace)
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
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
    
    @Namespace private var dayNamespace
}

#Preview {
    StandardHeaderView(
        title: "Summary",
        dateSubtitle: "Today, Wednesday 28 October",
        days: [
            DayItem(id: 0, letter: "M", dayNumber: 26, fullDateDescription: "Monday, 26 October"),
            DayItem(id: 1, letter: "T", dayNumber: 27, fullDateDescription: "Tuesday, 27 October"),
            DayItem(id: 2, letter: "W", dayNumber: 28, fullDateDescription: "Today, Wednesday 28 October"),
            DayItem(id: 3, letter: "T", dayNumber: 29, fullDateDescription: "Thursday, 29 October"),
            DayItem(id: 4, letter: "F", dayNumber: 30, fullDateDescription: "Friday, 30 October"),
            DayItem(id: 5, letter: "S", dayNumber: 31, fullDateDescription: "Saturday, 31 October"),
            DayItem(id: 6, letter: "S", dayNumber: 1,  fullDateDescription: "Sunday, 1 November")
        ],
        selectedDayIndex: 2,
        showProfileButton: true,
        onSelectDay: { _ in }
    )
}
