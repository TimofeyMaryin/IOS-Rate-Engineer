//
//  CurrencyView.swift
//  Hourly Rate Engineer
//
//  Мульти-валютный режим с конвертацией
//

import SwiftUI

struct CurrencyView: View {
    @Environment(DataController.self) private var dataController
    @State private var showingAddRate = false
    @State private var amount: Double = 100
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "EUR"
    @State private var showingDeleteAlert = false
    @State private var rateToDelete: CurrencyRateData?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick converter
                    converterSection
                    
                    // Popular conversions
                    if !dataController.currencyRates.isEmpty {
                        quickConversionsSection
                    }
                    
                    // Saved rates
                    savedRatesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Currency")
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
                AddCurrencyRateSheet()
            }
            .alert("Delete Currency Rate", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let rate = rateToDelete {
                        dataController.deleteCurrencyRate(rate)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this currency rate?")
            }
        }
    }
    
    // MARK: - Converter Section
    private var converterSection: some View {
        VStack(spacing: 16) {
            Text("Currency Converter")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Amount input
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    TextField("0", value: $amount, format: .number)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                    
                    Picker("", selection: $fromCurrency) {
                        ForEach(Array(CurrencyHelper.availableCurrencies.keys.sorted()), id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
            }
            
            // Swap button
            Button {
                let temp = fromCurrency
                fromCurrency = toCurrency
                toCurrency = temp
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
            }
            
            // Result
            VStack(alignment: .leading, spacing: 8) {
                Text("Converted Amount")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(CurrencyHelper.format(convertedAmount, currency: toCurrency))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Picker("", selection: $toCurrency) {
                        ForEach(Array(CurrencyHelper.availableCurrencies.keys.sorted()), id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
            }
            
            // Rate info
            if let rate = findRate(from: fromCurrency, to: toCurrency) {
                HStack {
                    Text("1 \(fromCurrency) = \(String(format: "%.4f", rate)) \(toCurrency)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Custom rate")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }
            } else {
                Text("Add a custom rate to enable conversion")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var convertedAmount: Double {
        dataController.convert(amount, from: fromCurrency, to: toCurrency)
    }
    
    private func findRate(from: String, to: String) -> Double? {
        if from == to { return 1.0 }
        
        if let direct = dataController.currencyRates.first(where: {
            $0.fromCurrency == from && $0.toCurrency == to
        }) {
            return direct.rate
        }
        
        if let inverse = dataController.currencyRates.first(where: {
            $0.fromCurrency == to && $0.toCurrency == from
        }) {
            return 1.0 / inverse.rate
        }
        
        return nil
    }
    
    // MARK: - Quick Conversions Section
    private var quickConversionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Conversions")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(dataController.currencyRates.prefix(4)) { rate in
                    QuickConversionCard(
                        amount: amount,
                        rate: rate
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Saved Rates Section
    private var savedRatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Exchange Rates")
                    .font(.headline)
                Spacer()
                Text("\(dataController.currencyRates.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if dataController.currencyRates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dollarsign.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    Text("No saved rates")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add your custom exchange rates for offline conversion")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingAddRate = true
                    } label: {
                        Label("Add Rate", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(dataController.currencyRates) { rate in
                        CurrencyRateRow(rate: rate)
                            .contextMenu {
                                Button {
                                    fromCurrency = rate.fromCurrency
                                    toCurrency = rate.toCurrency
                                } label: {
                                    Label("Use in Converter", systemImage: "arrow.left.arrow.right")
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

// MARK: - QuickConversionCard

struct QuickConversionCard: View {
    let amount: Double
    let rate: CurrencyRateData
    
    var convertedAmount: Double {
        amount * rate.rate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rate.fromCurrency)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text(rate.toCurrency)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            Text(CurrencyHelper.format(convertedAmount, currency: rate.toCurrency))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - CurrencyRateRow

struct CurrencyRateRow: View {
    let rate: CurrencyRateData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(rate.fromCurrency)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(rate.toCurrency)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
                
                Text("Updated: \(rate.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.4f", rate.rate))
                    .font(.headline)
                
                Text("1 \(rate.fromCurrency)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - AddCurrencyRateSheet

struct AddCurrencyRateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "EUR"
    @State private var rate: Double = 1.0
    
    // Popular pairs for quick selection
    let popularPairs = [
        ("USD", "EUR"),
        ("USD", "GBP"),
        ("EUR", "GBP"),
        ("USD", "JPY"),
        ("USD", "RUB"),
        ("EUR", "RUB"),
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Currency Pair") {
                    Picker("From", selection: $fromCurrency) {
                        ForEach(Array(CurrencyHelper.availableCurrencies.keys.sorted()), id: \.self) { code in
                            HStack {
                                Text(code)
                                Text("-")
                                    .foregroundStyle(.secondary)
                                Text(CurrencyHelper.availableCurrencies[code] ?? "")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(code)
                        }
                    }
                    
                    Picker("To", selection: $toCurrency) {
                        ForEach(Array(CurrencyHelper.availableCurrencies.keys.sorted()), id: \.self) { code in
                            HStack {
                                Text(code)
                                Text("-")
                                    .foregroundStyle(.secondary)
                                Text(CurrencyHelper.availableCurrencies[code] ?? "")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(code)
                        }
                    }
                }
                
                Section("Popular Pairs") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(popularPairs, id: \.0) { pair in
                            Button {
                                fromCurrency = pair.0
                                toCurrency = pair.1
                            } label: {
                                HStack {
                                    Text(pair.0)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                    Text(pair.1)
                                }
                                .font(.caption.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    (fromCurrency == pair.0 && toCurrency == pair.1) ?
                                    Color.accentColor.opacity(0.2) : Color(.tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                
                Section("Exchange Rate") {
                    HStack {
                        Text("1 \(fromCurrency) =")
                            .foregroundStyle(.secondary)
                        
                        TextField("1.0", value: $rate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        
                        Text(toCurrency)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("100 \(fromCurrency)")
                            Spacer()
                            Text("= \(String(format: "%.2f", 100 * rate)) \(toCurrency)")
                                .foregroundStyle(.green)
                        }
                        
                        HStack {
                            Text("1,000 \(fromCurrency)")
                            Spacer()
                            Text("= \(String(format: "%.2f", 1000 * rate)) \(toCurrency)")
                                .foregroundStyle(.green)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Inverse")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("1 \(toCurrency) = \(String(format: "%.4f", 1.0 / rate)) \(fromCurrency)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Exchange Rate")
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
                    .disabled(fromCurrency == toCurrency || rate <= 0)
                }
            }
        }
    }
    
    private func save() {
        let currencyRate = CurrencyRateData(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate
        )
        dataController.saveCurrencyRate(currencyRate)
    }
}
