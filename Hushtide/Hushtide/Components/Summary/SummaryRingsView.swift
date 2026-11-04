import SwiftUI

public struct SummaryRingsView: View {
    @Environment(\.appHighContrast) private var appHighContrast
    @Environment(\.appReduceMotion) private var appReduceMotion
    
    private let qualityActiveColor = Color(red: 3/255.0, green: 199/255.0, blue: 190/255.0)
    private let qualityTrackColor = Color(red: 194/255.0, green: 234/255.0, blue: 236/255.0)
    
    private let sleepActiveColor = Color(red: 88/255.0, green: 86/255.0, blue: 215/255.0)
    private let sleepTrackColor = Color(red: 212/255.0, green: 211/255.0, blue: 242/255.0)
    
    private let trainingActiveColor = Color(red: 1/255.0, green: 113/255.0, blue: 227/255.0)
    private let trainingTrackColor = Color(red: 194/255.0, green: 217/255.0, blue: 244/255.0)
    
    private let strokeWidth: CGFloat = 19
    private let outerDiameter: CGFloat = 216
    private let middleDiameter: CGFloat = 170
    private let innerDiameter: CGFloat = 124
    
    public var qualityProgress: Double = 220.0 / 360.0
    public var sleepProgress: Double = 260.0 / 360.0
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
            ringLayer(
                diameter: outerDiameter,
                trackColor: qualityTrackColor,
                activeColor: qualityActiveColor,
                progress: qualityProgress,
                rotationDegrees: -90
            )
            
            ringLayer(
                diameter: middleDiameter,
                trackColor: sleepTrackColor,
                activeColor: sleepActiveColor,
                progress: sleepProgress,
                rotationDegrees: 195
            )
            
            ringLayer(
                diameter: innerDiameter,
                trackColor: trainingTrackColor,
                activeColor: trainingActiveColor,
                progress: trainingProgress,
                rotationDegrees: 220
            )
        }
        .frame(width: outerDiameter + strokeWidth, height: outerDiameter + strokeWidth)
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func ringLayer(
        diameter: CGFloat,
        trackColor: Color,
        activeColor: Color,
        progress: Double,
        rotationDegrees: Double
    ) -> some View {
        let strokeW: CGFloat = appHighContrast ? (strokeWidth + 2) : strokeWidth
        
        ZStack {
            Circle()
                .stroke(appHighContrast ? trackColor.opacity(0.85) : trackColor, lineWidth: strokeW)
                .frame(width: diameter, height: diameter)
            
            if progress > 0.001 {
                Circle()
                    .trim(from: 0.0, to: min(max(progress, 0.0), 1.0))
                    .stroke(
                        activeColor,
                        style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(rotationDegrees))
                    .animation(appReduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8), value: progress)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
        SummaryRingsView()
    }
}
