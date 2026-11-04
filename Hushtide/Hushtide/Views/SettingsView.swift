import SwiftUI

public enum AppSettingsKey {
    public static let isHapticsEnabled = "RecoveryApp_isHapticsEnabled"
}

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    public var viewModel: TrainingModel?
    
    @AppStorage(AppSettingsKey.isHapticsEnabled)
    private var isHapticsEnabled: Bool = true
    
    public init(viewModel: TrainingModel? = nil) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Form {
            sensoryFeedbackSection
            
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
        } header: {
            Text("Sensory Feedback")
        } footer: {
            Text("Adjust in-app tactile feedback. Turning this off disables vibration responses when interacting with buttons, checkmarks, and targets.")
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
