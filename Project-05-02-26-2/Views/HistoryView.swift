//
//  HistoryView.swift
//  Hourly Rate Engineer
//
//  История расчётов с графиками и аналитикой
//

import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(DataController.self) private var dataController
    @State private var selectedPeriod: TimePeriod = .threeMonths
    @State private var selectedChart: ChartType = .hourlyRate
    @State private var showingAddSheet = false
    @State private var selectedEntry: RateHistoryData?
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: RateHistoryData?
    
    enum TimePeriod: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "All"
        
        var days: Int {
            switch self {
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .all: return Int.max
            }
        }
    }
    
    enum ChartType: String, CaseIterable {
        case hourlyRate = "Hourly"
        case monthlyIncome = "Monthly"
        case costs = "Costs"
        case comparison = "Compare"
    }
    
    var filteredHistory: [RateHistoryData] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date.distantPast
        return dataController.rateHistory.filter { selectedPeriod == .all || $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Период
                    periodSelector
                    
                    // Сводная статистика
                    if !filteredHistory.isEmpty {
                        summaryCards
                    }
                    
                    // Тип графика
                    chartTypeSelector
                    
                    // График
                    chartSection
                    
                    // Список записей
                    historyList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rate History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddHistoryEntrySheet()
            }
            .sheet(item: $selectedEntry) { entry in
                HistoryDetailSheet(entry: entry)
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        dataController.deleteRateHistory(entry)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this history entry?")
            }
        }
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedPeriod == period {
                                Capsule()
                                    .fill(Color.accentColor)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            SummaryCard(
                title: "Current Rate",
                value: CurrencyHelper.format(filteredHistory.last?.hourlyRate ?? 0, currency: filteredHistory.last?.currency ?? "USD"),
                icon: "dollarsign.circle.fill",
                color: .green
            )
            
            SummaryCard(
                title: "Average Rate",
                value: CurrencyHelper.format(averageRate, currency: filteredHistory.last?.currency ?? "USD"),
                icon: "chart.bar.fill",
                color: .blue
            )
            
            SummaryCard(
                title: "Rate Change",
                value: rateChangeString,
                icon: rateChange >= 0 ? "arrow.up.right" : "arrow.down.right",
                color: rateChange >= 0 ? .green : .red
            )
            
            SummaryCard(
                title: "Entries",
                value: "\(filteredHistory.count)",
                icon: "list.bullet",
                color: .purple
            )
        }
    }
    
    private var averageRate: Double {
        guard !filteredHistory.isEmpty else { return 0 }
        return filteredHistory.map(\.hourlyRate).reduce(0, +) / Double(filteredHistory.count)
    }
    
    private var rateChange: Double {
        guard filteredHistory.count >= 2 else { return 0 }
        let first = filteredHistory.first?.hourlyRate ?? 0
        let last = filteredHistory.last?.hourlyRate ?? 0
        guard first > 0 else { return 0 }
        return ((last - first) / first) * 100
    }
    
    private var rateChangeString: String {
        String(format: "%@%.1f%%", rateChange >= 0 ? "+" : "", rateChange)
    }
    
    // MARK: - Chart Type Selector
    private var chartTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    ChartTypeButton(
                        title: type.rawValue,
                        isSelected: selectedChart == type
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedChart = type
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Chart Section
    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(chartTitle)
                .font(.headline)
            
            if filteredHistory.isEmpty {
                ContentUnavailableView(
                    "No History Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Add your first calculation to see the history")
                )
                .frame(height: 200)
            } else {
                switch selectedChart {
                case .hourlyRate:
                    hourlyRateChart
                case .monthlyIncome:
                    monthlyIncomeChart
                case .costs:
                    costsChart
                case .comparison:
                    comparisonChart
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var chartTitle: String {
        switch selectedChart {
        case .hourlyRate: return "Hourly Rate Trend"
        case .monthlyIncome: return "Monthly Gross Income"
        case .costs: return "Cost Breakdown"
        case .comparison: return "Rate vs Costs"
        }
    }
    
    // MARK: - Charts
    private var hourlyRateChart: some View {
        Chart(filteredHistory) { entry in
            LineMark(
                x: .value("Date", entry.date),
                y: .value("Rate", entry.hourlyRate)
            )
            .foregroundStyle(Color.green.gradient)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", entry.date),
                y: .value("Rate", entry.hourlyRate)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.green.opacity(0.3), Color.green.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", entry.date),
                y: .value("Rate", entry.hourlyRate)
            )
            .foregroundStyle(Color.green)
            .symbolSize(40)
        }
        .frame(height: 200)
        .chartYAxisLabel("$/hr")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
    }
    
    private var monthlyIncomeChart: some View {
        Chart(filteredHistory) { entry in
            BarMark(
                x: .value("Date", entry.date, unit: .month),
                y: .value("Income", entry.monthlyGross)
            )
            .foregroundStyle(Color.blue.gradient)
            .cornerRadius(4)
        }
        .frame(height: 200)
        .chartYAxisLabel("Monthly $")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
    }
    
    private var costsChart: some View {
        Chart {
            let lastEntry = filteredHistory.last
            
            SectorMark(
                angle: .value("Tax", lastEntry?.taxAmount ?? 0),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(Color.red)
            .annotation(position: .overlay) {
                Text("Tax")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
            
            SectorMark(
                angle: .value("Fixed", lastEntry?.fixedCostsTotal ?? 0),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(Color.orange)
            .annotation(position: .overlay) {
                Text("Fixed")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
            
            SectorMark(
                angle: .value("Amort", lastEntry?.amortizationTotal ?? 0),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(Color.purple)
            .annotation(position: .overlay) {
                Text("Amort")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
            
            SectorMark(
                angle: .value("Social", lastEntry?.socialNetTotal ?? 0),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(Color.cyan)
            .annotation(position: .overlay) {
                Text("Social")
                    .font(.caption2)
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 200)
    }
    
    private var comparisonChart: some View {
        Chart(filteredHistory) { entry in
            LineMark(
                x: .value("Date", entry.date),
                y: .value("Rate", entry.hourlyRate)
            )
            .foregroundStyle(by: .value("Type", "Hourly Rate"))
            .interpolationMethod(.catmullRom)
            
            LineMark(
                x: .value("Date", entry.date),
                y: .value("Rate", entry.totalCosts / entry.billableHours)
            )
            .foregroundStyle(by: .value("Type", "Cost/Hour"))
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
        .chartForegroundStyleScale([
            "Hourly Rate": Color.green,
            "Cost/Hour": Color.red
        ])
        .chartLegend(position: .bottom)
    }
    
    // MARK: - History List
    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                Text("\(filteredHistory.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if filteredHistory.isEmpty {
                Text("No history entries yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredHistory.reversed()) { entry in
                        HistoryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntry = entry
                            }
                            .contextMenu {
                                Button {
                                    selectedEntry = entry
                                } label: {
                                    Label("View Details", systemImage: "eye")
                                }
                                
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ChartTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentColor)
                    } else {
                        Capsule()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    }
                }
        }
    }
}

struct HistoryRow: View {
    let entry: RateHistoryData
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.title2.bold())
                Text(entry.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(CurrencyHelper.format(entry.hourlyRate, currency: entry.currency) + "/hr")
                    .font(.headline)
                
                Text(CurrencyHelper.format(entry.monthlyGross, currency: entry.currency) + "/mo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add History Entry Sheet

struct AddHistoryEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    
    @State private var date = Date()
    @State private var hourlyRate: Double = 0
    @State private var dailyRate: Double = 0
    @State private var monthlyGross: Double = 0
    @State private var currency = "USD"
    @State private var netIncome: Double = 0
    @State private var taxAmount: Double = 0
    @State private var fixedCostsTotal: Double = 0
    @State private var amortizationTotal: Double = 0
    @State private var socialNetTotal: Double = 0
    @State private var billableHours: Double = 160
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Currency") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Currency", selection: $currency) {
                        ForEach(Array(CurrencyHelper.availableCurrencies.keys.sorted()), id: \.self) { code in
                            Text("\(code) - \(CurrencyHelper.availableCurrencies[code] ?? code)")
                                .tag(code)
                        }
                    }
                }
                
                Section("Rates") {
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("0", value: $hourlyRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Daily Rate")
                        Spacer()
                        TextField("0", value: $dailyRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Monthly Gross")
                        Spacer()
                        TextField("0", value: $monthlyGross, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Income & Tax") {
                    HStack {
                        Text("Net Income")
                        Spacer()
                        TextField("0", value: $netIncome, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tax Amount")
                        Spacer()
                        TextField("0", value: $taxAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Costs") {
                    HStack {
                        Text("Fixed Costs")
                        Spacer()
                        TextField("0", value: $fixedCostsTotal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Amortization")
                        Spacer()
                        TextField("0", value: $amortizationTotal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Social Net")
                        Spacer()
                        TextField("0", value: $socialNetTotal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Working Hours") {
                    HStack {
                        Text("Billable Hours")
                        Spacer()
                        TextField("160", value: $billableHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add History Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(hourlyRate <= 0)
                }
            }
        }
    }
    
    private func save() {
        let entry = RateHistoryData(
            date: date,
            hourlyRate: hourlyRate,
            dailyRate: dailyRate,
            monthlyGross: monthlyGross,
            currency: currency,
            netIncome: netIncome,
            taxAmount: taxAmount,
            fixedCostsTotal: fixedCostsTotal,
            amortizationTotal: amortizationTotal,
            socialNetTotal: socialNetTotal,
            billableHours: billableHours,
            notes: notes
        )
        dataController.saveRateHistory(entry)
    }
}

// MARK: - History Detail Sheet

struct HistoryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: RateHistoryData
    
    var body: some View {
        NavigationStack {
            List {
                Section("Date") {
                    LabeledContent("Date", value: entry.date.formatted(date: .long, time: .omitted))
                }
                
                Section("Rates") {
                    LabeledContent("Hourly Rate", value: CurrencyHelper.format(entry.hourlyRate, currency: entry.currency))
                    LabeledContent("Daily Rate", value: CurrencyHelper.format(entry.dailyRate, currency: entry.currency))
                    LabeledContent("Monthly Gross", value: CurrencyHelper.format(entry.monthlyGross, currency: entry.currency))
                }
                
                Section("Income & Tax") {
                    LabeledContent("Net Income", value: CurrencyHelper.format(entry.netIncome, currency: entry.currency))
                    LabeledContent("Tax Amount", value: CurrencyHelper.format(entry.taxAmount, currency: entry.currency))
                }
                
                Section("Costs") {
                    LabeledContent("Fixed Costs", value: CurrencyHelper.format(entry.fixedCostsTotal, currency: entry.currency))
                    LabeledContent("Amortization", value: CurrencyHelper.format(entry.amortizationTotal, currency: entry.currency))
                    LabeledContent("Social Net", value: CurrencyHelper.format(entry.socialNetTotal, currency: entry.currency))
                    LabeledContent("Total Costs", value: CurrencyHelper.format(entry.totalCosts, currency: entry.currency))
                }
                
                Section("Hours") {
                    LabeledContent("Billable Hours", value: String(format: "%.1f hrs", entry.billableHours))
                }
                
                if !entry.notes.isEmpty {
                    Section("Notes") {
                        Text(entry.notes)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

