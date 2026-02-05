//
//  EquipmentView.swift
//  Hourly Rate Engineer
//
//  Professional equipment management with iOS 18+ design
//  Animated lists and Material effects
//

import SwiftUI

struct EquipmentView: View {
    @Environment(DataController.self) var dataController
    @Binding var navigateToNext: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var equipment: [EquipmentData] = []
    @State private var showAddSheet = false
    @State private var editingItem: EquipmentData?
    @State private var isVisible = false
    
    private var currency: String {
        dataController.incomeTarget?.currency ?? "USD"
    }
    
    private var totalMonthlyAmortization: Double {
        equipment.reduce(0) { $0 + $1.monthlyAmortization }
    }
    
    private var totalAssetValue: Double {
        equipment.reduce(0) { $0 + $1.cost }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                headerSection
                
                // Equipment List
                equipmentListSection
                
                // Summary Card
                if !equipment.isEmpty {
                    summarySection
                }
                
                // Info tip
                InfoTip("Amortization spreads the cost of equipment over its useful life. This ensures your hourly rate covers equipment replacement.", icon: "lightbulb.fill")
                
                Spacer(minLength: AppTheme.Spacing.xxl)
                
                // Navigation buttons
                navigationButtons
                
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
        .sheet(isPresented: $showAddSheet) {
            AddEquipmentSheet(currency: currency) { newItem in
                withAnimation(AppTheme.Animation.bouncy) {
                    equipment.append(newItem)
                }
                AppTheme.Haptics.success()
            }
        }
        .sheet(item: $editingItem) { item in
            EditEquipmentSheet(item: item, currency: currency) { updatedItem in
                if let index = equipment.firstIndex(where: { $0.id == item.id }) {
                    withAnimation(AppTheme.Animation.smooth) {
                        equipment[index] = updatedItem
                    }
                }
            }
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
                                AppTheme.Colors.chartPurple.opacity(0.2),
                                AppTheme.Colors.chartPurple.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.Colors.chartPurple)
                    .symbolEffect(.bounce, value: isVisible)
            }
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Equipment & Assets")
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Text("Track your tools and their depreciation")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
    
    // MARK: - Equipment List Section
    private var equipmentListSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader("Your Equipment", subtitle: "Add all work-related equipment", icon: "cube.box.fill")
            
            if equipment.isEmpty {
                EmptyEquipmentView()
            } else {
                ForEach(Array(equipment.enumerated()), id: \.element.id) { index, item in
                    EquipmentItemRow(
                        item: item,
                        currency: currency,
                        onEdit: {
                            editingItem = item
                        },
                        onDelete: {
                            withAnimation(AppTheme.Animation.smooth) {
                                equipment.removeAll { $0.id == item.id }
                            }
                            AppTheme.Haptics.light()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: 20)),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }
            
            AddItemButton(title: "Add Equipment", icon: "plus.circle.fill") {
                showAddSheet = true
            }
        }
        .opacity(isVisible ? 1 : 0)
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Amortization Summary")
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Spacer()
                
                // Item count badge
                Text("\(equipment.count) item\(equipment.count == 1 ? "" : "s")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.chartPurple)
                    .padding(.horizontal, AppTheme.Spacing.xs)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(AppTheme.Colors.chartPurple.opacity(0.12))
                    }
            }
            
            Divider()
            
            InfoRow(
                icon: "cube.box.fill",
                title: "Total Asset Value",
                value: CurrencyFormatter.format(totalAssetValue, currency: currency, showDecimals: false),
                iconColor: AppTheme.Colors.chartBlue
            )
            
            InfoRow(
                icon: "calendar",
                title: "Monthly Amortization",
                value: CurrencyFormatter.format(totalMonthlyAmortization, currency: currency),
                valueColor: AppTheme.Colors.chartPurple,
                iconColor: AppTheme.Colors.chartPurple
            )
            
            InfoRow(
                icon: "calendar.badge.clock",
                title: "Annual Amortization",
                value: CurrencyFormatter.format(totalMonthlyAmortization * 12, currency: currency),
                valueColor: AppTheme.Colors.primary,
                iconColor: AppTheme.Colors.primary
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
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
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
            
            if equipment.isEmpty {
                Button {
                    AppTheme.Haptics.light()
                    saveAndContinue()
                } label: {
                    Text("Skip for Now")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
        }
    }
    
    // MARK: - Functions
    private func loadExistingData() {
        equipment = dataController.equipment
    }
    
    private func saveAndContinue() {
        dataController.saveEquipment(equipment)
        navigateToNext = true
    }
}

