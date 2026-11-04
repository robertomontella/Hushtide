import SwiftUI

public struct ProfileRowView: View {
    @Environment(\.appHighContrast) private var appHighContrast
    public let iconName: String
    public let iconColor: Color
    public let title: String
    public let value: String
    public let showDivider: Bool
    public let onTap: (() -> Void)?
    
    public init(
        iconName: String,
        iconColor: Color = .blue,
        title: String,
        value: String,
        showDivider: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.showDivider = showDivider
        self.onTap = onTap
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Button {
                HapticManager.impact(.light)
                onTap?()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 28, height: 28, alignment: .center)
                    
                    Text(title)
                        .font(.system(size: 16, weight: appHighContrast ? .bold : .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.system(size: 15, weight: appHighContrast ? .semibold : .regular))
                        .foregroundColor(appHighContrast ? .primary : .secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if showDivider {
                Divider()
                    .padding(.leading, 58)
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ProfileRowView(iconName: "figure.run", title: "Sport Type", value: "Running", showDivider: true, onTap: {})
        ProfileRowView(iconName: "chart.bar.fill", title: "Training Level", value: "Advanced", showDivider: true, onTap: {})
        ProfileRowView(iconName: "calendar", title: "Weekly Frequency", value: "days", showDivider: false, onTap: {})
    }
    .background(Color.white)
    .cornerRadius(18)
    .padding()
}
