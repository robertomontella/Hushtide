//
//  MetricsBoxView.swift
//  WorkoutRecoveryApp
//
//  Created by Senior iOS Developer on 29/10/2026.
//

import SwiftUI

public struct MetricsBoxView: View {
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
    
    // Backwards-compatible initializer
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
        // MARK: - 3-Column Metrics Container
        HStack(spacing: 0) {
            // Column 1: Sleep Debt
            metricColumn(title: sleepDebtMetric.title, value: sleepDebtMetric.value)
            
            // Vertical Divider
            dividerView
            
            // Column 2: Rested
            metricColumn(title: restedMetric.title, value: restedMetric.value)
            
            // Vertical Divider
            dividerView
            
            // Column 3: Regularity
            metricColumn(title: regularityMetric.title, value: regularityMetric.value)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.8)
                )
        )
    }
    
    @ViewBuilder
    private func metricColumn(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
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
