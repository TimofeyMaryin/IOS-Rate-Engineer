//
//  LoadScenariosView.swift
//  Hourly Rate Engineer
//
//  Interactive scenario analysis with real-time calculations
//

import SwiftUI

struct LoadScenariosView: View {
    @Environment(DataController.self) var dataController
    @Environment(\.dismiss) private var dismiss
    @State private var calculator = RateCalculator()
    
    @State private var hoursPerWeek: Double = 40
    @State private var extraEquipmentCost: Double = 0
    @State private var showSaveSheet = false
    @State private var scenarioName = ""
    
    private var currency: String {
        dataController.incomeTarget?.currency ?? "USD"
    }
    
    private var baseResult: RateCalculator.CalculationResult {
        calculator.calculate(
            incomeTarget: dataController.incomeTarget,
            timeBudget: dataController.timeBudget,
            equipment: dataController.equipment,
            fixedCosts: dataController.fixedCosts,
            socialNet: dataController.socialNet
        )
    }
    
    private var scenarioResult: RateCalculator.CalculationResult {
        calculator.calculateForScenario(
            baseResult: baseResult,
            hoursPerWeek: hoursPerWeek,
            extraEquipmentCost: extraEquipmentCost,
            incomeTarget: dataController.incomeTarget,
            timeBudget: dataController.timeBudget,
            equipment: dataController.equipment,
            fixedCosts: dataController.fixedCosts,
            socialNet: dataController.socialNet
        )
    }
    
    private var rateChange: Double {
        guard baseResult.hourlyRate > 0 else { return 0 }
        return (scenarioResult.hourlyRate - baseResult.hourlyRate) / baseResult.hourlyRate
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        Text("Scenario Analysis")
                            .font(AppTheme.Typography.title2)
                            .foregroundColor(AppTheme.Colors.graphite)
                        
                        Text("See how changes affect your rate")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.graphiteLight)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                    
                    // Rate Comparison
                    RateComparisonCard(
                        baseRate: baseResult.hourlyRate,
                        scenarioRate: scenarioResult.hourlyRate,
                        rateChange: rateChange,
                        currency: currency
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    // Hours Slider
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        SectionHeader("Work Hours", subtitle: "Adjust billable hours per week")
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            HStack {
                                Text("Hours per Week")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Colors.graphiteLight)
                                
                                Spacer()
                                
                                Text("\(Int(hoursPerWeek)) hours")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .monospacedDigit()
                            }
                            
                            Slider(value: $hoursPerWeek, in: 10...60, step: 1)
                                .tint(AppTheme.Colors.primary)
                            
                            HStack {
                                Text("10h (part-time)")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundColor(AppTheme.Colors.graphiteLight)
                                
                                Spacer()
                                
                                Text("60h (intense)")
                                    .font(AppTheme.Typography.caption2)
                                    .foregroundColor(AppTheme.Colors.graphiteLight)
                            }
                            
