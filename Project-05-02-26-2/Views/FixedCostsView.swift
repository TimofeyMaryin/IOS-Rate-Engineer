//
//  FixedCostsView.swift
//  Hourly Rate Engineer
//
//  Monthly fixed costs management
//

import SwiftUI

struct FixedCostsView: View {
    @Environment(DataController.self) var dataController
    @Binding var navigateToNext: Bool
    
    @State private var costs: [FixedCostData] = []
    @State private var showAddSheet = false
    @State private var editingItem: FixedCostData?
    
    private var currency: String {
        dataController.incomeTarget?.currency ?? "USD"
    }
    
    private var totalMonthlyCosts: Double {
        costs.reduce(0) { $0 + $1.amount }
    }
    
    private var costsByCategory: [(category: CostCategory, total: Double)] {
        var grouped: [CostCategory: Double] = [:]
        for cost in costs {
            let category = CostCategory(rawValue: cost.category) ?? .other
            grouped[category, default: 0] += cost.amount
        }
        return grouped.map { ($0.key, $0.value) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.Colors.chartOrange)
                    
                    Text("Fixed Costs")
                        .font(AppTheme.Typography.title1)
                        .foregroundColor(AppTheme.Colors.graphite)
                    
                    Text("Track your monthly business expenses")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.graphiteLight)
                }
                .padding(.top, AppTheme.Spacing.lg)
                
                // Costs List
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    SectionHeader("Monthly Expenses", subtitle: "Add recurring business costs")
                    
                    if costs.isEmpty {
                        EmptyCostsView()
                    } else {
                        ForEach(costs) { item in
                            CostItemRow(
                                item: item,
                                currency: currency,
                                onEdit: {
                                    editingItem = item
                                },
                                onDelete: {
                                    withAnimation {
                                        costs.removeAll { $0.id == item.id }
                                    }
                                }
                            )
                        }
                    }
                    
                    AddItemButton(title: "Add Expense") {
                        showAddSheet = true
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                
                // Category Breakdown
                if !costsByCategory.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Costs by Category")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.graphite)
                        
                        ForEach(costsByCategory, id: \.category) { item in
                            CategoryBreakdownRow(
                                category: item.category,
                                amount: item.total,
                                percentage: item.total / totalMonthlyCosts,
                                currency: currency
                            )
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .fill(AppTheme.Colors.cardBackground)
                    )
                    .shadowSmall()
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // Summary Card
                if !costs.isEmpty {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Cost Summary")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.graphite)
                        
                        Divider()
                        
                        InfoRow(
                            icon: "calendar",
                            title: "Monthly Total",
                            value: CurrencyFormatter.format(totalMonthlyCosts, currency: currency),
                            valueColor: AppTheme.Colors.chartOrange
                        )
                        
                        InfoRow(
                            icon: "calendar.badge.clock",
                            title: "Annual Total",
                            value: CurrencyFormatter.format(totalMonthlyCosts * 12, currency: currency),
                            valueColor: AppTheme.Colors.primary
                        )
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .fill(AppTheme.Colors.cardBackground)
                    )
                    .shadowMedium()
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }
                
                // Info tip
                InfoTip("Include all recurring business expenses: workspace rent, internet, software subscriptions, insurance, etc.")
                    .padding(.horizontal, AppTheme.Spacing.lg)
                
                Spacer(minLength: AppTheme.Spacing.xxl)
                
                // Navigation buttons
                VStack(spacing: AppTheme.Spacing.sm) {
                    Button("Continue") {
                        saveAndContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    if costs.isEmpty {
                        Button("Skip for Now") {
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
        .sheet(isPresented: $showAddSheet) {
            AddCostSheet(currency: currency) { newItem in
                withAnimation {
                    costs.append(newItem)
                }
            }
        }
        .sheet(item: $editingItem) { item in
            EditCostSheet(item: item, currency: currency) { updatedItem in
                if let index = costs.firstIndex(where: { $0.id == item.id }) {
                    withAnimation {
                        costs[index] = updatedItem
                    }
                }
            }
        }
        .onAppear {
            loadExistingData()
        }
    }
    
    private func loadExistingData() {
        costs = dataController.fixedCosts
    }
    
    private func saveAndContinue() {
        dataController.saveFixedCosts(costs)
        navigateToNext = true
    }
}

// MARK: - Empty Costs View
struct EmptyCostsView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.Colors.divider)
            
            Text("No Expenses Added")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.graphiteLight)
            
            Text("Add your monthly business expenses like rent, internet, subscriptions, etc.")
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.graphiteLight)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.Colors.background)
        )
    }
}