// MARK: - Empty Equipment View (Enhanced)
struct EmptyEquipmentView: View {
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.divider.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "shippingbox")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), value: isVisible)
            }
            
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("No Equipment Added")
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.graphite)
                
                Text("Add your work equipment like computers, monitors, cameras, etc.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(AppTheme.Colors.tertiaryBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .strokeBorder(AppTheme.Colors.divider.opacity(0.3), lineWidth: 0.5)
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Equipment Item Row (Enhanced)
struct EquipmentItemRow: View {
    let item: EquipmentData
    let currency: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showActions = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Icon
            Image(systemName: iconForEquipment(item.name))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.chartPurple)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(AppTheme.Colors.chartPurple.opacity(0.12))
                }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.graphite)
                    .lineLimit(1)
                
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(CurrencyFormatter.format(item.cost, currency: currency, showDecimals: false))
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.divider)
                    
                    Text("\(item.lifespan) year\(item.lifespan == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                }
            }
            
            Spacer()
            
            // Monthly cost
            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(item.monthlyAmortization, currency: currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.chartPurple)
                    .monospacedDigit()
                
                Text("/month")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.graphiteLight)
            }
            
            // Actions menu
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
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.Colors.graphiteLight.opacity(0.6))
                    .symbolEffect(.bounce, value: showActions)
            }
            .onTapGesture {
                showActions.toggle()
                AppTheme.Haptics.selection()
            }
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .strokeBorder(AppTheme.Colors.divider.opacity(0.3), lineWidth: 0.5)
        }
        .shadowSmall()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(CurrencyFormatter.format(item.monthlyAmortization, currency: currency)) per month")
    }
    
    private func iconForEquipment(_ name: String) -> String {
        let lowercasedName = name.lowercased()
        if lowercasedName.contains("mac") || lowercasedName.contains("laptop") || lowercasedName.contains("computer") {
            return "laptopcomputer"
        } else if lowercasedName.contains("monitor") || lowercasedName.contains("display") {
            return "display"
        } else if lowercasedName.contains("phone") || lowercasedName.contains("iphone") {
            return "iphone"
        } else if lowercasedName.contains("ipad") || lowercasedName.contains("tablet") {
            return "ipad"
        } else if lowercasedName.contains("camera") {
            return "camera.fill"
        } else if lowercasedName.contains("keyboard") {
            return "keyboard.fill"
        } else if lowercasedName.contains("mouse") {
            return "computermouse.fill"
        } else if lowercasedName.contains("headphone") || lowercasedName.contains("airpod") {
            return "headphones"
        } else if lowercasedName.contains("desk") || lowercasedName.contains("chair") {
            return "chair.fill"
        } else {
            return "cube.box.fill"
        }
    }
}

