
import SwiftUI

struct ContentView: View {
    @Environment(DataController.self) var dataController
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .animation(AppTheme.Animation.smooth, value: hasCompletedOnboarding)
    }
}

#Preview("Main App") {
    ContentView()
        .environment(DataController.shared)
}

#Preview("Onboarding") {
    @Previewable @AppStorage("hasCompletedOnboarding") var completed = false
    ContentView()
        .environment(DataController.shared)
        .onAppear {
            completed = false
        }
}
