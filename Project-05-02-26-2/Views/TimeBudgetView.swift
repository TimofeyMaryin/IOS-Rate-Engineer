//
//  TimeBudgetView.swift
//  Hourly Rate Engineer
//
//  Professional work schedule configuration with iOS 18+ design
//  Enhanced visual feedback and accessibility
//

import SwiftUI

struct TimeBudgetView: View {
    @Environment(DataController.self) var dataController
    @Binding var navigateToNext: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var workingDaysPerWeek: Int = 5
    @State private var hoursPerDay: Double = 8.0
    @State private var holidays: Int = 10
    @State private var vacationDays: Int = 20
    @State private var sickDays: Int = 5
    @State private var nonBillablePercent: Double = 0.2
    @State private var isVisible = false
    
    private var timeBudget: TimeBudgetData {
        TimeBudgetData(
            workingDaysPerWeek: Int16(workingDaysPerWeek),
            hoursPerDay: hoursPerDay,
            holidays: Int16(holidays),
            vacationDays: Int16(vacationDays),
            sickDays: Int16(sickDays),
            nonBillablePercent: nonBillablePercent
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                headerSection
                
                // Work Schedule Section
                workScheduleSection
                
                // Time Off Section
                timeOffSection
                
                // Non-Billable Time Section
                nonBillableSection
                
                // Calculated Results
                calculatedResultsSection
                
                // Visual Hours Breakdown
                hoursBreakdownSection
                
                Spacer(minLength: AppTheme.Spacing.xxl)
                
                // Continue button
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
                                AppTheme.Colors.chartBlue.opacity(0.2),
                                AppTheme.Colors.chartBlue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.Colors.chartBlue)
                    .symbolEffect(.bounce, value: isVisible)
            }
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Time Budget")
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Text("Configure your work schedule")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
    
    // MARK: - Work Schedule Section
    private var workScheduleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader("Work Schedule", icon: "briefcase.fill")
            
            NumberInputField(
                title: "Working Days per Week",
                value: $workingDaysPerWeek,
                range: 1...7,
                suffix: "days"
            )
            
            DecimalInputField(
                title: "Hours per Day",
                value: $hoursPerDay,
                range: 1...16,
                step: 0.5,
                suffix: "hours"
            )
        }
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Time Off Section
    private var timeOffSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader("Time Off (Annual)", subtitle: "Days you won't be working", icon: "airplane.departure")
            
            NumberInputField(
                title: "Public Holidays",
                value: $holidays,
                range: 0...30,
                suffix: "days"
            )
            
            NumberInputField(
                title: "Vacation Days",
                value: $vacationDays,
                range: 0...60,
                suffix: "days"
            )
            
            NumberInputField(
                title: "Sick Days Reserve",
                value: $sickDays,
                range: 0...30,
                suffix: "days"
            )
        }
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Non-Billable Time Section
    private var nonBillableSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader("Non-Billable Time", subtitle: "Admin, marketing, learning", icon: "clock.arrow.2.circlepath")
            
            PercentageSlider(
                title: "Non-Billable Time",
                value: $nonBillablePercent,
                range: 0...0.5
            )
            
            InfoTip("Consider 15-25% for admin work, client communication, learning, and business development.", icon: "lightbulb.fill")
        }
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Calculated Results Section
    private var calculatedResultsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Calculated Hours")
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.graphite)
                Spacer()
                
                // Efficiency indicator
                let efficiency = 1 - nonBillablePercent
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                    Text("\(Int(efficiency * 100))% efficient")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(efficiency >= 0.8 ? AppTheme.Colors.success : AppTheme.Colors.warning)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill((efficiency >= 0.8 ? AppTheme.Colors.success : AppTheme.Colors.warning).opacity(0.12))
                }
            }
            
            Divider()
            
            InfoRow(
                icon: "calendar",
                title: "Working Days/Year",
                value: "\(timeBudget.annualWorkingDays) days",
                iconColor: AppTheme.Colors.chartBlue
            )
            
            let totalHours = Double(timeBudget.annualWorkingDays) * hoursPerDay
            InfoRow(
                icon: "clock",
                title: "Total Hours/Year",
                value: String(format: "%.0f hrs", totalHours),
                iconColor: AppTheme.Colors.chartOrange
            )
            
            InfoRow(
                icon: "clock.badge.checkmark.fill",
                title: "Billable Hours/Year",
                value: String(format: "%.0f hrs", timeBudget.annualBillableHours),
                valueColor: AppTheme.Colors.primary,
                iconColor: AppTheme.Colors.primary
            )
            
            InfoRow(
                icon: "calendar.badge.clock",
                title: "Billable Hours/Month",
                value: String(format: "%.1f hrs", timeBudget.monthlyBillableHours),
                valueColor: AppTheme.Colors.success,
                iconColor: AppTheme.Colors.success
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
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Hours Breakdown Section
    private var hoursBreakdownSection: some View {
        HoursBreakdownChart(
            totalHours: Double(timeBudget.annualWorkingDays) * hoursPerDay,
            billableHours: timeBudget.annualBillableHours
        )
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Functions
    private func loadExistingData() {
        if let existing = dataController.timeBudget {
            workingDaysPerWeek = Int(existing.workingDaysPerWeek)
            hoursPerDay = existing.hoursPerDay
            holidays = Int(existing.holidays)
            vacationDays = Int(existing.vacationDays)
            sickDays = Int(existing.sickDays)
            nonBillablePercent = existing.nonBillablePercent
        }
    }
    
    private func saveAndContinue() {
        dataController.saveTimeBudget(timeBudget)
        navigateToNext = true
    }
}

// MARK: - Hours Breakdown Chart (Enhanced)
struct HoursBreakdownChart: View {
    let totalHours: Double
    let billableHours: Double
    
    @State private var animationProgress: Double = 0
    
    private var nonBillableHours: Double {
        totalHours - billableHours
    }
    
    private var billablePercentage: Double {
        guard totalHours > 0 else { return 0 }
        return billableHours / totalHours
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Hours Breakdown")
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Spacer()
                
                Text("\(Int(billablePercentage * 100))% billable")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.success)
            }
            
            // Animated bar chart
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.Colors.divider.opacity(0.2))
                    
                    // Billable hours (green)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.success, AppTheme.Colors.chartGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * billablePercentage * animationProgress))
                    
                    // Label inside bar
                    if animationProgress > 0 {
                        HStack {
                            Text(String(format: "%.0f hrs", billableHours))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.leading, AppTheme.Spacing.sm)
                            Spacer()
                        }
                    }
                }
            }
            .frame(height: 36)
            
            // Legend
            HStack(spacing: AppTheme.Spacing.lg) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Circle()
                        .fill(AppTheme.Colors.success)
                        .frame(width: 10, height: 10)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Billable")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.Colors.graphite)
                        Text(String(format: "%.0f hrs", billableHours))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.graphiteLight)
                    }
                }
                
                HStack(spacing: AppTheme.Spacing.xs) {
                    Circle()
                        .fill(AppTheme.Colors.graphiteLight.opacity(0.4))
                        .frame(width: 10, height: 10)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Non-billable")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.Colors.graphite)
                        Text(String(format: "%.0f hrs", nonBillableHours))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.graphiteLight)
                    }
                }
                
                Spacer()
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
        .onAppear {
            withAnimation(AppTheme.Animation.smooth.delay(0.3)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TimeBudgetView(navigateToNext: .constant(false))
            .environment(DataController.shared)
    }
}
