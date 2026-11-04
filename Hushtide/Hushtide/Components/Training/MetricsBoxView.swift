import SwiftUI

public struct MetricsBoxView: View {
    @Environment(\.appHighContrast) private var appHighContrast
    @Environment(\.colorScheme) private var colorScheme
    public let sleepDebtMetric: SecondaryMetric
    public let restedMetric: SecondaryMetric
    public let regularityMetric: SecondaryMetric
    
    public init(
        sleepDebtMetric: SecondaryMetric = SecondaryMetric(title: "Sleep Debt", value: "-15m"),
        restedMetric: SecondaryMetric = SecondaryMetric(title: "Quality", value: "88%"),
        regularityMetric: SecondaryMetric = SecondaryMetric(title: "Regularity", value: "On time")
    ) {
        self.sleepDebtMetric = sleepDebtMetric
        self.restedMetric = restedMetric
        self.regularityMetric = regularityMetric
    }
    
    public init(
        sleepMetric: SecondaryMetric,
        qualityMetric: SecondaryMetric,
        regularityMetric: SecondaryMetric
    ) {
        self.sleepDebtMetric = sleepMetric
        self.restedMetric = qualityMetric
        self.regularityMetric = regularityMetric
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            metricColumn(title: sleepDebtMetric.title, value: sleepDebtMetric.value)
            
            dividerView
            
            metricColumn(title: restedMetric.title, value: restedMetric.value)
            
            dividerView
            
            metricColumn(title: regularityMetric.title, value: regularityMetric.value)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            appHighContrast
                                ? (colorScheme == .dark ? Color.white : Color.black)
                                : Color(uiColor: .separator).opacity(0.3),
                            lineWidth: appHighContrast ? 2.0 : 0.8
                        )
                )
        )
    }
    
    @ViewBuilder
    private func metricColumn(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: appHighContrast ? .bold : .semibold))
                .foregroundColor(
                    appHighContrast
                        ? .primary
                        : (colorScheme == .dark ? Color(red: 0.88, green: 0.89, blue: 0.92) : Color(red: 0.22, green: 0.23, blue: 0.26))
                )
            
            Text(value)
                .font(.system(size: 16, weight: appHighContrast ? .black : .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dividerView: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.18))
            .frame(width: 1, height: 24)
    }
}

#Preview {
    MetricsBoxView(
        sleepDebtMetric: SecondaryMetric(title: "Sleep Debt", value: "-15m"),
        restedMetric: SecondaryMetric(title: "Quality", value: "88%"),
        regularityMetric: SecondaryMetric(title: "Regularity", value: "On time")
    )
    .padding()
}
