//
//  RealRateView.swift
//  Hourly Rate Engineer
//
//  Professional rate calculation results with iOS 18+ design
//  Animated charts, Material effects, and accessibility
//

import SwiftUI

struct RealRateView: View {
    @Environment(DataController.self) var dataController
    @State private var calculator = RateCalculator()
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showScenarios = false
    @State private var showExport = false
    @State private var animateResults = false
    @State private var showDetails = false
    
    private var currency: String {
        dataController.incomeTarget?.currency ?? "USD"
    }
    
    private var result: RateCalculator.CalculationResult {
        calculator.calculate(
            incomeTarget: dataController.incomeTarget,
            timeBudget: dataController.timeBudget,
            equipment: dataController.equipment,
            fixedCosts: dataController.fixedCosts,
            socialNet: dataController.socialNet
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Hero Rate Card
                heroRateCard
                
                // Quick Stats
                quickStatsSection
                
                // Rate Composition Chart
                rateCompositionSection
                
                // Detailed Breakdown (Expandable)
                detailedBreakdownSection
                
                // Action Buttons
                actionButtonsSection
                
                // Disclaimer
                DisclaimerText()
                    .padding(.vertical, AppTheme.Spacing.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .background {
            // Subtle gradient background
            ZStack {
                AppTheme.Colors.background
                
                if animateResults {
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.primary.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Your Rate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(0.2)) {
                animateResults = true
            }
        }
        .sheet(isPresented: $showScenarios) {
            LoadScenariosView()
                .environment(dataController)
        }
        .sheet(isPresented: $showExport) {
            ExportView()
                .environment(dataController)
        }
    }
    
    // MARK: - Hero Rate Card
    private var heroRateCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Success badge
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.success)
                
                Text("Calculated Rate")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.success)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background {
                Capsule()
                    .fill(AppTheme.Colors.success.opacity(0.12))
            }
            .scaleEffect(animateResults ? 1 : 0.8)
            .opacity(animateResults ? 1 : 0)
            
            // Main rate display
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Minimum Hourly Rate")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(CurrencyInfo.symbol(for: currency))
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.Colors.primary)
                    
