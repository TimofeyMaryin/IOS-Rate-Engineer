//
//  MainTabView.swift
//  Hourly Rate Engineer
//
//  Professional main navigation with iOS 18+ design
//  Custom TabView styling with haptic feedback
//

import SwiftUI

struct MainTabView: View {
    @Environment(DataController.self) var dataController
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    private var hasAllRequiredData: Bool {
        dataController.incomeTarget != nil && dataController.timeBudget != nil
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Calculator Tab (Wizard)
            NavigationStack {
                WizardContainerView()
            }
            .tabItem {
                Label("Calculator", systemImage: selectedTab == 0 ? "function" : "function")
            }
            .tag(0)
            
            // Results Tab
            NavigationStack {
                if hasAllRequiredData {
                    RealRateView()
                } else {
                    NoDataView {
                        selectedTab = 0
                    }
                }
            }
            .tabItem {
                Label("Results", systemImage: selectedTab == 1 ? "chart.pie.fill" : "chart.pie")
            }
            .tag(1)
            
            // Projects Tab
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: selectedTab == 2 ? "folder.fill" : "folder")
                }
                .tag(2)
            
            // Tools Tab (More features)
            NavigationStack {
                ToolsView()
            }
            .tabItem {
                Label("Tools", systemImage: selectedTab == 3 ? "wrench.and.screwdriver.fill" : "wrench.and.screwdriver")
            }
            .tag(3)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: selectedTab == 4 ? "gearshape.fill" : "gearshape")
            }
            .tag(4)
        }
        .tint(AppTheme.Colors.primary)
        .onChange(of: selectedTab) { oldValue, newValue in
            previousTab = oldValue
            AppTheme.Haptics.selection()
        }
    }
}

// MARK: - Tools View (Hub for additional features)
struct ToolsView: View {
    @Environment(DataController.self) var dataController
    
    var body: some View {
        List {
            // Analytics Section
            Section {
                NavigationLink {
                    HistoryView()
                } label: {
                    ToolsRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Rate History",
                        subtitle: "\(dataController.rateHistory.count) entries",
                        color: AppTheme.Colors.chartGreen
                    )
                }
                
                NavigationLink {
                    GoalsView()
                } label: {
                    ToolsRow(
                        icon: "target",
                        title: "Financial Goals",
                        subtitle: "\(dataController.activeGoals().count) active",
                        color: AppTheme.Colors.chartPurple
                    )
                }
                
                NavigationLink {
                    MarketComparisonView()
                } label: {
                    ToolsRow(
                        icon: "chart.bar.xaxis",
                        title: "Market Comparison",
                        subtitle: "Compare your rates",
                        color: AppTheme.Colors.chartBlue
                    )
                }
            } header: {
                Text("Analytics")
            }
            
            // Tools Section
            Section {
                NavigationLink {
                    CurrencyView()
                } label: {
                    ToolsRow(
                        icon: "dollarsign.arrow.circlepath",
                        title: "Currency Converter",
                        subtitle: "\(dataController.currencyRates.count) rates saved",
                        color: AppTheme.Colors.chartOrange
                    )
                }
                
                NavigationLink {
                    RemindersView()
                } label: {
                    ToolsRow(
                        icon: "bell.badge",
                        title: "Reminders",
                        subtitle: reminderSubtitle,
                        color: AppTheme.Colors.chartTeal
                    )
                }
                
                NavigationLink {
                    ExportView()
                } label: {
                    ToolsRow(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        subtitle: "CSV, PDF, JSON",
                        color: AppTheme.Colors.chartIndigo
                    )
                }
            } header: {
                Text("Tools")
            }
            
            // Quick Stats
            Section {
                VStack(spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        QuickStatBox(
                            title: "Projects",
                            value: "\(dataController.activeProjects().count)",
                            subtitle: "active",
                            color: AppTheme.Colors.chartBlue
                        )
                        
                        QuickStatBox(
                            title: "Goals",
                            value: String(format: "%.0f%%", averageGoalProgress * 100),
                            subtitle: "avg progress",
                            color: AppTheme.Colors.chartGreen
                        )
                    }
                    
                    HStack(spacing: AppTheme.Spacing.md) {
                        QuickStatBox(
                            title: "This Month",
                            value: String(format: "%.1f", totalHoursThisMonth),
                            subtitle: "hours tracked",
                            color: AppTheme.Colors.chartPurple
                        )
                        
                        QuickStatBox(
                            title: "Rate History",
                            value: "\(dataController.rateHistory.count)",
                            subtitle: "calculations",
                            color: AppTheme.Colors.chartOrange
                        )
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text("Quick Stats")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tools")
    }
    
    private var reminderSubtitle: String {
        let active = dataController.reminders.filter { $0.isEnabled }.count
        return "\(active) active"
    }
    
    private var averageGoalProgress: Double {
        let activeGoals = dataController.activeGoals()
        guard !activeGoals.isEmpty else { return 0 }
        return activeGoals.map(\.progress).reduce(0, +) / Double(activeGoals.count)
    }
    
    private var totalHoursThisMonth: Double {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        return dataController.timeEntries
            .filter { $0.startTime >= startOfMonth }
            .reduce(0) { $0 + $1.durationHours }
    }
}

// MARK: - Tools Row
struct ToolsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.gradient)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Stat Box
struct QuickStatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.graphiteLight)
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.Colors.graphiteLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Wizard Container View
struct WizardContainerView: View {
    @Environment(DataController.self) var dataController
    
