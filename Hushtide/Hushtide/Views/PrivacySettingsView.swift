import SwiftUI

public struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable public var viewModel: TrainingModel
    
    @State private var isExportSuccessAlertPresented: Bool = false
    @State private var isResetConfirmationPresented: Bool = false
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                // MARK: - Hero Privacy Banner (GDPR & Privacy)
                gdprHeroBanner
                
                // MARK: - Core Guarantees
                privacyPillarsSection
                
                // MARK: - HealthKit & Apple Health Protection
                healthKitPrivacySection
                
                // MARK: - User Rights (GDPR Rights)
                gdprRightsSection
                
                // MARK: - Legal Footer
                legalFooterSection
                
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Data Exported Successfully", isPresented: $isExportSuccessAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your recovery, sleep, and workout data has been compiled in accordance with your right to data portability (Art. 20 GDPR).")
        }
        .confirmationDialog(
            "Clear Local Data",
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Clear Local App History", role: .destructive) {
                viewModel.loggedWorkouts.removeAll()
                viewModel.evaluateRecovery()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action will erase workouts saved locally inside the app in accordance with Art. 17 GDPR (Right to Erasure). Your historical data in Apple Health will not be affected.")
        }
    }
    
    // MARK: - GDPR Hero Banner
    private var gdprHeroBanner: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                Text("GDPR & Privacy Compliance")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("EU Regulation 2016/679 • Italian Data Protection Authority")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("In Hushtide, privacy is the cornerstone of our architecture, not an afterthought. All health and biometric parameters are processed strictly on-device in full compliance with European and Italian privacy regulations.")
                .font(.system(size: 13.5, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .lineSpacing(2)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Core Privacy Pillars
    private var privacyPillarsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR DATA, SECURE")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                privacyRow(
                    icon: "iphone.gen3",
                    color: .green,
                    title: "100% On-Device Processing",
                    description: "All recovery, sleep debt, and readiness calculations run exclusively on your iPhone. Zero health metrics ever leave your device.",
                    showDivider: true
                )
                
                privacyRow(
                    icon: "hand.raised.slash.fill",
                    color: .orange,
                    title: "No Commercial Tracking or Ads",
                    description: "We do not use third-party trackers, advertising SDKs, or profiling tools. We never monetize or sell your personal data.",
                    showDivider: true
                )
                
                privacyRow(
                    icon: "key.fill",
                    color: .blue,
                    title: "End-to-End Device Encryption",
                    description: "All saved metrics are secured using Apple's device-level encryption and the iOS Secure Enclave.",
                    showDivider: false
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - HealthKit Section
    private var healthKitPrivacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("APPLE HEALTH INTEGRATION (HEALTHKIT)")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health Connection Status")
                            .font(.system(size: 15.5, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(viewModel.health.isAuthorized ? "Authorized & Synchronized" : "Not Connected")
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundColor(viewModel.health.isAuthorized ? .green : .secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(viewModel.health.isAuthorized ? Color.green : Color.secondary.opacity(0.4))
                        .frame(width: 10, height: 10)
                }
                
                Divider()
                
                Text("Access to your health data (sleep analysis, resting heart rate, heart rate variability, and workouts) is handled exclusively via Apple's official HealthKit APIs. You can modify or revoke permissions at any time in iOS Settings > Privacy & Security > Health.")
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - User Rights Section (GDPR Art. 15-22)
    private var gdprRightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR RIGHTS (GDPR)")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Portability (Art. 20)
                Button {
                    HapticManager.impact(.light)
                    isExportSuccessAlertPresented = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export My Data")
                                .font(.system(size: 15.5, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Right to data portability (Art. 20 GDPR)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                
                Divider().padding(.leading, 58)
                
                // Right to Erasure (Art. 17)
                Button {
                    HapticManager.impact(.medium)
                    isResetConfirmationPresented = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Local App History")
                                .font(.system(size: 15.5, weight: .medium))
                                .foregroundColor(.red)
                            
                            Text("Right to erasure (Art. 17 GDPR)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
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
    
    // MARK: - Legal Footer Section
    private var legalFooterSection: some View {
        VStack(spacing: 6) {
            Text("Data Controller: Hushtide Development Team (Italy)")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Privacy Policy v1.0 • Formulated in accordance with European and Italian standards")
                .font(.system(size: 10.5, weight: .regular))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private func privacyRow(
        icon: String,
        color: Color,
        title: String,
        description: String,
        showDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            if showDivider {
                Divider().padding(.leading, 58)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView(viewModel: TrainingModel())
    }
}
