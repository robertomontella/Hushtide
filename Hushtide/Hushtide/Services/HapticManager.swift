//
//  HapticManager.swift
//  RecoveryApp
//
//  Central manager for tactile haptic feedback and accessibility motion preferences.
//  Allows the user to enable or disable all haptics and reduce motion app-wide.
//

import UIKit
import SwiftUI

public final class HapticManager {
    public static let hapticsKey = "RecoveryApp_isHapticsEnabled"
    public static let reduceMotionKey = "RecoveryApp_isReduceMotionEnabled"
    
    /// Global flag observed by all haptic triggers
    public static var isHapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hapticsKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: hapticsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hapticsKey)
        }
    }
    
    /// Global flag observed by motion and animation systems
    public static var isReduceMotionEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: reduceMotionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reduceMotionKey)
        }
    }
    
    /// Initializes stored preferences and hooks UIKit feedback generators
    public static func initialize() {
        _ = isHapticsEnabled
        _ = isReduceMotionEnabled
        enableSwizzling()
    }
    
    /// Explicit trigger for impact haptics (guarded by isHapticsEnabled)
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Explicit trigger for impact haptics with intensity (guarded by isHapticsEnabled)
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, intensity: CGFloat) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
    
    /// Explicit trigger for notification haptics (guarded by isHapticsEnabled)
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Explicit trigger for selection haptics (guarded by isHapticsEnabled)
    public static func selection() {
        guard isHapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Safe Swizzling to enforce Haptics toggle globally
    private static var hasSwizzled = false
    
    private static func enableSwizzling() {
        guard !hasSwizzled else { return }
        hasSwizzled = true
        
        // 1. Swizzle UIImpactFeedbackGenerator.impactOccurred()
        let impactOriginal = #selector(UIImpactFeedbackGenerator.impactOccurred as (UIImpactFeedbackGenerator) -> () -> Void)
        let impactSwizzled = #selector(UIImpactFeedbackGenerator.app_impactOccurred as (UIImpactFeedbackGenerator) -> () -> Void)
        if let original = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactOriginal),
           let swizzled = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
        
        // 2. Swizzle UIImpactFeedbackGenerator.impactOccurred(intensity:)
        let impactIntensityOriginal = #selector(UIImpactFeedbackGenerator.impactOccurred(intensity:))
        let impactIntensitySwizzled = #selector(UIImpactFeedbackGenerator.app_impactOccurred(intensity:))
        if let original = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactIntensityOriginal),
           let swizzled = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactIntensitySwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
        
        // 3. Swizzle UINotificationFeedbackGenerator.notificationOccurred(_:)
        let notifOriginal = #selector(UINotificationFeedbackGenerator.notificationOccurred(_:))
        let notifSwizzled = #selector(UINotificationFeedbackGenerator.app_notificationOccurred(_:))
        if let original = class_getInstanceMethod(UINotificationFeedbackGenerator.self, notifOriginal),
           let swizzled = class_getInstanceMethod(UINotificationFeedbackGenerator.self, notifSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
        
        // 4. Swizzle UISelectionFeedbackGenerator.selectionChanged()
        let selectOriginal = #selector(UISelectionFeedbackGenerator.selectionChanged as (UISelectionFeedbackGenerator) -> () -> Void)
        let selectSwizzled = #selector(UISelectionFeedbackGenerator.app_selectionChanged)
        if let original = class_getInstanceMethod(UISelectionFeedbackGenerator.self, selectOriginal),
           let swizzled = class_getInstanceMethod(UISelectionFeedbackGenerator.self, selectSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
    }
}

// MARK: - Swizzled UIKit Extensions
extension UIImpactFeedbackGenerator {
    @objc dynamic func app_impactOccurred() {
        if HapticManager.isHapticsEnabled {
            self.app_impactOccurred()
        }
    }
    
    @objc dynamic func app_impactOccurred(intensity: CGFloat) {
        if HapticManager.isHapticsEnabled {
            self.app_impactOccurred(intensity: intensity)
        }
    }
}

extension UINotificationFeedbackGenerator {
    @objc dynamic func app_notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        if HapticManager.isHapticsEnabled {
            self.app_notificationOccurred(type)
        }
    }
}

extension UISelectionFeedbackGenerator {
    @objc dynamic func app_selectionChanged() {
        if HapticManager.isHapticsEnabled {
            self.app_selectionChanged()
        }
    }
}

// MARK: - Motion-Aware Animation Helper
/// Executes an animation block unless Reduce Motion is enabled (app setting or system).
public func withAppAnimation<Result>(
    _ animation: Animation? = .spring(response: 0.35, dampingFraction: 0.8),
    _ body: () throws -> Result
) rethrows -> Result {
    if HapticManager.isReduceMotionEnabled {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return try withTransaction(transaction, body)
    } else {
        return try withAnimation(animation, body)
    }
}

// MARK: - Sensory Feedback View Modifier Extension
extension View {
    @ViewBuilder
    public func appSensoryFeedback<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View {
        if HapticManager.isHapticsEnabled {
            self.sensoryFeedback(feedback, trigger: trigger)
        } else {
            self
        }
    }
}
