//
//  BiometricAuthService.swift
//  RecoveryApp
//
//  Provides Face ID authentication with phone PIN fallback when syncing Apple Health data.
//

import Foundation
import LocalAuthentication

@MainActor
public enum BiometricAuthService {
    
    /// Requests Face ID authentication to sync Apple Health data.
    ///
    /// If Face ID fails to recognize the user, or if the user chooses the fallback,
    /// iOS automatically prompts for the device PIN / passcode.
    ///
    /// - Parameter reason: The localized explanation displayed in the authentication dialog.
    /// - Returns: `true` if authentication succeeded (via Face ID or phone PIN); `false` otherwise.
    public static func authenticateForHealthSync(
        reason: String = "Face ID is required to sync Apple Health data. If Face ID is not recognized, enter your phone PIN."
    ) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Enter PIN"
        
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            #if targetEnvironment(simulator)
            // On simulator environments where Face ID / passcode may not be enrolled in settings,
            // allow development testing while logging clearly.
            print("[BiometricAuthService] Simulator fallback: biometrics not enrolled.")
            return true
            #else
            print("[BiometricAuthService] deviceOwnerAuthentication cannot be evaluated: \(authError?.localizedDescription ?? "unknown error")")
            return false
            #endif
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch {
            print("[BiometricAuthService] Authentication failed or cancelled: \(error.localizedDescription)")
            return false
        }
    }
}
