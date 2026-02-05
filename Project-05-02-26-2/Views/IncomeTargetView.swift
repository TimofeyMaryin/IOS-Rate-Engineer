//
//  IncomeTargetView.swift
//  Hourly Rate Engineer
//
//  Professional income target configuration with iOS 18+ design
//  Enhanced inputs and Material design elements
//

import SwiftUI

struct IncomeTargetView: View {
    @Environment(DataController.self) var dataController
    @Binding var navigateToNext: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var netIncome: Double = 0
    @State private var selectedCurrency: String = "USD"
    @State private var selectedTaxRegime: String = "NPD"
    @State private var customTaxRate: Double = 0.06
    @State private var showCurrencyPicker = false
    @State private var showTaxPicker = false
    @State private var isVisible = false
    
    private var currentTaxRate: Double {
        if selectedTaxRegime == "CUSTOM" {
            return customTaxRate
        }
        return TaxRegimeInfo.regime(for: selectedTaxRegime)?.rate ?? 0.06
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                headerSection
                
                // Currency Selection
                currencySection
                
                // Net Income Input
                incomeInputSection
                
                // Tax Regime Selection
                taxRegimeSection
                
                // Custom Tax Rate (if selected)
                if selectedTaxRegime == "CUSTOM" {
                    customTaxSection
                }
                
                // Summary Card
                if netIncome > 0 {
                    summarySection
                }
                
                // Info tip
                InfoTip("Your gross income needs to be higher than your net income to account for taxes. The calculator will factor this into your hourly rate.")
                
                Spacer(minLength: AppTheme.Spacing.xxl)
                
                // Next button
                Button {
                    AppTheme.Haptics.medium()
                    saveAndContinue()
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(netIncome <= 0)
                
                DisclaimerText()
                    .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .background {
            AppTheme.Colors.background
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selectedCurrency: $selectedCurrency)
        }
        .sheet(isPresented: $showTaxPicker) {
            TaxRegimePickerSheet(selectedRegime: $selectedTaxRegime)
        }
        .onAppear {
            loadExistingData()
            withAnimation(AppTheme.Animation.smooth.delay(0.1)) {
                isVisible = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.chartGreen.opacity(0.2),
                                AppTheme.Colors.chartGreen.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "banknote.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.Colors.chartGreen)
                    .symbolEffect(.bounce, value: isVisible)
            }
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Income Target")
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Text("Define your desired monthly net income")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
    
    // MARK: - Currency Section
    private var currencySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Currency")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.Colors.graphiteLight)
            
            Button {
                AppTheme.Haptics.selection()
                showCurrencyPicker = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    // Currency symbol in circle
                    Text(CurrencyInfo.symbol(for: selectedCurrency))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(AppTheme.Colors.primary.opacity(0.12))
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCurrency)
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.graphite)
                        
                        if let currency = CurrencyInfo.all.first(where: { $0.code == selectedCurrency }) {
                            Text(currency.name)
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.graphiteLight)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                }
                .padding(AppTheme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(AppTheme.Colors.secondaryBackground)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .strokeBorder(AppTheme.Colors.divider.opacity(0.3), lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
        }
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Income Input Section
    private var incomeInputSection: some View {
        CurrencyInputField(
            title: "Desired Monthly Net Income",
            value: $netIncome,
            currency: selectedCurrency,
            placeholder: "Enter amount"
        )
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Tax Regime Section
    private var taxRegimeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Tax Regime")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.Colors.graphiteLight)
            
            Button {
                AppTheme.Haptics.selection()
                showTaxPicker = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    // Tax icon
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.chartBlue)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(AppTheme.Colors.chartBlue.opacity(0.12))
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TaxRegimeInfo.regime(for: selectedTaxRegime)?.name ?? selectedTaxRegime)
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.graphite)
                        
