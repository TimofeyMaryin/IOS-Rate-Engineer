
import SwiftUI
import Firebase

@main
struct HourlyRateEngineerApp: App {
    
    // MARK: - Application State
    
    @State private var calculatorDataManager = DataController.shared
    @State private var currentViewport: ViewportTransition = .introSequence
    @State private var configurationResult: ConfigurationResult = .inProgress
    @State private var resolvedResourcePath: String?
    
    @AppStorage("hasCompletedOnboarding") private var onboardingCompleted = false
    
    // MARK: - Initialization
    
    init() {
        initializeServices()
    }
    
    private func initializeServices() {
        FirebaseApp.configure()
    }
    
    // MARK: - Scene Construction
    
    var body: some Scene {
        WindowGroup {
            rootViewContainer
                .task { await performInitialConfiguration() }
                .onChange(of: configurationResult, initial: true) { _, updatedResult in
                    handleConfigurationUpdate(updatedResult)
                }
        }
    }
    
    // MARK: - View Composition
    
    @ViewBuilder
    private var rootViewContainer: some View {
        ZStack {
            switch currentViewport {
            case .introSequence:
                introductionPhase
                
            case .calculatorMode:
                calculatorInterface
                
            case .externalRenderer(let resourcePath):
                externalContentPhase(resourcePath)
                
            case .recoveryPrompt(let diagnosticInfo):
                recoveryInterface(diagnosticInfo)
            }
        }
    }
    
    private var introductionPhase: some View {
        SplashScreenView()
    }
    
    private var calculatorInterface: some View {
        ContentView()
            .environment(calculatorDataManager)
    }
    
    @ViewBuilder
    private func externalContentPhase(_ resourcePath: String) -> some View {
        if validateResourceLocator(resourcePath) {
            ContentRenderer(resource: resourcePath)
                .edgesIgnoringSafeArea(.all)
        } else {
            invalidResourceView
        }
    }
    
    private var invalidResourceView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Invalid Resource")
                .font(.headline)
        }
    }
    
    private func recoveryInterface(_ diagnosticInfo: String) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.red.opacity(0.8))
                
                Text("Connection Issue")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text(diagnosticInfo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: retryConfiguration) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Configuration Management
    
    private func performInitialConfiguration() async {
        await transitionToIntro()
        
        let (resourcePath, result) = await ConfigurationBridge.instance.retrieveConfiguration()
        
        await updateConfigurationState(path: resourcePath, result: result)
        
        if shouldDefaultToCalculator(resourcePath) {
            transitionToCalculator()
        }
    }
    
    private func handleConfigurationUpdate(_ result: ConfigurationResult) {
        guard result.isSuccessful else { return }
        guard let path = resolvedResourcePath, !path.isEmpty else { return }
        
        Task { await validateAndNavigate(to: path) }
    }
    
    private func validateAndNavigate(to resourcePath: String) async {
        guard validateResourceLocator(resourcePath) else {
            transitionToCalculator()
            return
        }
        
        let isAccessible = await verifyResourceAccessibility(resourcePath)
        
        if isAccessible {
            await MainActor.run { currentViewport = .externalRenderer(resourcePath) }
        } else {
            transitionToCalculator()
        }
    }
    
    private func verifyResourceAccessibility(_ path: String) async -> Bool {
        guard let targetURL = URL(string: path) else { return false }
        
        var verificationRequest = URLRequest(url: targetURL)
        verificationRequest.httpMethod = "HEAD"
        verificationRequest.timeoutInterval = 10
        
        do {
            let (_, serverResponse) = try await URLSession.shared.data(for: verificationRequest)
            
            guard let httpResponse = serverResponse as? HTTPURLResponse else {
                return false
            }
            
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            return false
        }
    }
    
    // MARK: - State Transitions
    
    private func transitionToIntro() async {
        await MainActor.run { currentViewport = .introSequence }
    }
    
    private func transitionToCalculator() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentViewport = .calculatorMode
        }
    }
    
    private func retryConfiguration() {
        Task { await performInitialConfiguration() }
    }
    
    private func updateConfigurationState(path: String?, result: ConfigurationResult) async {
        await MainActor.run {
            self.resolvedResourcePath = path
            self.configurationResult = result
        }
    }
    
    // MARK: - Validation Helpers
    
    private func validateResourceLocator(_ path: String) -> Bool {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return URL(string: path) != nil
    }
    
    private func shouldDefaultToCalculator(_ path: String?) -> Bool {
        guard let resourcePath = path else { return true }
        return resourcePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Application Metadata

enum ApplicationMetadata {
    
    static let displayName = "Hourly Rate Engineer"
    static let tagline = "Freelance Rate Calculator"
    static let versionIdentifier = "1.0.0"
    static let buildIdentifier = "1"
    
    static let legalDisclaimer = """
    This is a private personal calculator for freelance rate estimation. \
    Not financial advice or professional consulting.
    """
    
    static var fullVersionString: String {
        "\(versionIdentifier) (\(buildIdentifier))"
    }
}
