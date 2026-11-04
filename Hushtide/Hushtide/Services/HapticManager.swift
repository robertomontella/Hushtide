import UIKit
import SwiftUI

public final class HapticManager {
    public static let hapticsKey = "RecoveryApp_isHapticsEnabled"
    public static let reduceMotionKey = "RecoveryApp_isReduceMotionEnabled"
    
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
    
    public static var isReduceMotionEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: reduceMotionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reduceMotionKey)
        }
    }
    
    // Initializes stored preferences and enables feedback generator swizzling
    public static func initialize() {
        _ = isHapticsEnabled
        _ = isReduceMotionEnabled
        enableSwizzling()
    }
    
    // Triggers impact haptic feedback with the specified style
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Triggers impact haptic feedback with custom intensity
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, intensity: CGFloat) {
        guard isHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
    
    // Triggers notification haptic feedback of the given type
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // Triggers selection change haptic feedback
    public static func selection() {
        guard isHapticsEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    private static var hasSwizzled = false
    
    // Swizzles UIKit feedback generator methods to enforce the global haptics toggle
    private static func enableSwizzling() {
        guard !hasSwizzled else { return }
        hasSwizzled = true
        
        let impactOriginal = #selector(UIImpactFeedbackGenerator.impactOccurred as (UIImpactFeedbackGenerator) -> () -> Void)
        let impactSwizzled = #selector(UIImpactFeedbackGenerator.app_impactOccurred as (UIImpactFeedbackGenerator) -> () -> Void)
        if let original = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactOriginal),
           let swizzled = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
        
        let impactIntensityOriginal = #selector(UIImpactFeedbackGenerator.impactOccurred(intensity:))
        let impactIntensitySwizzled = #selector(UIImpactFeedbackGenerator.app_impactOccurred(intensity:))
        if let original = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactIntensityOriginal),
           let swizzled = class_getInstanceMethod(UIImpactFeedbackGenerator.self, impactIntensitySwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
        
        let notifOriginal = #selector(UINotificationFeedbackGenerator.notificationOccurred(_:))
        let notifSwizzled = #selector(UINotificationFeedbackGenerator.app_notificationOccurred(_:))
        if let original = class_getInstanceMethod(UINotificationFeedbackGenerator.self, notifOriginal),
           let swizzled = class_getInstanceMethod(UINotificationFeedbackGenerator.self, notifSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
        
        let selectOriginal = #selector(UISelectionFeedbackGenerator.selectionChanged as (UISelectionFeedbackGenerator) -> () -> Void)
        let selectSwizzled = #selector(UISelectionFeedbackGenerator.app_selectionChanged)
        if let original = class_getInstanceMethod(UISelectionFeedbackGenerator.self, selectOriginal),
           let swizzled = class_getInstanceMethod(UISelectionFeedbackGenerator.self, selectSwizzled) {
            method_exchangeImplementations(original, swizzled)
        }
    }
}

extension UIImpactFeedbackGenerator {
    // Intercepts impact feedback and suppresses it when haptics are disabled
    @objc dynamic func app_impactOccurred() {
        if HapticManager.isHapticsEnabled {
            self.app_impactOccurred()
        }
    }
    
    // Intercepts impact feedback with intensity and suppresses it when disabled
    @objc dynamic func app_impactOccurred(intensity: CGFloat) {
        if HapticManager.isHapticsEnabled {
            self.app_impactOccurred(intensity: intensity)
        }
    }
}

extension UINotificationFeedbackGenerator {
    // Intercepts notification feedback and suppresses it when disabled
    @objc dynamic func app_notificationOccurred(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        if HapticManager.isHapticsEnabled {
            self.app_notificationOccurred(type)
        }
    }
}

extension UISelectionFeedbackGenerator {
    // Intercepts selection change feedback and suppresses it when disabled
    @objc dynamic func app_selectionChanged() {
        if HapticManager.isHapticsEnabled {
            self.app_selectionChanged()
        }
    }
}

// Executes animation block respecting app and system reduce motion preferences
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

extension View {
    // Applies SwiftUI sensory feedback modifier guarded by the haptics preference
    @ViewBuilder
    public func appSensoryFeedback<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View {
        if HapticManager.isHapticsEnabled {
            self.sensoryFeedback(feedback, trigger: trigger)
        } else {
            self
        }
    }
}