                        Text(TaxRegimeInfo.regime(for: selectedTaxRegime)?.description ?? "")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.graphiteLight)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Tax rate badge
                    Text("\(Int(currentTaxRate * 100))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background {
                            Capsule()
                                .fill(AppTheme.Colors.primary.opacity(0.12))
                        }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                }
                .padding(AppTheme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(AppTheme.Colors.secondaryBackground)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .strokeBorder(AppTheme.Colors.divider.opacity(0.3), lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
        }
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Custom Tax Section
    private var customTaxSection: some View {
        PercentageSlider(
            title: "Custom Tax Rate",
            value: $customTaxRate,
            range: 0...0.5
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Summary")
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.graphite)
                Spacer()
            }
            
            Divider()
            
            InfoRow(
                icon: "arrow.down.circle.fill",
                title: "Monthly Net Income",
                value: CurrencyFormatter.format(netIncome, currency: selectedCurrency),
                iconColor: AppTheme.Colors.chartGreen
            )
            
            InfoRow(
                icon: "percent",
                title: "Tax Rate",
                value: "\(Int(currentTaxRate * 100))%",
                iconColor: AppTheme.Colors.chartBlue
            )
            
            let grossIncome = netIncome / (1 - currentTaxRate)
            InfoRow(
                icon: "arrow.up.circle.fill",
                title: "Required Gross Income",
                value: CurrencyFormatter.format(grossIncome, currency: selectedCurrency),
                valueColor: AppTheme.Colors.primary,
                iconColor: AppTheme.Colors.primary
            )
            
            let taxAmount = grossIncome - netIncome
            InfoRow(
                icon: "building.columns.fill",
                title: "Estimated Tax",
                value: CurrencyFormatter.format(taxAmount, currency: selectedCurrency),
                valueColor: AppTheme.Colors.error,
                iconColor: AppTheme.Colors.error
            )
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
        .shadowMedium()
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(AppTheme.Animation.smooth, value: netIncome > 0)
    }
    
    // MARK: - Functions
    private func loadExistingData() {
        if let existing = dataController.incomeTarget {
            netIncome = existing.netIncome
            selectedCurrency = existing.currency
            selectedTaxRegime = existing.taxRegime
            customTaxRate = existing.taxRate
        }
    }
    
    private func saveAndContinue() {
        let data = IncomeTargetData(
            netIncome: netIncome,
            taxRegime: selectedTaxRegime,
            taxRate: currentTaxRate,
            currency: selectedCurrency
        )
        dataController.saveIncomeTarget(data)
        navigateToNext = true
    }
}

// MARK: - Currency Picker Sheet (Enhanced)
struct CurrencyPickerSheet: View {
    @Binding var selectedCurrency: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return CurrencyInfo.all
        }
        return CurrencyInfo.all.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredCurrencies) { currency in
                Button {
                    AppTheme.Haptics.selection()
                    selectedCurrency = currency.code
                    dismiss()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(currency.symbol)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.Colors.primary)
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill(AppTheme.Colors.primary.opacity(0.12))
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .font(.headline)
                                .foregroundStyle(AppTheme.Colors.graphite)
                            
                            Text(currency.name)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.Colors.graphiteLight)
                        }
                        
                        Spacer()
                        
                        if currency.code == selectedCurrency {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AppTheme.Colors.primary)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search currencies")
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tax Regime Picker Sheet (Enhanced)
struct TaxRegimePickerSheet: View {
    @Binding var selectedRegime: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(TaxRegimeInfo.all) { regime in
                Button {
                    AppTheme.Haptics.selection()
                    selectedRegime = regime.id
                    dismiss()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(regime.id == selectedRegime ? AppTheme.Colors.primary : AppTheme.Colors.chartBlue)
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill((regime.id == selectedRegime ? AppTheme.Colors.primary : AppTheme.Colors.chartBlue).opacity(0.12))
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(regime.name)
                                .font(.headline)
                                .foregroundStyle(AppTheme.Colors.graphite)
                            
                            Text(regime.description)
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.graphiteLight)
                        }
                        
                        Spacer()
                        
                        if regime.id != "CUSTOM" {
                            Text("\(Int(regime.rate * 100))%")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.Colors.primary)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background {
                                    Capsule()
                                        .fill(AppTheme.Colors.primary.opacity(0.12))
                                }
                        }
                        
                        if regime.id == selectedRegime {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AppTheme.Colors.primary)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle("Tax Regime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        IncomeTargetView(navigateToNext: .constant(false))
            .environment(DataController.shared)
    }
}
