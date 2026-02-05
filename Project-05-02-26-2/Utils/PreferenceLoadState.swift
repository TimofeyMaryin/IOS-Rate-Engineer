//
//  ConfigurationResult.swift
//  Hourly Rate Engineer
//

import Foundation

/// Represents the outcome of a configuration retrieval operation
/// Supports comprehensive error handling and state tracking
enum ConfigurationResult {
    
    /// Operation completed successfully
    case completed
    
    /// Operation is currently in progress
    case inProgress
    
    /// Operation was rate-limited, cached data may be available
    case rateLimited
    
    /// Operation encountered an error
    case failed(_ underlyingError: Error)
    
    // MARK: - State Queries
    
    /// Indicates whether the operation was successful
    var isSuccessful: Bool {
        if case .completed = self { return true }
        return false
    }
    
    /// Indicates whether the operation is still running
    var isPending: Bool {
        if case .inProgress = self { return true }
        return false
    }
    
    /// Indicates whether rate limiting was encountered
    var wasThrottled: Bool {
        if case .rateLimited = self { return true }
        return false
    }
    
    /// Returns the associated error, if any
    var associatedError: Error? {
        guard case .failed(let err) = self else { return nil }
        return err
    }
    
    /// Localized description of the current state
    var stateDescription: String {
        switch self {
        case .completed:
            return "Configuration loaded successfully"
        case .inProgress:
            return "Loading configuration..."
        case .rateLimited:
            return "Using cached configuration"
        case .failed(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Equatable Conformance

extension ConfigurationResult: Equatable {
    
    static func == (lhs: ConfigurationResult, rhs: ConfigurationResult) -> Bool {
        switch (lhs, rhs) {
        case (.completed, .completed),
             (.inProgress, .inProgress),
             (.rateLimited, .rateLimited):
            return true
            
        case (.failed(let lhsError), .failed(let rhsError)):
            let lhsNSError = lhsError as NSError
            let rhsNSError = rhsError as NSError
            return lhsNSError.domain == rhsNSError.domain && lhsNSError.code == rhsNSError.code
            
        default:
            return false
        }
    }
}

// MARK: - Factory Methods

extension ConfigurationResult {
    
    /// Creates a failed result from an error message
    static func fromMessage(_ message: String, code: Int = -1) -> ConfigurationResult {
        let error = NSError(
            domain: "com.app.configuration.result",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        return .failed(error)
    }
    
    /// Converts an optional error to a result
    static func fromOptionalError(_ error: Error?) -> ConfigurationResult {
        guard let err = error else { return .completed }
        return .failed(err)
    }
}
