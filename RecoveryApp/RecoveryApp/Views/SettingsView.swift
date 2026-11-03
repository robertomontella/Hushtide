//
//  SettingsView.swift
//  RecoveryApp
//
//  Main Settings view: Includes sections for Privacy & GDPR,
//  Accessibility, and About the Developers.
//

import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable public var viewModel: TrainingModel
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Section: PRIVACY & DATA SECURITY
                privacySection
                
                // MARK: - Section: ACCESSIBILITY
                accessibilitySection
                
                // MARK: - Section: ABOUT THE DEVELOPERS
                aboutSection
                
                // MARK: - Section: APPLE HEALTH SYNCHRONIZATION
                healthKitSection
                
                // MARK: - Footer (Made with passion in Italy)
                madeInItalyFooter
                
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRIVACY & DATA SECURITY")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                NavigationLink {
                    PrivacySettingsView(viewModel: viewModel)
                } label: {
                    settingsRowLabel(
                        icon: "lock.shield.fill",
                        color: .blue,
                        title: "Privacy & GDPR Compliance",
                        subtitle: "Compliant with European and Italian regulations"
                    )
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Accessibility Section
    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACCESSIBILITY")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                NavigationLink {
                    AccessibilitySettingsView(viewModel: viewModel)
                } label: {
                    settingsRowLabel(
                        icon: "accessibility",
                        color: .purple,
                        title: "Accessibility Options",
                        subtitle: "Haptic feedback, animations, and high contrast"
                    )
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - About Developers Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ABOUT")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                NavigationLink {
                    AboutDevelopersView()
                } label: {
                    HStack(spacing: 12) {
                        Image("Untitled-iOS-Default-1024@1x")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("About Us • Hushtide")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Francesco Micallo, Roberto Montella and team")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - HealthKit Status
    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYNCHRONIZATION STATUS")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(.system(size: 15.5, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(viewModel.health.isAuthorized ? "Active and authorized" : "Not authorized")
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: viewModel.health.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.health.isAuthorized ? .green : .orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Made in Italy Footer
    private var madeInItalyFooter: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("🇮🇹")
                    .font(.system(size: 14))
                Text("Made with passion in Italy")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Text("RecoveryApp v1.0 • All calculations performed locally on-device")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func settingsRowLabel(
        icon: String,
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15.5, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: TrainingModel())
    }
}