    @State private var navigateToTime = false
    @State private var navigateToEquipment = false
    @State private var navigateToCosts = false
    @State private var navigateToSocial = false
    @State private var navigateToResults = false
    
    var body: some View {
        IncomeTargetView(navigateToNext: $navigateToTime)
            .navigationDestination(isPresented: $navigateToTime) {
                TimeBudgetView(navigateToNext: $navigateToEquipment)
                    .navigationDestination(isPresented: $navigateToEquipment) {
                        EquipmentView(navigateToNext: $navigateToCosts)
                            .navigationDestination(isPresented: $navigateToCosts) {
                                FixedCostsView(navigateToNext: $navigateToSocial)
                                    .navigationDestination(isPresented: $navigateToSocial) {
                                        SocialNetView(navigateToNext: $navigateToResults)
                                            .navigationDestination(isPresented: $navigateToResults) {
                                                RealRateView()
                                            }
                                    }
                            }
                    }
            }
    }
}

// MARK: - No Data View (Enhanced)
struct NoDataView: View {
    let onStartCalculator: () -> Void
    
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer(minLength: AppTheme.Spacing.xxxl)
                
                // Animated icon
                ZStack {
                    // Background circles
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(AppTheme.Colors.primary.opacity(0.1 - Double(i) * 0.03), lineWidth: 2)
                            .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                    }
                    
                    // Main icon
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.primary.opacity(0.15), AppTheme.Colors.primaryAccent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "chart.pie")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
                .onAppear {
                    withAnimation(AppTheme.Animation.bouncy.delay(0.1)) {
                        iconScale = 1
                        iconOpacity = 1
                    }
                }
                
                // Text content
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("No Rate Calculated Yet")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.graphite)
                    
                    Text("Complete the calculator wizard to see your personalized rate breakdown and insights")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // CTA Button
                Button {
                    AppTheme.Haptics.medium()
                    onStartCalculator()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Start Calculator")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppTheme.Spacing.xl)
                
                Spacer(minLength: AppTheme.Spacing.xxxl)
                
                // Disclaimer
                DisclaimerText()
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
            .frame(maxWidth: .infinity)
        }
        .background {
            AppTheme.Colors.background
                .ignoresSafeArea()
        }
        .navigationTitle("Results")
    }
}

// MARK: - Settings View (Enhanced)
struct SettingsView: View {
    @Environment(DataController.self) var dataController
    @Environment(\.colorScheme) private var colorScheme
    @State private var showResetConfirmation = false
    
    var body: some View {
        List {
            // App Info Section
            Section {
                // App Header
                HStack(spacing: AppTheme.Spacing.md) {
                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hourly Rate Engineer")
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.graphite)
                        
                        Text("Version 1.0.0 (1)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.graphiteLight)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
                .listRowBackground(Color.clear)
            }
            
            // Information Section
            Section {
                NavigationLink {
                    AboutView()
                } label: {
                    SettingsRow(icon: "info.circle.fill", title: "About", color: AppTheme.Colors.chartBlue)
                }
                
                NavigationLink {
                    PrivacyView()
                } label: {
                    SettingsRow(icon: "hand.raised.fill", title: "Privacy", color: AppTheme.Colors.chartGreen)
                }
            } header: {
                Text("Information")
            }
            
            // Data Section
            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    SettingsRow(icon: "trash.fill", title: "Reset All Data", color: AppTheme.Colors.error)
                }
            } header: {
                Text("Data")
            } footer: {
                Text("This will delete all your saved data and show the onboarding again.")
            }
            
            // Footer
            Section {
                VStack(spacing: AppTheme.Spacing.md) {
                    DisclaimerText()
                    
                    Text("Made with care for freelancers")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .alert("Reset All Data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                AppTheme.Haptics.warning()
                dataController.resetAllData()
            }
        } message: {
            Text("This action cannot be undone. All your income, expenses, equipment, and scenarios will be permanently deleted.")
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(color)
                }
            
            Text(title)
                .foregroundStyle(title == "Reset All Data" ? AppTheme.Colors.error : AppTheme.Colors.graphite)
        }
    }
}

