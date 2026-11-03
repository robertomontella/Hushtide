//
//  SleepGaugeView.swift
//  RecoveryApp
//
//  Created by Antigravity on 30/10/2026.
//

import SwiftUI

public struct SleepGaugeView: View {
    public let progress: Double
    public let durationText: String
    public let targetText: String
    public let accentColor: Color
    public let trackColor: Color
    public var onEditGoal: (() -> Void)? = nil
    
    public init(
        progress: Double,
        durationText: String,
        targetText: String,
        accentColor: Color = Color(red: 0.33, green: 0.36, blue: 1.0),
        trackColor: Color = Color(red: 0.83, green: 0.83, blue: 0.95),
        onEditGoal: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.durationText = durationText
        self.targetText = targetText
        self.accentColor = accentColor
        self.trackColor = trackColor
        self.onEditGoal = onEditGoal
    }
    
    public var body: some View {
        ZStack {
            // Background Inactive Track
            Circle()
                .stroke(trackColor, lineWidth: 15)
            
            // Foreground Active Progress Arc
            Circle()
                .trim(from: 0.0, to: CGFloat(max(0.01, min(1.0, progress))))
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.78), value: progress)
            
            // Central Metrics Text
            VStack(spacing: 4) {
                Text(durationText)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: durationText)
                
                // Sleep Goal Target (Interactive to edit goal)
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
                    onEditGoal?()
                } label: {
                    HStack(spacing: 4) {
                        Text(targetText)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: .systemGray6).opacity(0.7))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change sleep goal, currently \(targetText)")
            }
        }
        .frame(width: 154, height: 154)
        .padding(.vertical, 2)
    }
}

#Preview {
    SleepGaugeView(
        progress: 0.968,
        durationText: "7h 45m",
        targetText: "of 8h",
        onEditGoal: {}
    )
    .padding()
}
