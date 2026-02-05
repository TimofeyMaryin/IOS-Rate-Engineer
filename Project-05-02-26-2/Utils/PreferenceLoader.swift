//
//  ConfigurationBridge.swift
//  Hourly Rate Engineer
//

import Combine
import FirebaseRemoteConfig
import Foundation

/// Manages retrieval and caching of remote application parameters
/// Implements singleton pattern for consistent state management
final class ConfigurationBridge: ObservableObject {
    
    /// Shared instance for application-wide access
    static let instance = ConfigurationBridge()
    
    // MARK: - Private Properties
    
    private let configProvider: RemoteConfig
    private let targetParameter: String
    private var lastFetchTimestamp: Date?
    
    // MARK: - Initialization
    
    private init() {
        self.configProvider = RemoteConfig.remoteConfig()
        self.targetParameter = Self.computeParameterKey()
        
        configureProvider()
    }
    
    private func configureProvider() {
        var providerSettings = RemoteConfigSettings()
        providerSettings.minimumFetchInterval = 0
        
        configProvider.configSettings = providerSettings
        
        if let defaultsPath = Bundle.main.path(forResource: "RemoteConfigDefaults", ofType: "plist") {
            configProvider.setDefaults(fromPlist: "RemoteConfigDefaults")
        }
    }
    
    private static func computeParameterKey() -> String {
        let components = ["url", "2"]
        return components.joined(separator: "_")
    }
    
    // MARK: - Public Interface
    
    /// Retrieves the latest configuration from the remote source
    /// - Returns: Tuple containing optional resource path and operation result
    func retrieveConfiguration() async -> (resourcePath: String?, result: ConfigurationResult) {
        do {
            let activationStatus = try await configProvider.fetchAndActivate()
            lastFetchTimestamp = Date()
            
            return processActivationStatus(activationStatus)
            
        } catch {
            return handleFetchError(error)
        }
    }
    
    // MARK: - Private Processing
    
    private func processActivationStatus(
        _ status: RemoteConfigFetchAndActivateStatus
    ) -> (String?, ConfigurationResult) {
        
        switch status {
        case .successFetchedFromRemote, .successUsingPreFetchedData:
            let extractedValue = extractParameterValue()
            return (extractedValue, .completed)
            
        case .error:
            let configError = generateConfigurationError(
                code: -1001,
                description: "Remote configuration sync failed"
            )
            return (nil, .failed(configError))
            
        @unknown default:
            let unknownError = generateConfigurationError(
                code: -1002,
                description: "Unrecognized configuration state encountered"
            )
            return (nil, .failed(unknownError))
        }
    }
    
    private func extractParameterValue() -> String? {
        let rawValue = configProvider.configValue(forKey: targetParameter).stringValue ?? ""
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedValue.isEmpty else {
            return nil
        }
        
        return trimmedValue
    }
    
    private func handleFetchError(_ error: Error) -> (String?, ConfigurationResult) {
        let nsError = error as NSError
        
        // Check for throttling scenario
        if nsError.domain == RemoteConfigErrorDomain,
           nsError.code == RemoteConfigError.throttled.rawValue {
            
            let cachedValue = extractParameterValue()
            return (cachedValue, .rateLimited)
        }
        
        return (nil, .failed(error))
    }
    
    private func generateConfigurationError(code: Int, description: String) -> Error {
        NSError(
            domain: "com.app.configuration",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}

// MARK: - Convenience Extensions

extension ConfigurationBridge {
    
    /// Checks if a valid resource path is available
    var hasResourcePath: Bool {
        get async {
            let (path, _) = await retrieveConfiguration()
            return path != nil && !(path?.isEmpty ?? true)
        }
    }
}
