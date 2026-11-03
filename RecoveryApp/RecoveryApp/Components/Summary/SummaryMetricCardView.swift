//
//  SummaryMetricCardView.swift
//  RecoveryApp
//
//  Created by Antigravity on 30/10/2026.
//

import SwiftUI

/// An interactive metric card button used in the Summary view.
/// Shows a colored title, large metric value, and two-line secondary subtitle.
/// When tapped, activates its detailed daily chart below.
public struct SummaryMetricCardView: View {
    public let title: String
    public let titleColor: Color
    public let value: String
    public let subtitle: String
    public let isSelected: Bool
    public let action: (() -> Void)?
    
    public init(
        title: String,
        titleColor: Color,
        value: String,
        subtitle: String,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.titleColor = titleColor
        self.value = value
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            action?()
        } label: {
            VStack(spacing: 6) {
                // Colored section title matching the concentric ring
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(titleColor)
                
                // Primary highlighted metric value
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Contextual subtitle (e.g., average rating, goal progress)
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
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
                    .stroke(isSelected ? titleColor.opacity(0.65) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
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