// MARK: - Add Equipment Sheet (Enhanced)
struct AddEquipmentSheet: View {
    let currency: String
    let onSave: (EquipmentData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var cost: Double = 0
    @State private var lifespan: Int = 3
    
    private var isValid: Bool {
        !name.isEmpty && cost > 0 && lifespan > 0
    }
    
    private var monthlyAmortization: Double {
        guard cost > 0 && lifespan > 0 else { return 0 }
        return cost / (Double(lifespan) * 12)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Preview card
                    if !name.isEmpty || cost > 0 {
                        previewCard
                    }
                    
                    TextInputField(
                        title: "Equipment Name",
                        text: $name,
                        placeholder: "e.g., MacBook Pro",
                        icon: "cube.box"
                    )
                    
                    CurrencyInputField(
                        title: "Purchase Cost",
                        value: $cost,
                        currency: currency
                    )
                    
                    NumberInputField(
                        title: "Expected Lifespan",
                        value: $lifespan,
                        range: 1...10,
                        suffix: "years"
                    )
                    
                    // Monthly amortization display
                    if cost > 0 && lifespan > 0 {
                        amortizationDisplay
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background {
                AppTheme.Colors.background
                    .ignoresSafeArea()
            }
            .navigationTitle("Add Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let item = EquipmentData(
                            name: name,
                            cost: cost,
                            lifespan: Int16(lifespan)
                        )
                        onSave(item)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var previewCard: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "cube.box.fill")
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.Colors.chartPurple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Equipment Name" : name)
                    .font(.headline)
                    .foregroundStyle(name.isEmpty ? AppTheme.Colors.graphiteLight : AppTheme.Colors.graphite)
                
                if cost > 0 {
                    Text("\(CurrencyFormatter.format(cost, currency: currency, showDecimals: false)) • \(lifespan) year\(lifespan == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Colors.graphiteLight)
                }
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.chartPurple.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .strokeBorder(AppTheme.Colors.chartPurple.opacity(0.2), lineWidth: 1)
        }
    }
    
    private var amortizationDisplay: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("Monthly Amortization")
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.graphiteLight)
            
            Text(CurrencyFormatter.format(monthlyAmortization, currency: currency))
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.Colors.chartPurple)
                .contentTransition(.numericText())
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.chartPurple.opacity(0.15),
                            AppTheme.Colors.chartPurple.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Edit Equipment Sheet
struct EditEquipmentSheet: View {
    let item: EquipmentData
    let currency: String
    let onSave: (EquipmentData) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var cost: Double
    @State private var lifespan: Int
    
    init(item: EquipmentData, currency: String, onSave: @escaping (EquipmentData) -> Void) {
        self.item = item
        self.currency = currency
        self.onSave = onSave
        _name = State(initialValue: item.name)
        _cost = State(initialValue: item.cost)
        _lifespan = State(initialValue: Int(item.lifespan))
    }
    
    private var isValid: Bool {
        !name.isEmpty && cost > 0 && lifespan > 0
    }
    
    private var monthlyAmortization: Double {
        guard cost > 0 && lifespan > 0 else { return 0 }
        return cost / (Double(lifespan) * 12)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    TextInputField(
                        title: "Equipment Name",
                        text: $name,
                        placeholder: "e.g., MacBook Pro",
                        icon: "cube.box"
                    )
                    
                    CurrencyInputField(
                        title: "Purchase Cost",
                        value: $cost,
                        currency: currency
                    )
                    
                    NumberInputField(
                        title: "Expected Lifespan",
                        value: $lifespan,
                        range: 1...10,
                        suffix: "years"
                    )
                    
                    if cost > 0 && lifespan > 0 {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("Monthly Amortization")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.Colors.graphiteLight)
                            
                            Text(CurrencyFormatter.format(monthlyAmortization, currency: currency))
                                .font(.system(.title, design: .rounded).weight(.bold))
                                .foregroundStyle(AppTheme.Colors.chartPurple)
                                .contentTransition(.numericText())
                        }
                        .padding(AppTheme.Spacing.lg)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                .fill(AppTheme.Colors.chartPurple.opacity(0.1))
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background {
                AppTheme.Colors.background
                    .ignoresSafeArea()
            }
            .navigationTitle("Edit Equipment")
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
                        updatedItem.cost = cost
                        updatedItem.lifespan = Int16(lifespan)
                        onSave(updatedItem)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EquipmentView(navigateToNext: .constant(false))
            .environment(DataController.shared)
    }
}
