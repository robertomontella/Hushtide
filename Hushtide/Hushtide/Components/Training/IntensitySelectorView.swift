import SwiftUI

public struct IntensitySelectorView: View {
    public let recommendedIntensity: IntensityLevel
    public let dynamicColor: Color
    
    public init(
        recommendedIntensity: IntensityLevel,
        dynamicColor: Color
    ) {
        self.recommendedIntensity = recommendedIntensity
        self.dynamicColor = dynamicColor
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            ForEach(IntensityLevel.allCases) { level in
                let isRecommended = (recommendedIntensity == level)
                
                VStack(spacing: 7) {
                    Image(systemName: level.iconName)
                        .font(.system(size: 23, weight: isRecommended ? .bold : .regular))
                        .foregroundColor(isRecommended ? dynamicColor : .primary)
                        .scaleEffect(isRecommended ? 1.08 : 1.0)
                    
                    Text(level.rawValue)
                        .font(.system(size: 12, weight: isRecommended ? .bold : .medium))
                        .foregroundColor(isRecommended ? dynamicColor : .primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(
                            color: isRecommended ? dynamicColor.opacity(0.18) : Color.black.opacity(0.04),
                            radius: isRecommended ? 8 : 4,
                            x: 0,
                            y: 2
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    isRecommended ? dynamicColor.opacity(0.8) : Color.clear,
                                    lineWidth: 1.8
                                )
                        )
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isRecommended)
                .animation(.easeInOut(duration: 0.25), value: dynamicColor)
            }
        }
    }
}

#Preview {
    IntensitySelectorView(
        recommendedIntensity: .hard,
        dynamicColor: .green
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