                    Text(String(format: "%.2f", result.hourlyRate))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.graphite)
                        .contentTransition(.numericText())
                }
                .scaleEffect(animateResults ? 1 : 0.9)
                .opacity(animateResults ? 1 : 0)
                
                Text("per billable hour")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xl)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xlarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.primary.opacity(0.08),
                            AppTheme.Colors.primaryAccent.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xlarge, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.primary.opacity(0.2),
                            AppTheme.Colors.primary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .padding(.top, AppTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Minimum hourly rate: \(CurrencyInfo.symbol(for: currency))\(String(format: "%.2f", result.hourlyRate)) per billable hour")
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
            StatCard(
                title: "Daily Rate",
                value: CurrencyFormatter.format(result.dailyRate, currency: currency, showDecimals: false),
                subtitle: "8hr day",
                icon: "sun.max.fill",
                color: AppTheme.Colors.chartOrange
            )
            
            StatCard(
                title: "Min Project",
                value: CurrencyFormatter.format(result.minimumProjectRate, currency: currency, showDecimals: false),
                subtitle: "1 week",
                icon: "folder.fill",
                color: AppTheme.Colors.chartPurple
            )
            
            StatCard(
                title: "Monthly Gross",
                value: CurrencyFormatter.formatCompact(result.monthlyGrossIncome, currency: currency),
                subtitle: "required",
                icon: "arrow.up.circle.fill",
                color: AppTheme.Colors.chartBlue
            )
            
            StatCard(
                title: "Billable Hours",
                value: String(format: "%.0f", result.monthlyBillableHours),
                subtitle: "per month",
                icon: "clock.fill",
                color: AppTheme.Colors.chartGreen
            )
        }
        .opacity(animateResults ? 1 : 0)
        .offset(y: animateResults ? 0 : 20)
    }
    
    // MARK: - Rate Composition Section
    private var rateCompositionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader("Rate Composition", icon: "chart.pie.fill")
            
            HStack(spacing: AppTheme.Spacing.lg) {
                // Donut Chart
                DonutChartView(
                    segments: result.breakdownPercentages.map { item in
                        DonutChartView.DonutSegment(
                            value: item.value,
                            color: colorForBreakdown(item.color),
                            label: item.name
                        )
                    },
                    showLabels: true
                )
                .frame(width: 130, height: 130)
                
                // Legend
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    ForEach(result.breakdownPercentages) { item in
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Circle()
                                .fill(colorForBreakdown(item.color))
                                .frame(width: 10, height: 10)
                            
                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.graphiteLight)
                            
                            Spacer()
                            
                            Text("\(Int(item.percentage * 100))%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.graphite)
                                .monospacedDigit()
                        }
                    }
                }
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
        .opacity(animateResults ? 1 : 0)
    }
    
    // MARK: - Detailed Breakdown Section
    private var detailedBreakdownSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(AppTheme.Animation.smooth) {
                    showDetails.toggle()
                }
                AppTheme.Haptics.selection()
            } label: {
                HStack {
                    SectionHeader("Detailed Breakdown", icon: "list.bullet.rectangle.fill")
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                        .rotationEffect(.degrees(showDetails ? 180 : 0))
                }
            }
            .buttonStyle(.plain)
            
            if showDetails {
                VStack(spacing: AppTheme.Spacing.xs) {
                    BreakdownRow(
                        title: "Net Income",
                        monthly: result.netIncomeComponent,
                        currency: currency,
                        color: AppTheme.Colors.chartBlue
                    )
                    
                    BreakdownRow(
                        title: "Taxes",
                        monthly: result.taxComponent,
                        currency: currency,
                        color: AppTheme.Colors.chartRed
                    )
                    
                    BreakdownRow(
                        title: "Fixed Costs",
                        monthly: result.fixedCostsComponent,
                        currency: currency,
                        color: AppTheme.Colors.chartOrange
                    )
                    
                    BreakdownRow(
                        title: "Equipment",
                        monthly: result.amortizationComponent,
                        currency: currency,
                        color: AppTheme.Colors.chartPurple
                    )
                    
                    BreakdownRow(
                        title: "Safety Net",
                        monthly: result.socialNetComponent,
                        currency: currency,
                        color: AppTheme.Colors.chartGreen
                    )
                    
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xs)
                    
                    // Total
                    HStack {
                        Text("Total Required")
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.graphite)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(CurrencyFormatter.format(result.monthlyGrossIncome, currency: currency))
                                .font(.headline)
                                .foregroundStyle(AppTheme.Colors.primary)
                            
                            Text("/month")
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.graphiteLight)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xs)
                    
                    // Hours info
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Annual Billable Hours")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.Colors.graphiteLight)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.0f hrs", result.annualBillableHours))
                            .font(.headline)
                            .foregroundStyle(AppTheme.Colors.graphite)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                AppTheme.Haptics.medium()
                showScenarios = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Explore Scenarios")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button {
                AppTheme.Haptics.medium()
                showExport = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Export PDF Report")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
    
    // MARK: - Helper Functions
    private func colorForBreakdown(_ color: RateCalculator.BreakdownColor) -> Color {
        switch color {
        case .blue: return AppTheme.Colors.chartBlue
        case .red: return AppTheme.Colors.chartRed
        case .orange: return AppTheme.Colors.chartOrange
        case .purple: return AppTheme.Colors.chartPurple
        case .green: return AppTheme.Colors.chartGreen
        }
    }
}

// MARK: - Breakdown Row
struct BreakdownRow: View {
    let title: String
    let monthly: Double
    let currency: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: AppTheme.Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.graphite)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(monthly, currency: currency))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.graphite)
                    .monospacedDigit()
                
                Text("/month")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(CurrencyFormatter.format(monthly, currency: currency)) per month")
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RealRateView()
            .environment(DataController.shared)
    }
}
