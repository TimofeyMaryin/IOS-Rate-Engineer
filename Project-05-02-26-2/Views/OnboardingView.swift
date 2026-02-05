//
//  OnboardingView.swift
//  Hourly Rate Engineer
//
//  Professional onboarding wizard with iOS 18+ animations
//  MeshGradient backgrounds and fluid transitions
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentStep = 0
    @Environment(\.colorScheme) private var colorScheme
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            // Animated mesh gradient background
            MeshGradientBackground(animate: true)
                .opacity(colorScheme == .dark ? 0.6 : 0.4)
            
            // Background color
            AppTheme.Colors.background
                .opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: AppTheme.Spacing.md) {
                    StepIndicator(currentStep: currentStep, totalSteps: totalSteps)
                    
                    Spacer()
                    
                    // Skip button
                    if currentStep < totalSteps - 1 {
                        Button("Skip") {
                            AppTheme.Haptics.light()
                            withAnimation(AppTheme.Animation.smooth) {
                                currentStep = totalSteps - 1
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    IncomeExplanationStep()
                        .tag(1)
                    
                    TimeExplanationStep()
                        .tag(2)
                    
                    CostsExplanationStep()
                        .tag(3)
                    
                    ReadyStep()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AppTheme.Animation.smooth, value: currentStep)
                
                // Navigation buttons
                HStack(spacing: AppTheme.Spacing.md) {
                    if currentStep > 0 {
                        Button {
                            AppTheme.Haptics.light()
                            withAnimation(AppTheme.Animation.smooth) {
                                currentStep -= 1
                            }
                        } label: {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Button {
                        if currentStep == totalSteps - 1 {
                            AppTheme.Haptics.success()
                            withAnimation(AppTheme.Animation.smooth) {
                                hasCompletedOnboarding = true
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            }
                        } else {
                            AppTheme.Haptics.light()
                            withAnimation(AppTheme.Animation.smooth) {
                                currentStep += 1
                            }
                        }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                            if currentStep < totalSteps - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
    }
}

// MARK: - Welcome Step (Enhanced)
struct WelcomeStep: View {
    @State private var iconVisible = false
    @State private var textVisible = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Animated app icon
            ZStack {
                // Outer rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            AppTheme.Colors.primary.opacity(0.15 - Double(i) * 0.04),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(160 + i * 50), height: CGFloat(160 + i * 50))
                        .scaleEffect(iconVisible ? 1 : 0.8)
                        .opacity(iconVisible ? 1 : 0)
                        .animation(AppTheme.Animation.bouncy.delay(Double(i) * 0.1), value: iconVisible)
                }
                
                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.primary.opacity(0.2),
                                AppTheme.Colors.primaryAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                // Main icon
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce, options: .speed(0.5), value: iconVisible)
            }
            .scaleEffect(iconVisible ? 1 : 0.5)
            .opacity(iconVisible ? 1 : 0)
            
            // Text content
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Hourly Rate Engineer")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.graphite)
                    .multilineTextAlignment(.center)
                
                Text("Calculate your minimum freelance rate with precision and confidence")
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            .opacity(textVisible ? 1 : 0)
            .offset(y: textVisible ? 0 : 20)
            
            Spacer()
            
            DisclaimerText()
                .opacity(textVisible ? 1 : 0)
                .padding(.bottom, AppTheme.Spacing.md)
        }
        .padding(AppTheme.Spacing.lg)
        .onAppear {
            withAnimation(AppTheme.Animation.bouncy.delay(0.2)) {
                iconVisible = true
            }
            withAnimation(AppTheme.Animation.smooth.delay(0.4)) {
                textVisible = true
            }
        }
    }
}

// MARK: - Income Explanation Step
struct IncomeExplanationStep: View {
    var body: some View {
        OnboardingStepContent(
            icon: "banknote.fill",
            iconColor: AppTheme.Colors.chartGreen,
            title: "Set Your Income Goal",
            description: "Start by defining how much net income you want to earn each month. This is your take-home pay after all expenses.",
            features: [
                OnboardingFeature(icon: "target", text: "Define your monthly net income target"),
                OnboardingFeature(icon: "percent", text: "Choose your tax regime and rate"),
                OnboardingFeature(icon: "dollarsign.circle.fill", text: "Select from 40+ currencies")
            ]
        )
    }
}

// MARK: - Time Explanation Step
struct TimeExplanationStep: View {
    var body: some View {
        OnboardingStepContent(
            icon: "calendar.badge.clock",
            iconColor: AppTheme.Colors.chartBlue,
            title: "Plan Your Time",
            description: "Configure your work schedule to calculate actual billable hours. Account for holidays, vacation, and non-productive time.",
            features: [
                OnboardingFeature(icon: "calendar", text: "Set working days and hours"),
                OnboardingFeature(icon: "airplane.departure", text: "Plan for holidays and vacation"),
                OnboardingFeature(icon: "clock.arrow.2.circlepath", text: "Account for non-billable time")
            ]
        )
    }
}

// MARK: - Costs Explanation Step
struct CostsExplanationStep: View {
    var body: some View {
        OnboardingStepContent(
            icon: "creditcard.fill",
            iconColor: AppTheme.Colors.chartOrange,
            title: "Track All Costs",
            description: "Include equipment depreciation and fixed monthly expenses to ensure your rate covers all business costs.",
            features: [
                OnboardingFeature(icon: "desktopcomputer", text: "Equipment amortization"),
                OnboardingFeature(icon: "building.2.fill", text: "Rent and workspace costs"),
                OnboardingFeature(icon: "wifi", text: "Subscriptions and utilities")
            ]
        )
    }
}

// MARK: - Ready Step (Enhanced)
struct ReadyStep: View {
    @State private var checkmarks: [Bool] = [false, false, false, false]
    @State private var headerVisible = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Success icon
            ZStack {
                // Animated rings
                ForEach(0..<2) { i in
                    Circle()
                        .stroke(
                            AppTheme.Colors.success.opacity(0.2 - Double(i) * 0.08),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.success.opacity(0.2),
                                AppTheme.Colors.success.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.Colors.success)
                    .symbolEffect(.bounce, value: headerVisible)
            }
            .scaleEffect(headerVisible ? 1 : 0.8)
            .opacity(headerVisible ? 1 : 0)
            
            // Text
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("You're Ready!")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Text("After completing the setup, you'll receive:")
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 10)
            
            // Checklist
            VStack(spacing: AppTheme.Spacing.md) {
                ReadyFeatureRow(text: "Your minimum hourly rate", isChecked: checkmarks[0])
                ReadyFeatureRow(text: "Daily and project rates", isChecked: checkmarks[1])
                ReadyFeatureRow(text: "Cost breakdown analysis", isChecked: checkmarks[2])
                ReadyFeatureRow(text: "PDF export for reference", isChecked: checkmarks[3])
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
            
            Spacer()
            
            DisclaimerText()
                .padding(.bottom, AppTheme.Spacing.md)
        }
        .padding(AppTheme.Spacing.lg)
        .onAppear {
            withAnimation(AppTheme.Animation.bouncy.delay(0.1)) {
                headerVisible = true
            }
            
            // Animate checkmarks sequentially
            for i in 0..<checkmarks.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.15) {
                    withAnimation(AppTheme.Animation.bouncy) {
                        checkmarks[i] = true
                    }
                    AppTheme.Haptics.light()
                }
            }
        }
    }
}

struct ReadyFeatureRow: View {
    let text: String
    let isChecked: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isChecked ? AppTheme.Colors.success : AppTheme.Colors.divider)
                    .frame(width: 26, height: 26)
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            Text(text)
                .font(.body)
                .foregroundStyle(AppTheme.Colors.graphite)
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text), \(isChecked ? "completed" : "pending")")
    }
}

// MARK: - Reusable Components
struct OnboardingStepContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [OnboardingFeature]
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(iconColor)
                    .symbolEffect(.bounce, value: isVisible)
            }
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            
            // Text
            VStack(spacing: AppTheme.Spacing.md) {
                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.graphite)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            
            // Features card
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(iconColor.opacity(0.12))
                            }
                        
                        Text(feature.text)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.Colors.graphite)
                        
                        Spacer()
                    }
                    .opacity(isVisible ? 1 : 0)
                    .offset(x: isVisible ? 0 : -20)
                    .animation(AppTheme.Animation.smooth.delay(Double(index) * 0.1), value: isVisible)
                }
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
            .shadowSmall()
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(0.1)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

// MARK: - Preview
#Preview {
    @Previewable @State var completed = false
    OnboardingView(hasCompletedOnboarding: $completed)
}
