//
//  SleepCheckmarksView.swift
//  RecoveryApp
//
//  Created by Antigravity on 30/10/2026.
//

import SwiftUI

public struct SleepCheckmarksView: View {
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
            // Section Title with Add Button Above
            HStack(alignment: .center) {
                Text(sectionTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.prepare()
                    generator.impactOccurred()
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
            
            // Checkmarks Container Card (Fixed-size Pill with ScrollView)
            VStack(alignment: .leading, spacing: 10) {
                // Scrollable Checkmarks list with fixed height boundary
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
                                    // Interactive Checkbox Button
                                    Button {
                                        onToggle(item.id)
                                    } label: {
                                        HStack(spacing: 14) {
                                            // Purple Rounded Square Checkbox
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                    .fill(item.isChecked ? accentColor : Color.clear)
                                                    .frame(width: 26, height: 26)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                            .stroke(item.isChecked ? accentColor : Color(uiColor: .systemGray4), lineWidth: 1.8)
                                                    )
                                                
                                                if item.isChecked {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .transition(.scale.combined(with: .opacity))
                                                }
                                            }
                                            
                                            // Checkmark Label
                                            Text(item.title)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(item.title), \(item.isChecked ? "completed" : "incomplete")")
                                    
                                    Spacer()
                                    
                                    // Edit Checkmark Button
                                    Button {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.prepare()
                                        generator.impactOccurred()
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
                
                // Explanatory Recommendation Note
                Text(recommendationNote)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 140) // Fixed size regardless of the number of checkmarks
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
