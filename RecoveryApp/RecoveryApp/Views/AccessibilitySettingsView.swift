import SwiftUI

public struct AccessibilitySettingsView: View {
    @Bindable public var viewModel: TrainingModel
    @Environment(\.colorScheme) private var colorScheme
    
    // Interactive test states for immediate live verification
    @State private var motionTestOffset: CGFloat = 0
    @State private var hapticTestFeedbackNotice: String? = nil
    
    public init(viewModel: TrainingModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                // MARK: - Hero Banner
                accessibilityHeroBanner
                
                // MARK: - Section: Interaction & Haptics
                interactionSection
                
                // MARK: - Section: Vision & Contrast
                visionSection
                
                // MARK: - Section: Screen Reader & VoiceOver
                screenReaderSection
                
                // MARK: - Compliance Footer
                complianceFooter
                
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Hero Banner
    private var accessibilityHeroBanner: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "accessibility")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 4) {
                Text("Inclusive Design for Everyone")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Tailor your visual, tactile, and motion experience")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("RecoveryApp is designed to ensure maximum legibility, seamless VoiceOver navigation, and optimal comfort for every athlete and user.")
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
    
    // MARK: - Interaction & Haptics Section
    private var interactionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INTERACTION & HAPTIC FEEDBACK")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Haptics Toggle
                Toggle(isOn: Binding(
                    get: { viewModel.isHapticsEnabled },
                    set: { newValue in
                        viewModel.isHapticsEnabled = newValue
                        HapticManager.isHapticsEnabled = newValue
                        if newValue {
                            HapticManager.impact(.medium)
                        }
                    }
                )) {
                    HStack(spacing: 14) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Haptic Feedback")
                                .font(.system(size: 15.5, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Tactile vibration when tapping buttons, goals, and metrics")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Test Haptics Button
                Button {
                    HapticManager.impact(.heavy)
                    hapticTestFeedbackNotice = viewModel.isHapticsEnabled
                        ? "✓ Haptic fired"
                        : "✕ Haptics disabled"
                } label: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("Test Haptic Vibration")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        if let notice = hapticTestFeedbackNotice {
                            Text(notice)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.isHapticsEnabled ? .green : .secondary)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.06))
                }
                .buttonStyle(.plain)
                
                Divider()
                
                // Reduce Motion Toggle
                Toggle(isOn: $viewModel.isReduceMotionEnabled) {
                    HStack(spacing: 14) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.indigo)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reduce Motion")
                                .font(.system(size: 15.5, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Replaces spring animations with instant transitions")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Live Motion Test Demo
                HStack {
                    Text("Motion Test:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                            .frame(width: 120, height: 28)
                        
                        Circle()
                            .fill(Color.indigo)
                            .frame(width: 24, height: 24)
                            .padding(.horizontal, 2)
                            .offset(x: motionTestOffset)
                    }
                    
                    Button {
                        if viewModel.isReduceMotionEnabled {
                            // Instant jump with no animation
                            motionTestOffset = (motionTestOffset == 0) ? 92 : 0
                        } else {
                            // Spring animation
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                motionTestOffset = (motionTestOffset == 0) ? 92 : 0
                            }
                        }
                    } label: {
                        Text("Animate")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.indigo)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.indigo.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.indigo.opacity(0.04))
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Vision & High Contrast Section
    private var visionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VISION & HIGH CONTRAST")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // High Contrast Toggle
                Toggle(isOn: $viewModel.isHighContrastEnabled) {
                    HStack(spacing: 14) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("High Contrast Mode")
                                .font(.system(size: 15.5, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Enforces bold borders and maximum contrast on charts")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Live High-Contrast Visual Demo Card
                VStack(spacing: 8) {
                    HStack {
                        Text("Live Contrast Preview")
                            .font(.system(size: 12, weight: viewModel.isHighContrastEnabled ? .bold : .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(viewModel.isHighContrastEnabled ? "HIGH CONTRAST ON" : "STANDARD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(viewModel.isHighContrastEnabled ? .orange : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(viewModel.isHighContrastEnabled ? Color.orange.opacity(0.18) : Color.secondary.opacity(0.1))
                            )
                    }
                    
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(viewModel.isHighContrastEnabled ? 0.6 : 0.2), lineWidth: viewModel.isHighContrastEnabled ? 5 : 3)
                                .frame(width: 36, height: 36)
                            
                            Circle()
                                .trim(from: 0, to: 0.88)
                                .stroke(Color.teal, style: StrokeStyle(lineWidth: viewModel.isHighContrastEnabled ? 5 : 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 36, height: 36)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Readiness: 88%")
                                .font(.system(size: 14, weight: viewModel.isHighContrastEnabled ? .black : .bold))
                                .foregroundColor(.primary)
                            Text("Sleep Debt: -15m • Regularity: On time")
                                .font(.system(size: 11.5, weight: viewModel.isHighContrastEnabled ? .semibold : .regular))
                                .foregroundColor(viewModel.isHighContrastEnabled ? .primary : .secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    viewModel.isHighContrastEnabled
                                        ? (colorScheme == .dark ? Color.white : Color.black)
                                        : Color.clear,
                                    lineWidth: viewModel.isHighContrastEnabled ? 2.0 : 0
                                )
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                Divider().padding(.leading, 58)
                
                // Dynamic Type info
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.teal)
                        .frame(width: 28, height: 28)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Type Integration")
                            .font(.system(size: 15.5, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("RecoveryApp automatically scales fonts to respect your system settings in iOS Settings > Display & Brightness > Text Size.")
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
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
    
    // MARK: - VoiceOver Section
    private var screenReaderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SCREEN READER (VOICEOVER)")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                    
                    Text("Rich Spoken Biometric Descriptions")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("All summary concentric rings (Quality, Sleep, Training), readiness scores, sleep debts, and recommended intensity levels feature complete VoiceOver accessibility labels and spoken values.")
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
    
    // MARK: - Compliance Footer
    private var complianceFooter: some View {
        VStack(spacing: 4) {
            Text("Conforms to European Accessibility Act (Directive EU 2019/882) & WCAG 2.1 AA")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Designed & Tested in Italy")
                .font(.system(size: 10.5, weight: .regular))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack {
        AccessibilitySettingsView(viewModel: TrainingModel())
    }
}