// MARK: - About View (Enhanced)
struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var featuresVisible = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // App Icon with animation
                ZStack {
                    // Background glow
                    Circle()
                        .fill(AppTheme.Colors.primary.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5))
                    }
                    .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 20, x: 0, y: 10)
                }
                .padding(.top, AppTheme.Spacing.xl)
                
                // App name
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Hourly Rate Engineer")
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.graphite)
                    
                    Text("Freelance Rate Calculator")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                }
                
                // About text
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    Text("About This App")
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.graphite)
                    
                    Text("Hourly Rate Engineer helps freelancers and self-employed professionals calculate their minimum hourly rate. The app takes into account your income goals, taxes, expenses, equipment costs, and safety net requirements to provide an accurate rate estimation.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Features")
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.graphite)
                        .padding(.top, AppTheme.Spacing.sm)
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        FeatureRow(icon: "dollarsign.circle.fill", text: "Income goal setting with tax calculations", color: AppTheme.Colors.chartGreen, delay: 0)
                        FeatureRow(icon: "calendar.badge.clock", text: "Work schedule and billable hours planning", color: AppTheme.Colors.chartBlue, delay: 0.05)
                        FeatureRow(icon: "desktopcomputer", text: "Equipment amortization tracking", color: AppTheme.Colors.chartPurple, delay: 0.1)
                        FeatureRow(icon: "creditcard.fill", text: "Fixed costs management", color: AppTheme.Colors.chartOrange, delay: 0.15)
                        FeatureRow(icon: "umbrella.fill", text: "Safety net fund planning", color: AppTheme.Colors.chartTeal, delay: 0.2)
                        FeatureRow(icon: "slider.horizontal.3", text: "Interactive scenario analysis", color: AppTheme.Colors.chartPink, delay: 0.25)
                        FeatureRow(icon: "doc.text.fill", text: "PDF report export", color: AppTheme.Colors.chartIndigo, delay: 0.3)
                    }
                    .opacity(featuresVisible ? 1 : 0)
                    .offset(y: featuresVisible ? 0 : 10)
                }
                .padding(AppTheme.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(AppTheme.Colors.cardBackground)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .strokeBorder(AppTheme.Colors.divider.opacity(0.3), lineWidth: 0.5)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                DisclaimerText()
                    .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .background {
            AppTheme.Colors.background
                .ignoresSafeArea()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(0.2)) {
                featuresVisible = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background {
                    Circle()
                        .fill(color.opacity(0.12))
                }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.graphite)
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -10)
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Privacy View (Enhanced)
struct PrivacyView: View {
    @State private var cardsVisible = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.success.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.Colors.success)
                            .symbolEffect(.bounce, options: .speed(0.5))
                    }
                    
                    Text("Your Privacy Matters")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.graphite)
                    
                    Text("Hourly Rate Engineer is designed with privacy at its core.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppTheme.Spacing.xl)
                
                // Privacy points
                VStack(spacing: AppTheme.Spacing.sm) {
                    PrivacyPointCard(
                        icon: "iphone",
                        title: "100% Offline",
                        description: "All calculations happen on your device. No internet connection required.",
                        color: AppTheme.Colors.chartBlue,
                        delay: 0
                    )
                    
                    PrivacyPointCard(
                        icon: "internaldrive.fill",
                        title: "Local Storage Only",
                        description: "Your data is stored only on your device using Core Data. Nothing is sent to any server.",
                        color: AppTheme.Colors.chartPurple,
                        delay: 0.05
                    )
                    
                    PrivacyPointCard(
                        icon: "eye.slash.fill",
                        title: "No Tracking",
                        description: "No analytics, no tracking, no third-party SDKs. Your financial data stays private.",
                        color: AppTheme.Colors.chartOrange,
                        delay: 0.1
                    )
                    
                    PrivacyPointCard(
                        icon: "person.fill.xmark",
                        title: "No Account Required",
                        description: "Use the app without creating any account or providing personal information.",
                        color: AppTheme.Colors.chartTeal,
                        delay: 0.15
                    )
                    
                    PrivacyPointCard(
                        icon: "xmark.shield.fill",
                        title: "No Data Collection",
                        description: "We don't collect, store, or process any of your data. Period.",
                        color: AppTheme.Colors.chartGreen,
                        delay: 0.2
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                DisclaimerText()
                    .padding(.top, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .background {
            AppTheme.Colors.background
                .ignoresSafeArea()
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPointCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(color.opacity(0.12))
                }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .strokeBorder(AppTheme.Colors.divider.opacity(0.3), lineWidth: 0.5)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(delay)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environment(DataController.shared)
}
