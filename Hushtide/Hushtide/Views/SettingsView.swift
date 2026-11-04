import SwiftUI

public enum AppSettingsKey {
    public static let isHapticsEnabled = "RecoveryApp_isHapticsEnabled"
    public static let isAudioCuesEnabled = "Hushtide_isAudioCuesEnabled"
    public static let simplifyCharts = "Hushtide_simplifyCharts"
    public static let isManualInputModeEnabled = "Hushtide_isManualInputModeEnabled"
}

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    public var viewModel: TrainingModel?
    
    @AppStorage(AppSettingsKey.isHapticsEnabled)
    private var isHapticsEnabled: Bool = true
    
    @AppStorage(AppSettingsKey.isAudioCuesEnabled)
    private var isAudioCuesEnabled: Bool = true
    
    @AppStorage(AppSettingsKey.simplifyCharts)
    private var simplifyCharts: Bool = false
    
    @AppStorage(AppSettingsKey.isManualInputModeEnabled)
    private var isManualInputModeEnabled: Bool = false
    
    public init(viewModel: TrainingModel? = nil) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Form {
            sensoryFeedbackSection
            dataVisualizationSection
            inputFallbackSection
            
            if let viewModel = viewModel {
                systemIntegrationSection(viewModel: viewModel)
            }
            
            aboutSection
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var sensoryFeedbackSection: some View {
        Section {
            Toggle(isOn: $isHapticsEnabled) {
                settingsRowLabel(
                    icon: "iphone.radiowaves.left.and.right",
                    iconColor: .pink,
                    title: "Haptic Feedback",
                    subtitle: "Tactile vibrations when interacting with buttons, targets, and metrics"
                )
            }
            .onChange(of: isHapticsEnabled) { _, newValue in
                HapticManager.isHapticsEnabled = newValue
                if newValue {
                    HapticManager.impact(.medium)
                }
            }
            .accessibilityLabel("Haptic Feedback")
            .accessibilityHint("Enables or disables tactile vibration responses inside the app.")
            
            Toggle(isOn: $isAudioCuesEnabled) {
                settingsRowLabel(
                    icon: "speaker.wave.2.fill",
                    iconColor: .teal,
                    title: "Audio Cues & Sounds",
                    subtitle: "Auditory guidance, countdown tones, and tracking alerts during sessions"
                )
            }
            .accessibilityLabel("Audio Cues and Sounds")
            .accessibilityHint("Plays auditory prompts and milestone tones during tracking sessions.")
        } header: {
            Text("Sensory Feedback")
        } footer: {
            Text("Adjust in-app tactile and auditory cues. Turning these off reduces stimulation for users with sensory hypersensitivity, hyperacusis, or motor tremors without disabling system sounds.")
                .font(.footnote)
        }
    }
    
    private var dataVisualizationSection: some View {
        Section {
            Toggle(isOn: $simplifyCharts) {
                settingsRowLabel(
                    icon: "chart.bar.xaxis",
                    iconColor: .orange,
                    title: "Simplify Charts",
                    subtitle: "Present data as high-legibility plain text lists and tables instead of complex vector charts"
                )
            }
            .accessibilityLabel("Simplify Charts")
            .accessibilityHint("Replaces multi-axis radar charts and complex graphics with plain text lists.")
        } header: {
            Text("Data Visualization")
        } footer: {
            Text("Substitutes circular gauges, bezier curves, and multi-variable radar charts with structured text and numerical lists. Recommended for users with cognitive fatigue, low vision, or screen reader navigation.")
                .font(.footnote)
        }
    }
    
    private var inputFallbackSection: some View {
        Section {
            Toggle(isOn: $isManualInputModeEnabled) {
                settingsRowLabel(
                    icon: "hand.point.up.left.and.text",
                    iconColor: .green,
                    title: "Manual Input Mode",
                    subtitle: "Bypass camera body/motion tracking and enter workout metrics manually"
                )
            }
            .accessibilityLabel("Manual Input Mode")
            .accessibilityHint("Allows manual form entry of workout metrics instead of real-time camera tracking.")
        } header: {
            Text("Input Fallback")
        } footer: {
            Text("Allows entering exercise duration, intensity, and sets directly through standard forms. Designed for athletes with motor difficulties, tremors, or positioning constraints who cannot utilize camera-based motion tracking.")
                .font(.footnote)
        }
    }
    
    // Renders the system and Apple Health integration section
    @ViewBuilder
    private func systemIntegrationSection(viewModel: TrainingModel) -> some View {
        Section {
            NavigationLink {
                PrivacySettingsView(viewModel: viewModel)
            } label: {
                settingsRowLabel(
                    icon: "lock.shield.fill",
                    iconColor: .blue,
                    title: "Privacy & GDPR Compliance",
                    subtitle: "Local-only processing, data controls, and export options"
                )
            }
            .accessibilityLabel("Privacy and GDPR Compliance")
            
            HStack(spacing: 12) {
                settingsIcon("heart.text.square.fill", color: .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.health.isAuthorized ? "Connected and authorized" : "Not authorized")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: viewModel.health.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(viewModel.health.isAuthorized ? .green : .orange)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Apple Health Status: \(viewModel.health.isAuthorized ? "Connected" : "Not authorized")")
        } header: {
            Text("System & Privacy")
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutDevelopersView()
            } label: {
                HStack(spacing: 12) {
                    Image("Untitled-iOS-Default-1024@1x")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("About Hushtide")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text("Francesco Micallo, Roberto Montella and team")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .accessibilityLabel("About Hushtide developers")
        } header: {
            Text("About")
        } footer: {
            VStack(alignment: .center, spacing: 4) {
                Text("Made with passion in Italy 🇮🇹")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("Hushtide v1.0 • Built with Apple Accessibility Standards")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
    
    // Configures a settings row with a leading icon, title, and descriptive subtitle
    @ViewBuilder
    private func settingsRowLabel(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon, color: iconColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        }
    }
    
    // Builds a rounded square icon container matching standard iOS settings style
    @ViewBuilder
    private func settingsIcon(_ name: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: name)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(.white)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: TrainingModel())
    }
}
