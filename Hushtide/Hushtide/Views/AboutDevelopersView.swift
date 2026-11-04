import SwiftUI

public struct AboutDevelopersView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let developers: [DeveloperProfile] = [
        DeveloperProfile(
            name: "Francesco Micallo",
            role: "IOS Developer",
            initials: "FM",
            accentColor: Color.blue
        ),
        DeveloperProfile(
            name: "Roberto Montella",
            role: "IOS Developer ",
            initials: "RM",
            accentColor: Color.indigo
        ),
        DeveloperProfile(
            name: "Gianmarco Ravo",
            role: "UI/UX Designer",
            initials: "GR",
            accentColor: Color.teal
        ),
        DeveloperProfile(
            name: "Francesco Langella",
            role: "iOS Developer",
            initials: "FL",
            accentColor: Color.purple
        ),
        DeveloperProfile(
            name: "Daniele Mammola",
            role: "iOS Developer",
            initials: "DM",
            accentColor: Color.orange
        ),
        DeveloperProfile(
            name: "Giuseppe Teodorici",
            role: "UI/UX Designer",
            initials: "GT",
            accentColor: Color.green
        )
    ]
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                appHeroSection
                developersSection
                heritageSection
                buildInfoSection
                
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("About Us")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var appHeroSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Text("🇮🇹")
                    .font(.system(size: 16))
                
                Text("DEVELOPED IN ITALY")
                    .font(.system(size: 11.5, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
                    )
            )
            
            Image("Untitled-iOS-Default-1024@1x")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
                )
            
            VStack(spacing: 4) {
                Text("Hushtide")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Version 1.0 (Build 1)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text("Designed for athletes and fitness enthusiasts seeking to master the balance between restorative sleep, accumulated sleep debt, and training load.")
                .font(.system(size: 13.5, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .lineSpacing(2)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
    
    private var developersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("THE DEVELOPMENT TEAM")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(developers.count) Developers")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(developers.enumerated()), id: \.element.id) { index, dev in
                    developerRow(developer: dev)
                    
                    if index < developers.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    @ViewBuilder
    private func developerRow(developer: DeveloperProfile) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(developer.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(developer.initials)
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .foregroundColor(developer.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(developer.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(developer.role)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var heritageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MISSION & ROOTS")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("Italian Digital Excellence")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("Hushtide was born in Italy through the union of iOS software engineering, human-centered design, and sports science. Our mission is to translate complex biometric data from Apple Health into actionable, immediate, and privacy-first daily recovery insights.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(2.5)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private var buildInfoSection: some View {
        VStack(spacing: 6) {
            Text("Crafted with Swift and SwiftUI in Italy 🇮🇹")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("© 2026 Hushtide Team. All rights reserved.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

private struct DeveloperProfile: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let initials: String
    let accentColor: Color
}

#Preview {
    NavigationStack {
        AboutDevelopersView()
    }
}
