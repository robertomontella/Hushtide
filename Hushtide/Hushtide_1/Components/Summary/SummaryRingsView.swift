//
//  SummaryRingsView.swift
//  RecoveryApp
//
//  Created by Antigravity on 30/10/2026.
//

import SwiftUI

/// A clean, non-elaborate concentric rings chart for the Summary view.
/// Displays three concentric progress rings representing Quality, Sleep, and Training metrics.
public struct SummaryRingsView: View {
    
    // MARK: - Ring Colors (Pixel-matched with design)
    // Outer Ring: Mint / Teal (Quality)
    private let qualityActiveColor = Color(red: 3/255.0, green: 199/255.0, blue: 190/255.0)
    private let qualityTrackColor = Color(red: 194/255.0, green: 234/255.0, blue: 236/255.0)
    
    // Middle Ring: Indigo / Purple (Sleep)
    private let sleepActiveColor = Color(red: 88/255.0, green: 86/255.0, blue: 215/255.0)
    private let sleepTrackColor = Color(red: 212/255.0, green: 211/255.0, blue: 242/255.0)
    
    // Inner Ring: Electric Blue (Training)
    private let trainingActiveColor = Color(red: 1/255.0, green: 113/255.0, blue: 227/255.0)
    private let trainingTrackColor = Color(red: 194/255.0, green: 217/255.0, blue: 244/255.0)
    
    // MARK: - Geometry Settings
    private let strokeWidth: CGFloat = 19
    private let outerDiameter: CGFloat = 216
    private let middleDiameter: CGFloat = 170
    private let innerDiameter: CGFloat = 124
    
    // MARK: - Progress Values (Arc fractions corresponding to the visual design)
    // Quality starts at top (12:00) and sweeps 220 degrees clockwise (~61% of circle)
    public var qualityProgress: Double = 220.0 / 360.0
    // Sleep starts at ~9:30 and sweeps 260 degrees down to ~6:00 (~72% of circle)
    public var sleepProgress: Double = 260.0 / 360.0
    // Training starts at ~10:20 and sweeps 235 degrees down to ~6:00 (~65% of circle)
    public var trainingProgress: Double = 235.0 / 360.0
    
    public init(
        qualityProgress: Double = 220.0 / 360.0,
        sleepProgress: Double = 260.0 / 360.0,
        trainingProgress: Double = 235.0 / 360.0
    ) {
        self.qualityProgress = qualityProgress
        self.sleepProgress = sleepProgress
        self.trainingProgress = trainingProgress
    }
    
    public var body: some View {
        ZStack {
            // 1. Outer Ring (Quality - Mint / Teal)
            ringLayer(
                diameter: outerDiameter,
                trackColor: qualityTrackColor,
                activeColor: qualityActiveColor,
                progress: qualityProgress,
                rotationDegrees: -90 // Starts at top (12 o'clock)
            )
            
            // 2. Middle Ring (Sleep - Indigo / Purple)
            ringLayer(
                diameter: middleDiameter,
                trackColor: sleepTrackColor,
                activeColor: sleepActiveColor,
                progress: sleepProgress,
                rotationDegrees: 195 // Starts at 285° (9:30)
            )
            
            // 3. Inner Ring (Training - Blue)
            ringLayer(
                diameter: innerDiameter,
                trackColor: trainingTrackColor,
                activeColor: trainingActiveColor,
                progress: trainingProgress,
                rotationDegrees: 220 // Starts at 310° (10:20)
            )
        }
        .frame(width: outerDiameter + strokeWidth, height: outerDiameter + strokeWidth)
        .padding(.vertical, 2)
    }
    
    // MARK: - Single Ring Helper
    /// Builds a full background circle track and a trimmed active progress arc with rounded caps.
    @ViewBuilder
    private func ringLayer(
        diameter: CGFloat,
        trackColor: Color,
        activeColor: Color,
        progress: Double,
        rotationDegrees: Double
    ) -> some View {
        ZStack {
            // Full background track circle in soft pastel tint
            Circle()
                .stroke(trackColor, lineWidth: strokeWidth)
                .frame(width: diameter, height: diameter)
            
            // Active progress arc with clean rounded caps on both ends
            Circle()
                .trim(from: 0.0, to: min(max(progress, 0.0), 1.0))
                .stroke(
                    activeColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(rotationDegrees))
                .animation(.spring(response: 0.55, dampingFraction: 0.8), value: progress)
        }
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
        SummaryRingsView()
    }
}
