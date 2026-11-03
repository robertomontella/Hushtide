//
//  SleepCardView.swift
//  RecoveryApp
//
//  Created by Antigravity on 30/10/2026.
//

import SwiftUI

public struct SleepCardView: View {
    public let progress: Double
    public let durationText: String
    public let targetText: String
    public let accentColor: Color
    public let trackColor: Color
    public let inBedTime: String
    public let asleepTime: String
    public var onEditGoal: (() -> Void)? = nil
    public var onEditInBedTime: (() -> Void)? = nil
    public var onEditAsleepTime: (() -> Void)? = nil
    
    public init(
        progress: Double,
        durationText: String,
        targetText: String,
        accentColor: Color = Color(red: 0.33, green: 0.36, blue: 1.0),
        trackColor: Color = Color(red: 0.83, green: 0.83, blue: 0.95),
        inBedTime: String,
        asleepTime: String,
        onEditGoal: (() -> Void)? = nil,
        onEditInBedTime: (() -> Void)? = nil,
        onEditAsleepTime: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.durationText = durationText
        self.targetText = targetText
        self.accentColor = accentColor
        self.trackColor = trackColor
        self.inBedTime = inBedTime
        self.asleepTime = asleepTime
        self.onEditGoal = onEditGoal
        self.onEditInBedTime = onEditInBedTime
        self.onEditAsleepTime = onEditAsleepTime
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Circular Progress Gauge (Tappable target to set sleep goal)
            SleepGaugeView(
                progress: progress,
                durationText: durationText,
                targetText: targetText,
                accentColor: accentColor,
                trackColor: trackColor,
                onEditGoal: onEditGoal
            )
            .padding(.top, 0)
            
            // In Bed & Asleep Schedule Rows (Matching new design with icons & chevron pills)
            VStack(spacing: 9) {
                SleepScheduleRowView(
                    title: "In Bed",
                    subtitle: "Bedtime schedule",
                    iconName: "bed.double.fill",
                    timeString: inBedTime,
                    accentColor: accentColor,
                    onTap: onEditInBedTime
                )
                
                SleepScheduleRowView(
                    title: "Asleep",
                    subtitle: "Wake-up alarm",
                    iconName: "alarm.fill",
                    timeString: asleepTime,
                    accentColor: accentColor,
                    onTap: onEditAsleepTime
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
        )
    }
}

#Preview {
    SleepCardView(
        progress: 0.968,
        durationText: "7h 45m",
        targetText: "of 8h",
        inBedTime: "11:00 PM",
        asleepTime: "6:45 AM",
        onEditGoal: {}
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
