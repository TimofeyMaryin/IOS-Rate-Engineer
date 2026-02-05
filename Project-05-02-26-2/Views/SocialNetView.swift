//
//  SocialNetView.swift
//  Hourly Rate Engineer
//
//  Social safety net and emergency fund configuration
//

import SwiftUI

struct SocialNetView: View {
    @Environment(DataController.self) var dataController
    @Binding var navigateToNext: Bool
    
    @State private var sickFundMonths: Double = 1.0
    @State private var safetyNetMonths: Double = 3.0
    @State private var targetSavingMonths: Int = 12
    
    private var currency: String {
        dataController.incomeTarget?.currency ?? "USD"
    }
    
    private var monthlyIncome: Double {
        dataController.incomeTarget?.netIncome ?? 0
    }
    
    private var totalFundNeeded: Double {
        (sickFundMonths + safetyNetMonths) * monthlyIncome
    }
    
    private var monthlyContribution: Double {
        guard targetSavingMonths > 0 else { return 0 }
        return totalFundNeeded / Double(targetSavingMonths)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "umbrella.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.Colors.chartGreen)
                    
                    Text("Social Safety Net")
                        .font(AppTheme.Typography.title1)
                        .foregroundColor(AppTheme.Colors.graphite)
                    
                    Text("Build your financial safety cushion")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.graphiteLight)
                }
                .padding(.top, AppTheme.Spacing.lg)
                
                // Explanation Card
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Why Safety Net Matters")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.graphite)
                    }
                    
                    Text("As a freelancer, you don't have employer-provided benefits. Building a safety net protects you during slow periods, illness, or unexpected expenses.")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.graphiteLight)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(AppTheme.Colors.primary.opacity(0.05))
                )
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Sick Fund Configuration
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    SectionHeader("Sick Leave Fund", subtitle: "Cover your income during illness")
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text("Fund Size")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.graphiteLight)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.1f", sickFundMonths)) month\(sickFundMonths == 1 ? "" : "s") of income")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        Slider(value: $sickFundMonths, in: 0...6, step: 0.5)
                            .tint(AppTheme.Colors.chartGreen)
                        
                        HStack {
                            Text("0")
                            Spacer()
                            Text("6 months")
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.graphiteLight)
                        
                        if sickFundMonths > 0 {
                            HStack {
                                Text("Target amount:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Colors.graphiteLight)
                                
                                Text(CurrencyFormatter.format(sickFundMonths * monthlyIncome, currency: currency))
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.chartGreen)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(AppTheme.Colors.background)
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Emergency Fund Configuration
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    SectionHeader("Emergency Fund", subtitle: "Cover expenses during slow periods")
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text("Fund Size")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.graphiteLight)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.1f", safetyNetMonths)) month\(safetyNetMonths == 1 ? "" : "s") of income")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        Slider(value: $safetyNetMonths, in: 0...12, step: 0.5)
                            .tint(AppTheme.Colors.chartBlue)
                        
                        HStack {
                            Text("0")
                            Spacer()
                            Text("12 months")
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundColor(AppTheme.Colors.graphiteLight)
                        
                        if safetyNetMonths > 0 {
                            HStack {
                                Text("Target amount:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Colors.graphiteLight)
                                
                                Text(CurrencyFormatter.format(safetyNetMonths * monthlyIncome, currency: currency))
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.chartBlue)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(AppTheme.Colors.background)
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Timeline Configuration
                if totalFundNeeded > 0 {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        SectionHeader("Savings Timeline", subtitle: "How long to build your safety net")
                        
                        NumberInputField(
                            title: "Build Over",
                            value: $targetSavingMonths,
                            range: 1...36,
                            suffix: "months"
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // Summary Card
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Safety Net Summary")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.graphite)
                    
                    Divider()
                    
                    InfoRow(
                        icon: "cross.case",
                        title: "Sick Leave Fund",
                        value: CurrencyFormatter.format(sickFundMonths * monthlyIncome, currency: currency)
                    )
                    
                    InfoRow(
                        icon: "shield.fill",
                        title: "Emergency Fund",
                        value: CurrencyFormatter.format(safetyNetMonths * monthlyIncome, currency: currency)
                    )
                    
                    Divider()
                    
                    InfoRow(
                        icon: "banknote",
                        title: "Total Fund Target",
                        value: CurrencyFormatter.format(totalFundNeeded, currency: currency),
                        valueColor: AppTheme.Colors.primary
                    )
                    
                    if totalFundNeeded > 0 {
                        InfoRow(
                            icon: "calendar.badge.plus",
                            title: "Monthly Contribution",
                            value: CurrencyFormatter.format(monthlyContribution, currency: currency),
                            valueColor: AppTheme.Colors.success
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .fill(AppTheme.Colors.cardBackground)
                )
                .shadowMedium()
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Visualization
                if totalFundNeeded > 0 {
                    SafetyNetVisualization(
                        sickFund: sickFundMonths * monthlyIncome,
                        emergencyFund: safetyNetMonths * monthlyIncome,
                        currency: currency
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // Info tip
                InfoTip("Most financial planners recommend 3-6 months of expenses as an emergency fund. As a freelancer, consider the higher end.")
                    .padding(.horizontal, AppTheme.Spacing.lg)
                
                Spacer(minLength: AppTheme.Spacing.xxl)
                
                // Navigation buttons
                VStack(spacing: AppTheme.Spacing.sm) {
                    Button("Calculate My Rate") {
                        saveAndContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    if totalFundNeeded == 0 {
                        Button("Skip Safety Net") {
                            saveAndContinue()
                        }
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.graphiteLight)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                DisclaimerText()
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
        .background(AppTheme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingData()
        }
    }
    
    private func loadExistingData() {
        if let existing = dataController.socialNet {
            sickFundMonths = existing.sickFundMonths
            safetyNetMonths = existing.safetyNetMonths
            targetSavingMonths = Int(existing.targetSavingMonths)
        }
    }
    
    private func saveAndContinue() {
        let data = SocialNetData(
            sickFundMonths: sickFundMonths,
            safetyNetMonths: safetyNetMonths,
            targetSavingMonths: Int16(targetSavingMonths)
        )
        dataController.saveSocialNet(data)
        navigateToNext = true
    }
}

// MARK: - Safety Net Visualization
struct SafetyNetVisualization: View {
    let sickFund: Double
    let emergencyFund: Double
    let currency: String
    
    private var total: Double {
        sickFund + emergencyFund
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Fund Composition")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.graphite)
            
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if sickFund > 0 {
                        Rectangle()
                            .fill(AppTheme.Colors.chartGreen)
                            .frame(width: geometry.size.width * (sickFund / max(total, 1)))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    if emergencyFund > 0 {
                        Rectangle()
                            .fill(AppTheme.Colors.chartBlue)
                            .frame(width: geometry.size.width * (emergencyFund / max(total, 1)))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            .frame(height: 24)
            
            HStack(spacing: AppTheme.Spacing.lg) {
                if sickFund > 0 {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Circle()
                            .fill(AppTheme.Colors.chartGreen)
                            .frame(width: 10, height: 10)
                        Text("Sick Leave")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.graphiteLight)
                    }
                }
                
                if emergencyFund > 0 {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Circle()
                            .fill(AppTheme.Colors.chartBlue)
                            .frame(width: 10, height: 10)
                        Text("Emergency")
                            .font(AppTheme.Typography.caption1)
                            .foregroundColor(AppTheme.Colors.graphiteLight)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.cardBackground)
        )
        .shadowSmall()
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SocialNetView(navigateToNext: .constant(false))
            .environment(DataController.shared)
    }
}