                            // Quick presets
                            HStack(spacing: AppTheme.Spacing.sm) {
                                QuickPresetButton(label: "20h", isSelected: hoursPerWeek == 20) {
                                    withAnimation { hoursPerWeek = 20 }
                                }
                                QuickPresetButton(label: "30h", isSelected: hoursPerWeek == 30) {
                                    withAnimation { hoursPerWeek = 30 }
                                }
                                QuickPresetButton(label: "40h", isSelected: hoursPerWeek == 40) {
                                    withAnimation { hoursPerWeek = 40 }
                                }
                                QuickPresetButton(label: "50h", isSelected: hoursPerWeek == 50) {
                                    withAnimation { hoursPerWeek = 50 }
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
                    
                    // Extra Equipment
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        SectionHeader("Additional Equipment", subtitle: "Plan for new equipment purchases")
                        
                        CurrencyInputField(
                            title: "New Equipment Cost",
                            value: $extraEquipmentCost,
                            currency: currency,
                            placeholder: "0"
                        )
                        
                        if extraEquipmentCost > 0 {
                            let extraMonthly = extraEquipmentCost / 36 // 3 year amortization
                            HStack {
                                Text("Added monthly cost:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Colors.graphiteLight)
                                
                                Text("+\(CurrencyFormatter.format(extraMonthly, currency: currency))")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.chartPurple)
                            }
                            .padding(.top, AppTheme.Spacing.xs)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    // Scenario Results
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Scenario Results")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.graphite)
                        
                        Divider()
                        
                        InfoRow(
                            icon: "clock",
                            title: "Hourly Rate",
                            value: CurrencyFormatter.format(scenarioResult.hourlyRate, currency: currency),
                            valueColor: AppTheme.Colors.primary
                        )
                        
                        InfoRow(
                            icon: "sun.max",
                            title: "Daily Rate",
                            value: CurrencyFormatter.format(scenarioResult.dailyRate, currency: currency)
                        )
                        
                        InfoRow(
                            icon: "calendar",
                            title: "Monthly Billable Hours",
                            value: String(format: "%.0f hrs", scenarioResult.monthlyBillableHours)
                        )
                        
                        InfoRow(
                            icon: "banknote",
                            title: "Monthly Gross Required",
                            value: CurrencyFormatter.format(scenarioResult.monthlyGrossIncome, currency: currency)
                        )
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .fill(AppTheme.Colors.cardBackground)
                    )
                    .shadowMedium()
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    // Saved Scenarios
                    if !dataController.scenarios.isEmpty {
                        SavedScenariosSection(currency: currency)
                    }
                    
                    // Save Button
                    Button {
                        showSaveSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save This Scenario")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    DisclaimerText()
                        .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Scenarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Save Scenario", isPresented: $showSaveSheet) {
                TextField("Scenario Name", text: $scenarioName)
                Button("Cancel", role: .cancel) {
                    scenarioName = ""
                }
                Button("Save") {
                    saveScenario()
                }
            } message: {
                Text("Enter a name for this scenario")
            }
            .onAppear {
                if let time = dataController.timeBudget {
                    hoursPerWeek = Double(time.workingDaysPerWeek) * time.hoursPerDay
                }
            }
        }
    }
    
    private func saveScenario() {
        let scenario = ScenarioData(
            name: scenarioName.isEmpty ? "Scenario \(dataController.scenarios.count + 1)" : scenarioName,
            hoursPerWeek: hoursPerWeek,
            extraEquipmentCost: extraEquipmentCost,
            createdAt: Date(),
            calculatedHourlyRate: scenarioResult.hourlyRate
        )
        dataController.saveScenario(scenario)
        scenarioName = ""
    }
}

// MARK: - Rate Comparison Card
struct RateComparisonCard: View {
    let baseRate: Double
    let scenarioRate: Double
    let rateChange: Double
    let currency: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Base Rate
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text("Base Rate")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.graphiteLight)
                
                Text(CurrencyFormatter.format(baseRate, currency: currency))
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.graphite)
            }
            .frame(maxWidth: .infinity)
            
            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.divider)
            
            // Scenario Rate
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text("Scenario Rate")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.graphiteLight)
                
                Text(CurrencyFormatter.format(scenarioRate, currency: currency))
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.primary)
                    .contentTransition(.numericText())
                
                // Change indicator
                HStack(spacing: AppTheme.Spacing.xxxs) {
                    Image(systemName: rateChange >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10))
                    
                    Text("\(String(format: "%.1f", abs(rateChange * 100)))%")
                        .font(AppTheme.Typography.caption1)
                }
                .foregroundColor(rateChange >= 0 ? AppTheme.Colors.error : AppTheme.Colors.success)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.Colors.cardBackground)
        )
        .shadowMedium()
    }
}

// MARK: - Quick Preset Button
struct QuickPresetButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.Typography.caption1)
                .foregroundColor(isSelected ? .white : AppTheme.Colors.graphite)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.cardBackground)
                )
        }
    }
}

// MARK: - Saved Scenarios Section
struct SavedScenariosSection: View {
    @Environment(DataController.self) var dataController
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader("Saved Scenarios")
            
            ForEach(dataController.scenarios) { scenario in
                SavedScenarioRow(scenario: scenario, currency: currency) {
                    dataController.deleteScenario(scenario)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}

struct SavedScenarioRow: View {
    let scenario: ScenarioData
    let currency: String
    let onDelete: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxxs) {
                Text(scenario.name)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.graphite)
                
                Text("\(Int(scenario.hoursPerWeek))h/week • \(dateFormatter.string(from: scenario.createdAt))")
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.graphiteLight)
            }
            
            Spacer()
            
            Text(CurrencyFormatter.format(scenario.calculatedHourlyRate, currency: currency))
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.primary)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.Colors.graphiteLight)
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
    LoadScenariosView()
        .environment(DataController.shared)
}
