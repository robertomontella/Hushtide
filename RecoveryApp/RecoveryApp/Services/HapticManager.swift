//
//  HapticManager.swift
//  RecoveryApp
//
//  Central manager for tactile haptic feedback.
//  Allows the user to enable or disable all haptics app-wide from Accessibility settings.
//

import UIKit

public final class HapticManager {
    /// Global flag observed by all haptic triggers
    public static var isHapticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "RecoveryApp_isHapticsEnabled")
        }
    }
    
    /// Initializes stored preferences and hooks UIKit feedback generators
    public static func initialize() {
        if UserDefaults.standard.object(forKey: "RecoveryApp_isHapticsEnabled") != nil {
            isHapticsEnabled = UserDefaults.standard.bool(forKey: "RecoveryApp_isHapticsEnabled")
        }
        enableSwizzling()
    }
    
    /// Explicit trigger for impact haptics
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Explicit trigger for notification haptics
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Safe Swizzling to enforce Haptics toggle globally
    private static var hasSwizzled = false
    
    private static func enableSwizzling() {
        guard !hasSwizzled else { return }
        hasSwizzled = true
        
        // 1. Swizzle UIImpactFeedbackGenerator.impactOccurred()
        let impactOriginal = #selector(UIImpactFeedbackGenerator.impactOccurred as (UIImpactFeedbackGenerator) -> () -> Void)
        let impactSwizzled = #selector(UIImpactFeedbackGenerator.app_impactOccurred)
        if let original = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactOriginal),
           let swizzled = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
        
        // 2. Swizzle UINotificationFeedbackGenerator.notificationOccurred(_:)
        let notifOriginal = #selector(UINotificationFeedbackGenerator.notificationOccurred(_:))
        let notifSwizzled = #selector(UINotificationFeedbackGenerator.app_notificationOccurred(_:))
        if let original = class_getInstanceMethod(UINotificationFeedbackGenerator.self, notifOriginal),
           let swizzled = class_getInstanceMethod(UINotificationFeedbackGenerator.self, notifSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
    }
}

// MARK: - Swizzled UIKit Extensions
extension UIImpactFeedbackGenerator {
    @objc func app_impactOccurred() {
        if HapticManager.isHapticsEnabled {
            // Calls original implementation after swizzle
            self.app_impactOccurred()
        }
    }
}

extension UINotificationFeedbackGenerator {
    @objc func app_notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        if HapticManager.isHapticsEnabled {
            // Calls original implementation after swizzle
            self.app_notificationOccurred(type)
        }
    }
}
