//
//  MarketComparisonView.swift
//  Hourly Rate Engineer
//
//  Сравнительный анализ с рыночными ставками
//

import SwiftUI
import Charts

struct MarketComparisonView: View {
    @Environment(DataController.self) private var dataController
    @State private var showingAddRate = false
    @State private var selectedRate: MarketRateData?
    @State private var yourRate: Double = 0
    @State private var showingDeleteAlert = false
    @State private var rateToDelete: MarketRateData?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Your rate input
                    yourRateSection
                    
                    // Comparison summary
                    if !dataController.marketRates.isEmpty {
                        comparisonSummary
                        
                        // Visual comparison chart
                        comparisonChart
                    }
                    
                    // Market rates list
                    marketRatesList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Market Comparison")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddRate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddRate) {
                AddMarketRateSheet()
            }
            .sheet(item: $selectedRate) { rate in
                MarketRateDetailSheet(rate: rate)
            }
            .alert("Delete Market Rate", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let rate = rateToDelete {
                        dataController.deleteMarketRate(rate)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this market rate?")
            }
            .onAppear {
                // Загружаем последнюю ставку из истории
                if let lastHistory = dataController.rateHistory.last {
                    yourRate = lastHistory.hourlyRate
                }
            }
        }
    }
    
    // MARK: - Your Rate Section
    private var yourRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Rate")
                .font(.headline)
            
            HStack {
                Text("$")
                    .font(.title2.bold())
                    .foregroundStyle(.secondary)
                
                TextField("0", value: $yourRate, format: .number)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                
                Text("/hr")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Text("Enter your hourly rate to compare with market data")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Comparison Summary
    private var comparisonSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How You Compare")
                .font(.headline)
            
            HStack(spacing: 12) {
                ComparisonCard(
                    title: "Below Market",
                    count: belowMarketCount,
                    color: .red,
                    icon: "arrow.down.circle.fill"
                )
                
                ComparisonCard(
                    title: "In Range",
                    count: inRangeCount,
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
                
                ComparisonCard(
                    title: "Above Market",
                    count: aboveMarketCount,
                    color: .blue,
                    icon: "arrow.up.circle.fill"
                )
            }
            
            // Overall position indicator
            overallPositionIndicator
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var belowMarketCount: Int {
        dataController.marketRates.filter { yourRate < $0.minRate }.count
    }
    
    private var inRangeCount: Int {
        dataController.marketRates.filter { yourRate >= $0.minRate && yourRate <= $0.maxRate }.count
    }
    
    private var aboveMarketCount: Int {
        dataController.marketRates.filter { yourRate > $0.maxRate }.count
    }
    
    private var overallPositionIndicator: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let position = averageMarketPosition
                
                ZStack(alignment: .leading) {
                    // Background gradient
                    LinearGradient(
                        colors: [.red, .yellow, .green, .yellow, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 12)
                    .clipShape(Capsule())
                    
                    // Position marker
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(radius: 2)
                        .overlay {
                            Circle()
                                .fill(positionColor(position))
                                .frame(width: 12, height: 12)
                        }
                        .offset(x: geometry.size.width * CGFloat(position) - 10)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("Below Market")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Average")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Above Market")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    private var averageMarketPosition: Double {
        guard !dataController.marketRates.isEmpty else { return 0.5 }
        
        let positions = dataController.marketRates.map { rate -> Double in
            if yourRate < rate.minRate {
                return yourRate / rate.minRate * 0.4
            } else if yourRate > rate.maxRate {
                return 0.6 + (min(yourRate / rate.maxRate, 2) - 1) * 0.4
            } else {
                return 0.4 + (yourRate - rate.minRate) / (rate.maxRate - rate.minRate) * 0.2
            }
        }
        
        return min(max(positions.reduce(0, +) / Double(positions.count), 0), 1)
    }
    
    private func positionColor(_ position: Double) -> Color {
        if position < 0.35 { return .red }
        if position > 0.65 { return .blue }
        return .green
    }
    
    // MARK: - Comparison Chart
    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rate Comparison")
                .font(.headline)
            
            Chart {
                ForEach(dataController.marketRates) { rate in
                    // Range bar
                    RectangleMark(
                        xStart: .value("Min", rate.minRate),
                        xEnd: .value("Max", rate.maxRate),
                        y: .value("Role", rate.name)
                    )
                    .foregroundStyle(Color.blue.opacity(0.3))
                    .cornerRadius(4)
                    
                    // Average marker
                    PointMark(
                        x: .value("Average", rate.averageRate),
                        y: .value("Role", rate.name)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(60)
                }
                
                // Your rate line
                RuleMark(x: .value("Your Rate", yourRate))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .annotation(position: .top) {
                        Text("You")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
            }
            .frame(height: CGFloat(dataController.marketRates.count) * 50 + 40)
            .chartXAxisLabel("Hourly Rate ($)")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Market Rates List
    private var marketRatesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Market Rates")
                    .font(.headline)
                Spacer()
                Text("\(dataController.marketRates.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if dataController.marketRates.isEmpty {
                ContentUnavailableView(
                    "No Market Data",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Add market rates to compare your pricing")
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(dataController.marketRates) { rate in
                        MarketRateRow(rate: rate, yourRate: yourRate)
                            .onTapGesture {
                                selectedRate = rate
                            }
                            .contextMenu {
                                Button {
                                    selectedRate = rate
                                } label: {
                                    Label("View Details", systemImage: "eye")
                                }
                                
                                Button(role: .destructive) {
                                    rateToDelete = rate
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

// MARK: - ComparisonCard

struct ComparisonCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.title2.bold())
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - MarketRateRow

struct MarketRateRow: View {
    let rate: MarketRateData
    let yourRate: Double
    
    var positionStatus: (text: String, color: Color, icon: String) {
        if yourRate < rate.minRate {
            return ("Below", .red, "arrow.down")
        } else if yourRate > rate.maxRate {
            return ("Above", .blue, "arrow.up")
        } else {
            return ("In Range", .green, "checkmark")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(rate.name)
                        .font(.subheadline.weight(.medium))
                    
                    if !rate.region.isEmpty {
                        Text(rate.region)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: positionStatus.icon)
                    Text(positionStatus.text)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(positionStatus.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(positionStatus.color.opacity(0.1), in: Capsule())
            }
            
            // Rate range visualization
            GeometryReader { geometry in
                let width = geometry.size.width
                let minPos = 0.0
                let maxPos = width
                let avgPos = width * 0.5
                let yourPos = calculateYourPosition(in: width)
                
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Range indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.4))
                        .frame(height: 8)
                    
                    // Your position
                    Circle()
                        .fill(positionStatus.color)
                        .frame(width: 16, height: 16)
                        .offset(x: yourPos - 8)
                }
            }
            .frame(height: 16)
            
            HStack {
                Text(CurrencyHelper.format(rate.minRate, currency: rate.currency))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Avg: " + CurrencyHelper.format(rate.averageRate, currency: rate.currency))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(CurrencyHelper.format(rate.maxRate, currency: rate.currency))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func calculateYourPosition(in width: Double) -> Double {
        let range = rate.maxRate - rate.minRate
        guard range > 0 else { return width * 0.5 }
        
        let clampedRate = max(rate.minRate * 0.5, min(yourRate, rate.maxRate * 1.5))
        let extendedMin = rate.minRate * 0.5
        let extendedMax = rate.maxRate * 1.5
        let extendedRange = extendedMax - extendedMin
        
        return width * (clampedRate - extendedMin) / extendedRange
    }
}

// MARK: - AddMarketRateSheet

struct AddMarketRateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    
    @State private var name = ""
    @State private var minRate: Double = 0
    @State private var maxRate: Double = 0
    @State private var averageRate: Double = 0
    @State private var currency = "USD"
    @State private var region = ""
    @State private var source = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Role Info") {
                    TextField("Role Name (e.g., iOS Developer)", text: $name)
                    TextField("Region (e.g., USA, Europe)", text: $region)
                    TextField("Source (e.g., Glassdoor)", text: $source)
                }
                
                Section("Rate Range") {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        TextField("0", value: $minRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Maximum")
                        Spacer()
                        TextField("0", value: $maxRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Average")
                        Spacer()
                        TextField("0", value: $averageRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Currency", selection: $currency) {
                        ForEach(Array(CurrencyHelper.availableCurrencies.keys.sorted()), id: \.self) { code in
                            Text("\(code) - \(CurrencyHelper.availableCurrencies[code] ?? code)")
                                .tag(code)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Preview
                if minRate > 0 && maxRate > 0 {
                    Section("Preview") {
                        Text("\(name.isEmpty ? "Role" : name)")
                            .font(.headline)
                        
                        Text("Range: \(CurrencyHelper.format(minRate, currency: currency)) - \(CurrencyHelper.format(maxRate, currency: currency))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Market Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || minRate <= 0 || maxRate <= 0)
                }
            }
            .onChange(of: minRate) { _, newValue in
                if averageRate == 0 && maxRate > 0 {
                    averageRate = (newValue + maxRate) / 2
                }
            }
            .onChange(of: maxRate) { _, newValue in
                if averageRate == 0 && minRate > 0 {
                    averageRate = (minRate + newValue) / 2
                }
            }
        }
    }
    
    private func save() {
        let rate = MarketRateData(
            name: name,
            minRate: minRate,
            maxRate: maxRate,
            averageRate: averageRate > 0 ? averageRate : (minRate + maxRate) / 2,
            currency: currency,
            region: region,
            source: source,
            notes: notes
        )
        dataController.saveMarketRate(rate)
    }
}

// MARK: - MarketRateDetailSheet

struct MarketRateDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let rate: MarketRateData
    
    var body: some View {
        NavigationStack {
            List {
                Section("Role") {
                    LabeledContent("Name", value: rate.name)
                    if !rate.region.isEmpty {
                        LabeledContent("Region", value: rate.region)
                    }
                    if !rate.source.isEmpty {
                        LabeledContent("Source", value: rate.source)
                    }
                }
                
                Section("Rate Range") {
                    LabeledContent("Minimum", value: CurrencyHelper.format(rate.minRate, currency: rate.currency))
                    LabeledContent("Maximum", value: CurrencyHelper.format(rate.maxRate, currency: rate.currency))
                    LabeledContent("Average", value: CurrencyHelper.format(rate.averageRate, currency: rate.currency))
                    LabeledContent("Range", value: rate.rateRange)
                }
                
                Section("Info") {
                    LabeledContent("Updated", value: rate.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                
                if !rate.notes.isEmpty {
                    Section("Notes") {
                        Text(rate.notes)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Market Rate Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


