import SwiftUI

public struct ReadinessArcShape: Shape {
    public var startAngle: Angle = .degrees(150)
    public var endAngle: Angle = .degrees(30)
    public var strokeWidth: CGFloat = 13.5
    
    public init(startAngle: Angle = .degrees(150), endAngle: Angle = .degrees(30), strokeWidth: CGFloat = 13.5) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.strokeWidth = strokeWidth
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let halfStroke = strokeWidth / 2.0
        let effectiveWidth = rect.width - strokeWidth
        let radius = effectiveWidth / 2.0
        let center = CGPoint(x: rect.midX, y: rect.minY + halfStroke + radius)
        
        // Circular arc starting at 150° (down-left), sweeping over the top (270°), ending at 30° (down-right)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

public struct ReadinessRingView: View {
    @Environment(\.appHighContrast) private var appHighContrast
    @Environment(\.appReduceMotion) private var appReduceMotion
    public let score: Double
    public let dynamicColor: Color
    public let readinessLabel: String
    
    public init(score: Double, dynamicColor: Color, readinessLabel: String = "READINESS") {
        self.score = score
        self.dynamicColor = dynamicColor
        self.readinessLabel = readinessLabel
    }
    
    private var progress: Double {
        max(0.0, min(1.0, score / 100.0))
    }
    
    public var body: some View {
        let strokeW: CGFloat = appHighContrast ? 18.0 : 13.5
        
        return ZStack {
            // Background Inactive Track (Full 240° Arc from 150° to 30°)
            ReadinessArcShape(strokeWidth: strokeW)
                .stroke(
                    appHighContrast ? Color(uiColor: .systemGray3) : Color(uiColor: .systemGray5),
                    style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                )
            
            // Active Dynamic Track (Animated with spring, only drawn when score > 0)
            if progress > 0.001 {
                ReadinessArcShape(strokeWidth: strokeW)
                    .trim(from: 0.0, to: CGFloat(progress))
                    .stroke(
                        dynamicColor,
                        style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                    )
                    .animation(appReduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8), value: score)
                    .animation(appReduceMotion ? nil : .easeInOut(duration: 0.25), value: dynamicColor)
            }
                
            
            // Numerical Score and READINESS Label nested in the arch
                
            VStack(spacing: 0) {
                
                Text("\(Int(round(score)))")
                    .font(.system(size: 46, weight: appHighContrast ? .black : .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    
                
                Text(readinessLabel)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.0)
                    .foregroundColor(.secondary)
            }
            .offset(y: 20)
        }
        .frame(width: 204, height: 144)
        .padding(.top, 6)
    }
}

#Preview {
    ReadinessRingView(score: 93, dynamicColor: .green)
        .padding()
}
