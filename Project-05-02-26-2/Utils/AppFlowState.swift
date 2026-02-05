//
//  ViewportTransition.swift
//  Hourly Rate Engineer
//

import Foundation

/// Determines the current visual presentation mode of the application
/// Each case represents a distinct rendering context
enum ViewportTransition: Hashable {
    
    /// Initial loading phase with branded animation
    case introSequence
    
    /// Standard calculator functionality
    case calculatorMode
    
    /// External content rendering with associated resource locator
    case externalRenderer(_ resourceLocator: String)
    
    /// Recovery state with diagnostic information
    case recoveryPrompt(_ diagnosticInfo: String)
    
    // MARK: - Convenience Accessors
    
    var isIntroPhase: Bool {
        if case .introSequence = self { return true }
        return false
    }
    
    var isCalculatorActive: Bool {
        if case .calculatorMode = self { return true }
        return false
    }
    
    var associatedResource: String? {
        guard case .externalRenderer(let locator) = self else { return nil }
        return locator
    }
    
    var diagnosticPayload: String? {
        guard case .recoveryPrompt(let info) = self else { return nil }
        return info
    }
}

// MARK: - Transition Factory

extension ViewportTransition {
    
    static func resolveFromResource(_ resource: String?) -> ViewportTransition {
        guard let res = resource, !res.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .calculatorMode
        }
        return .externalRenderer(res)
    }
    
    static func fromRecoverable(_ err: Error) -> ViewportTransition {
        .recoveryPrompt(err.localizedDescription)
    }
}
