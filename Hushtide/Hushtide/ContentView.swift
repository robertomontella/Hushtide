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
                .environment(\.appHighContrast, viewModel.isHighContrastEnabled)
                .environment(\.appReduceMotion, viewModel.isReduceMotionEnabled)
        }
        .transaction { transaction in
            if viewModel.isReduceMotionEnabled {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
        .environment(\.appHighContrast, viewModel.isHighContrastEnabled)
        .environment(\.appReduceMotion, viewModel.isReduceMotionEnabled)
        .task {
            viewModel.sleepModel.checkAndPerformDailyResetIfNeeded()
            await viewModel.startHealthSync()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.sleepModel.checkAndPerformDailyResetIfNeeded()
                
                if viewModel.isAppleHealthSynced && viewModel.isAppleHealthConnected {
                    Task { await viewModel.syncHealthData(requireAuthentication: false) }
                }
            }
        }
    }
}

private struct AppHighContrastKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct AppReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    public var appHighContrast: Bool {
        get { self[AppHighContrastKey.self] }
        set { self[AppHighContrastKey.self] = newValue }
    }
    
    public var appReduceMotion: Bool {
        get { self[AppReduceMotionKey.self] }
        set { self[AppReduceMotionKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}