// MARK: - Cost Item Row
struct CostItemRow: View {
    let item: FixedCostData
    let currency: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var category: CostCategory {
        CostCategory(rawValue: item.category) ?? .other
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: category.icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.chartOrange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxxs) {
                Text(item.name)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.graphite)
                
                Text(category.displayName)
                    .font(AppTheme.Typography.caption1)
                    .foregroundColor(AppTheme.Colors.graphiteLight)
            }
            
            Spacer()
            
            Text(CurrencyFormatter.format(item.amount, currency: currency))
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.chartOrange)
            
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
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

// MARK: - Category Breakdown Row
struct CategoryBreakdownRow: View {
    let category: CostCategory
    let amount: Double
    let percentage: Double
    let currency: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.chartOrange)
                
                Text(category.displayName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.graphite)
                
                Spacer()
                
                Text(CurrencyFormatter.format(amount, currency: currency))
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.graphite)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.Colors.divider)
                        .frame(height: 6)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    
                    Rectangle()
                        .fill(AppTheme.Colors.chartOrange)
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Add Cost Sheet
struct AddCostSheet: View {
    let currency: String
    let onSave: (FixedCostData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var amount: Double = 0
    @State private var selectedCategory: CostCategory = .other
    
    private var isValid: Bool {
        !name.isEmpty && amount > 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    TextInputField(
                        title: "Expense Name",
                        text: $name,
                        placeholder: "e.g., Internet Service"
                    )
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Category")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.graphiteLight)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppTheme.Spacing.sm) {
                            ForEach(CostCategory.allCases) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    
                    CurrencyInputField(
                        title: "Monthly Amount",
                        value: $amount,
                        currency: currency
                    )
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let item = FixedCostData(
                            name: name,
                            amount: amount,
                            category: selectedCategory.rawValue
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: CostCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                
                Text(category.displayName)
                    .font(AppTheme.Typography.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? .white : AppTheme.Colors.graphite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(isSelected ? AppTheme.Colors.chartOrange : AppTheme.Colors.background)
            )
        }
    }
}

// MARK: - Edit Cost Sheet
struct EditCostSheet: View {
    let item: FixedCostData
    let currency: String
    let onSave: (FixedCostData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var amount: Double
    @State private var selectedCategory: CostCategory
    
    init(item: FixedCostData, currency: String, onSave: @escaping (FixedCostData) -> Void) {
        self.item = item
        self.currency = currency
        self.onSave = onSave
        _name = State(initialValue: item.name)
        _amount = State(initialValue: item.amount)
        _selectedCategory = State(initialValue: CostCategory(rawValue: item.category) ?? .other)
    }
    
    private var isValid: Bool {
        !name.isEmpty && amount > 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    TextInputField(
                        title: "Expense Name",
                        text: $name,
                        placeholder: "e.g., Internet Service"
                    )
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Category")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.graphiteLight)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppTheme.Spacing.sm) {
                            ForEach(CostCategory.allCases) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    
                    CurrencyInputField(
                        title: "Monthly Amount",
                        value: $amount,
                        currency: currency
                    )
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updatedItem = item
                        updatedItem.name = name
                        updatedItem.amount = amount
                        updatedItem.category = selectedCategory.rawValue
                        onSave(updatedItem)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FixedCostsView(navigateToNext: .constant(false))
            .environment(DataController.shared)
    }
}
