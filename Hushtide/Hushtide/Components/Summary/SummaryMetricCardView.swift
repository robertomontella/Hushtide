import SwiftUI

public struct SummaryMetricCardView: View {
    @Environment(\.appHighContrast) private var appHighContrast
    @Environment(\.appReduceMotion) private var appReduceMotion
    @Environment(\.colorScheme) private var colorScheme
    public let title: String
    public let titleColor: Color
    public let value: String
    public let subtitle: String
    public let isSelected: Bool
    public var onTap: (() -> Void)? = nil
    public var onDoubleTap: (() -> Void)? = nil
    
    public init(
        title: String,
        titleColor: Color,
        value: String,
        subtitle: String,
        isSelected: Bool = false,
        action: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.titleColor = titleColor
        self.value = value
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.onTap = onTap ?? action
        self.onDoubleTap = onDoubleTap
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(titleColor)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 11, weight: appHighContrast ? .semibold : .regular))
                .foregroundColor(appHighContrast ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 10 : 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isSelected
                        ? titleColor
                        : (appHighContrast ? (colorScheme == .dark ? Color.white : Color.black) : Color.clear),
                    lineWidth: appHighContrast ? 2.5 : (isSelected ? 1.5 : 0)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture(count: 2) {
            HapticManager.impact(.medium)
            onDoubleTap?()
        }
        .onTapGesture(count: 1) {
            HapticManager.impact(.light)
            onTap?()
        }
        .scaleEffect(isSelected && !appReduceMotion ? 1.02 : 1.0)
        .animation(appReduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
    }
}

#Preview {
    HStack(spacing: 12) {
        SummaryMetricCardView(
            title: "Quality",
            titleColor: Color(red: 3/255.0, green: 199/255.0, blue: 190/255.0),
            value: "88%",
            subtitle: "average\nrating",
            isSelected: false
        )
        SummaryMetricCardView(
            title: "Sleep",
            titleColor: Color(red: 88/255.0, green: 86/255.0, blue: 215/255.0),
            value: "4/7",
            subtitle: "average\n7h 45m",
            isSelected: true
        )
        SummaryMetricCardView(
            title: "Training",
            titleColor: Color(red: 1/255.0, green: 113/255.0, blue: 227/255.0),
            value: "220m",
            subtitle: "of 150min\nper week",
            isSelected: false
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
