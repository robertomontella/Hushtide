//
//  ContentView.swift
//  RecoveryApp
//
//  Created by AFP FED 019 on 28/10/2026.
//

import SwiftUI

public struct ContentView: View {
    @State private var viewModel = TrainingModel()
    @Environment(\.scenePhase) private var scenePhase
    
    public init() {
        HapticManager.initialize()
    }
    
    public var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            SummaryView(viewModel: viewModel)
                .tabItem {
                    Label(AppTab.summary.title, systemImage: AppTab.summary.iconName)
                }
                .tag(AppTab.summary)
            
            SleepView(viewModel: viewModel)
                .tabItem {
                    Label(AppTab.sleep.title, systemImage: AppTab.sleep.iconName)
                }
                .tag(AppTab.sleep)
            
            TrainingView(viewModel: viewModel)
                .tabItem {
                    Label(AppTab.training.title, systemImage: AppTab.training.iconName)
                }
                .tag(AppTab.training)
        }
        .tint(.blue)
        .fullScreenCover(isPresented: $viewModel.isProfilePresented) {
            ProfileView(viewModel: viewModel)
        }
        // MARK: - Global Accessibility Enforcers
        // 1. Reduce Motion: Disables spring animations app-wide when enabled
        .transaction { transaction in
            if viewModel.isReduceMotionEnabled {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        // 2. High Contrast Environment Key
        .environment(\.appHighContrast, viewModel.isHighContrastEnabled)
        // MARK: - Apple Health Sync
        .task {
            await viewModel.startHealthSync()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // If user has actively authenticated and connected Apple Health, refresh data in background
                if viewModel.isAppleHealthSynced && viewModel.isAppleHealthConnected {
                    Task { await viewModel.syncHealthData(requireAuthentication: false) }
                }
            }
        }
    }
}

// MARK: - High Contrast Environment Support
private struct AppHighContrastKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    public var appHighContrast: Bool {
        get { self[AppHighContrastKey.self] }
        set { self[AppHighContrastKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}
