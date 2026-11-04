import SwiftUI

public struct SleepCheckmarksView: View {
    @Environment(\.appHighContrast) private var appHighContrast
    @Environment(\.colorScheme) private var colorScheme
    public let sectionTitle: String
    public let recommendationNote: String
    public let checkmarks: [SleepCheckmarkItem]
    public let accentColor: Color
    public let onToggle: (UUID) -> Void
    public var onManageCheckmarks: (() -> Void)? = nil
    public var onEditCheckmark: ((SleepCheckmarkItem) -> Void)? = nil
    
    public init(
        sectionTitle: String = "Checkmarks",
        recommendationNote: String = "Based on your weekly workouts and daily routine, we recommend that you:",
        checkmarks: [SleepCheckmarkItem],
        accentColor: Color = Color(red: 0.33, green: 0.36, blue: 1.0),
        onToggle: @escaping (UUID) -> Void,
        onManageCheckmarks: (() -> Void)? = nil,
        onEditCheckmark: ((SleepCheckmarkItem) -> Void)? = nil
    ) {
        self.sectionTitle = sectionTitle
        self.recommendationNote = recommendationNote
        self.checkmarks = checkmarks
        self.accentColor = accentColor
        self.onToggle = onToggle
        self.onManageCheckmarks = onManageCheckmarks
        self.onEditCheckmark = onEditCheckmark
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(sectionTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    HapticManager.impact(.light)
                    onManageCheckmarks?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add checkmark")
            }
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        if checkmarks.isEmpty {
                            Text("No checkmarks. Tap + Add to create one.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(checkmarks) { item in
                                HStack(spacing: 14) {
                                    Button {
                                        onToggle(item.id)
                                    } label: {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                    .fill(item.isChecked ? accentColor : Color.clear)
                                                    .frame(width: 26, height: 26)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                            .stroke(item.isChecked ? accentColor : (appHighContrast ? (colorScheme == .dark ? Color.white : Color.black) : Color(uiColor: .systemGray4)), lineWidth: appHighContrast ? 2.5 : 1.8)
                                                    )
                                                
                                                if item.isChecked {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .transition(.scale.combined(with: .opacity))
                                                }
                                            }
                                            
                                            Text(item.title)
                                                .font(.system(size: 15, weight: appHighContrast ? .black : .bold))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(item.title), \(item.isChecked ? "completed" : "incomplete")")
                                    
                                    Spacer()
                                    
                                    Button {
                                        HapticManager.impact(.light)
                                        onEditCheckmark?(item)
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                                            .padding(6)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Edit checkmark \(item.title)")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: .infinity)
                
                Text(recommendationNote)
                    .font(.system(size: 12, weight: appHighContrast ? .semibold : .regular))
                    .foregroundColor(appHighContrast ? .primary : .secondary)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                appHighContrast
                                    ? (colorScheme == .dark ? Color.white : Color.black)
                                    : Color(uiColor: .separator).opacity(0.25),
                                lineWidth: appHighContrast ? 2.0 : 0.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
            )
        }
    }
}

#Preview {
    SleepCheckmarksView(
        checkmarks: [
            SleepCheckmarkItem(title: "Go to bed at 22:00", isChecked: true),
            SleepCheckmarkItem(title: "Do not drink caffeine after 4:00", isChecked: true)
        ],
        onToggle: { _ in },
        onManageCheckmarks: {}
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
