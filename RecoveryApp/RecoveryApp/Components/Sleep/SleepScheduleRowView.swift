//
//  SleepScheduleRowView.swift
//  RecoveryApp
//
//  Created by Antigravity on 30/10/2026.
//

import SwiftUI

public struct SleepScheduleRowView: View {
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let timeString: String
    public let accentColor: Color
    public var onTap: (() -> Void)? = nil
    
    public init(
        title: String,
        subtitle: String,
        iconName: String,
        timeString: String,
        accentColor: Color = Color(red: 0.33, green: 0.36, blue: 1.0),
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.timeString = timeString
        self.accentColor = accentColor
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            onTap?()
        } label: {
            HStack(spacing: 14) {
                // Circular Icon with soft purple background
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                // Title and Subtitle (e.g. "In Bed", "Bedtime schedule")
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time Selector Pill with Chevrons
                HStack(spacing: 7) {
                    Text(timeString)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemFill))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.8)
                        )
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle), \(timeString)")
    }
}

#Preview {
    VStack(spacing: 12) {
        SleepScheduleRowView(
            title: "In Bed",
            subtitle: "Bedtime schedule",
            iconName: "bed.double.fill",
            timeString: "11:00 PM"
        )
        
        SleepScheduleRowView(
            title: "Asleep",
            subtitle: "Wake-up alarm",
            iconName: "alarm.fill",
            timeString: "6:45 AM"
        )
    }
    .padding()
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .cornerRadius(24)
    .padding()
}
