//
//  GoalsView.swift
//  Hourly Rate Engineer
//
//  Финансовые цели с отслеживанием прогресса
//

import SwiftUI
import Charts

struct GoalsView: View {
    @Environment(DataController.self) private var dataController
    @State private var showingAddGoal = false
    @State private var selectedGoal: GoalData?
    @State private var selectedFilter: GoalFilter = .active
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: GoalData?
    
    enum GoalFilter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"
    }
    
    var filteredGoals: [GoalData] {
        switch selectedFilter {
        case .active:
            return dataController.goals.filter { !$0.isCompleted }
        case .completed:
            return dataController.goals.filter { $0.isCompleted }
        case .all:
            return dataController.goals
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter
                filterSelector
                    .padding()
                
                if filteredGoals.isEmpty {
                    ContentUnavailableView(
                        "No Goals",
                        systemImage: "target",
                        description: Text("Set your first financial goal to track your progress")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Overview
                            if selectedFilter == .active {
                                goalsOverview
                            }
                            
                            // Goals list
                            LazyVStack(spacing: 12) {
                                ForEach(filteredGoals) { goal in
                                    GoalCard(goal: goal)
                                        .onTapGesture {
                                            selectedGoal = goal
                                        }
                                        .contextMenu {
                                            Button {
                                                selectedGoal = goal
                                            } label: {
                                                Label("View Details", systemImage: "eye")
                                            }
                                            
                                            if !goal.isCompleted {
                                                Button {
                                                    markGoalComplete(goal)
                                                } label: {
                                                    Label("Mark Complete", systemImage: "checkmark.circle")
                                                }
                                            }
                                            
                                            Button(role: .destructive) {
                                                goalToDelete = goal
                                                showingDeleteAlert = true
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalSheet()
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
            }
            .alert("Delete Goal", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let goal = goalToDelete {
                        dataController.deleteGoal(goal)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this goal?")
            }
        }
    }
    
    private var filterSelector: some View {
        HStack(spacing: 0) {
            ForEach(GoalFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedFilter == filter ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedFilter == filter {
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
    
    private var goalsOverview: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                OverviewCard(
                    title: "Active Goals",
                    value: "\(dataController.activeGoals().count)",
                    icon: "target",
                    color: .blue
                )
                
                OverviewCard(
                    title: "Avg Progress",
                    value: String(format: "%.0f%%", averageProgress * 100),
                    icon: "chart.pie.fill",
                    color: .green
                )
            }
            
            // Progress ring chart
            if !filteredGoals.isEmpty {
                progressChart
            }
        }
    }
    
    private var averageProgress: Double {
        let activeGoals = dataController.activeGoals()
        guard !activeGoals.isEmpty else { return 0 }
        return activeGoals.map(\.progress).reduce(0, +) / Double(activeGoals.count)
    }
    
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals Progress")
                .font(.headline)
            
            Chart(filteredGoals.prefix(5)) { goal in
                BarMark(
                    x: .value("Progress", goal.progress),
                    y: .value("Goal", goal.name)
                )
                .foregroundStyle(goal.color.gradient)
                .annotation(position: .trailing) {
                    Text(String(format: "%.0f%%", goal.progress * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: CGFloat(min(filteredGoals.count, 5)) * 50)
            .chartXScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(values: [0, 0.25, 0.5, 0.75, 1]) { value in
                    AxisGridLine()
                    AxisValueLabel(format: FloatingPointFormatStyle<Double>.Percent())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func markGoalComplete(_ goal: GoalData) {
        var updated = goal
        updated.isCompleted = true
        updated.currentAmount = updated.targetAmount
        dataController.saveGoal(updated)
    }
}

// MARK: - OverviewCard

struct OverviewCard: View {
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
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - GoalCard

struct GoalCard: View {
    let goal: GoalData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goal.categoryIcon)
                    .font(.title2)
                    .foregroundStyle(goal.color)
                    .frame(width: 44, height: 44)
                    .background(goal.color.opacity(0.15), in: Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.headline)
                    
                    Text(GoalData.categories[goal.category] ?? goal.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(goal.color.gradient)
                            .frame(width: geometry.size.width * goal.progress, height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text(CurrencyHelper.format(goal.currentAmount, currency: goal.currency))
                        .font(.subheadline)
                    
                    Text("of")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyHelper.format(goal.targetAmount, currency: goal.currency))
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", goal.progress * 100))
                        .font(.subheadline.bold())
                        .foregroundStyle(goal.color)
                }
            }
            
            // Deadline info
            if let deadline = goal.deadline {
                Divider()
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    
                    Text("Deadline: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if let days = goal.daysRemaining {
                        Text(days > 0 ? "\(days) days left" : "Overdue")
                            .font(.caption.bold())
                            .foregroundStyle(days > 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - AddGoalSheet

struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    
    @State private var name = ""
    @State private var targetAmount: Double = 0
    @State private var currentAmount: Double = 0
    @State private var currency = "USD"
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 3600) // +30 дней
    @State private var category = "savings"
    @State private var notes = ""
    @State private var selectedColor = "34C759"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Info") {
                    TextField("Goal Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(Array(GoalData.categories.keys.sorted()), id: \.self) { key in
                            Text(GoalData.categories[key] ?? key).tag(key)
                        }
                    }
                }
                
                Section("Amount") {
                    HStack {
                        Text("Target Amount")
                        Spacer()
                        TextField("0", value: $targetAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Current Progress")
                        Spacer()
                        TextField("0", value: $currentAmount, format: .number)
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
                
                Section("Deadline") {
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                        
                        if targetAmount > currentAmount {
                            let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 1
                            let dailyAmount = (targetAmount - currentAmount) / Double(max(days, 1))
                            
                            HStack {
                                Text("Required daily")
                                Spacer()
                                Text(CurrencyHelper.format(dailyAmount, currency: currency))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(GoalData.goalColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if targetAmount > 0 && currentAmount >= 0 {
                    Section("Preview") {
                        let progress = min(currentAmount / targetAmount, 1.0)
                        
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text(String(format: "%.1f%%", progress * 100))
                                .foregroundStyle(progress >= 1 ? .green : .primary)
                        }
                        
                        HStack {
                            Text("Remaining")
                            Spacer()
                            Text(CurrencyHelper.format(max(0, targetAmount - currentAmount), currency: currency))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || targetAmount <= 0)
                }
            }
        }
    }
    
    private func save() {
        let goal = GoalData(
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            currency: currency,
            deadline: hasDeadline ? deadline : nil,
            category: category,
            isCompleted: currentAmount >= targetAmount,
            notes: notes,
            colorHex: selectedColor
        )
        dataController.saveGoal(goal)
    }
}

// MARK: - GoalDetailView

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    @State var goal: GoalData
    
    @State private var addAmount: Double = 0
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    goalHeader
                    
                    // Progress ring
                    progressRing
                    
                    // Quick add
                    if !goal.isCompleted {
                        quickAddSection
                    }
                    
                    // Details
                    detailsSection
                    
                    // Milestones
                    milestonesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Text("Edit")
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditGoalSheet(goal: $goal)
            }
        }
    }
    
    private var goalHeader: some View {
        HStack {
            Image(systemName: goal.categoryIcon)
                .font(.title)
                .foregroundStyle(goal.color)
                .frame(width: 56, height: 56)
                .background(goal.color.opacity(0.15), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.title3.bold())
                
                Text(GoalData.categories[goal.category] ?? goal.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if goal.isCompleted {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("Complete!")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var progressRing: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: goal.progress)
                    .stroke(goal.color.gradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: goal.progress)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.1f%%", goal.progress * 100))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(goal.color)
                    
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            
            HStack(spacing: 32) {
                VStack {
                    Text(CurrencyHelper.format(goal.currentAmount, currency: goal.currency))
                        .font(.headline)
                    Text("Saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text(CurrencyHelper.format(goal.remainingAmount, currency: goal.currency))
                        .font(.headline)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Progress")
                .font(.headline)
            
            HStack {
                TextField("Amount", value: $addAmount, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    addProgress()
                } label: {
                    Text("Add")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(goal.color.gradient, in: Capsule())
                }
                .disabled(addAmount <= 0)
            }
            
            // Quick buttons
            HStack {
                ForEach([10.0, 50.0, 100.0, 500.0], id: \.self) { amount in
                    Button {
                        addAmount = amount
                    } label: {
                        Text("+\(Int(amount))")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            VStack(spacing: 0) {
                DetailRow(label: "Target", value: CurrencyHelper.format(goal.targetAmount, currency: goal.currency))
                Divider().padding(.leading)
                DetailRow(label: "Current", value: CurrencyHelper.format(goal.currentAmount, currency: goal.currency))
                Divider().padding(.leading)
                DetailRow(label: "Created", value: goal.createdAt.formatted(date: .abbreviated, time: .omitted))
                
                if let deadline = goal.deadline {
                    Divider().padding(.leading)
                    DetailRow(label: "Deadline", value: deadline.formatted(date: .abbreviated, time: .omitted))
                    
                    if let days = goal.daysRemaining, !goal.isCompleted {
                        Divider().padding(.leading)
                        DetailRow(
                            label: "Days Left",
                            value: days > 0 ? "\(days)" : "Overdue",
                            valueColor: days > 0 ? .green : .red
                        )
                        
                        if let daily = goal.requiredDailyAmount, daily > 0 {
                            Divider().padding(.leading)
                            DetailRow(
                                label: "Daily Target",
                                value: CurrencyHelper.format(daily, currency: goal.currency),
                                valueColor: .orange
                            )
                        }
                    }
                }
            }
            
            if !goal.notes.isEmpty {
                Text(goal.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { milestone in
                    MilestoneRow(
                        milestone: milestone,
                        currentProgress: goal.progress,
                        targetAmount: goal.targetAmount,
                        currency: goal.currency,
                        color: goal.color
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func addProgress() {
        guard addAmount > 0 else { return }
        var updated = goal
        updated.currentAmount += addAmount
        if updated.currentAmount >= updated.targetAmount {
            updated.isCompleted = true
        }
        dataController.saveGoal(updated)
        goal = updated
        addAmount = 0
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 10)
    }
}

struct MilestoneRow: View {
    let milestone: Double
    let currentProgress: Double
    let targetAmount: Double
    let currency: String
    let color: Color
    
    var isReached: Bool {
        currentProgress >= milestone
    }
    
    var body: some View {
        HStack {
            Image(systemName: isReached ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isReached ? .green : .secondary)
            
            Text(String(format: "%.0f%%", milestone * 100))
                .font(.subheadline.bold())
                .foregroundStyle(isReached ? .primary : .secondary)
            
            Spacer()
            
            Text(CurrencyHelper.format(targetAmount * milestone, currency: currency))
                .font(.subheadline)
                .foregroundStyle(isReached ? color : .secondary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - EditGoalSheet

struct EditGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    @Binding var goal: GoalData
    
    @State private var name: String = ""
    @State private var targetAmount: Double = 0
    @State private var currentAmount: Double = 0
    @State private var currency: String = "USD"
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date()
    @State private var category: String = "savings"
    @State private var notes: String = ""
    @State private var selectedColor: String = "34C759"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Info") {
                    TextField("Goal Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(Array(GoalData.categories.keys.sorted()), id: \.self) { key in
                            Text(GoalData.categories[key] ?? key).tag(key)
                        }
                    }
                }
                
                Section("Amount") {
                    HStack {
                        Text("Target Amount")
                        Spacer()
                        TextField("0", value: $targetAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Current Progress")
                        Spacer()
                        TextField("0", value: $currentAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Currency", selection: $currency) {
                        ForEach(Array(CurrencyHelper.availableCurrencies.keys.sorted()), id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }
                
                Section("Deadline") {
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(GoalData.goalColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Goal")
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
                    .disabled(name.isEmpty || targetAmount <= 0)
                }
            }
            .onAppear {
                name = goal.name
                targetAmount = goal.targetAmount
                currentAmount = goal.currentAmount
                currency = goal.currency
                hasDeadline = goal.deadline != nil
                deadline = goal.deadline ?? Date()
                category = goal.category
                notes = goal.notes
                selectedColor = goal.colorHex
            }
        }
    }
    
    private func save() {
        var updated = goal
        updated.name = name
        updated.targetAmount = targetAmount
        updated.currentAmount = currentAmount
        updated.currency = currency
        updated.deadline = hasDeadline ? deadline : nil
        updated.category = category
        updated.notes = notes
        updated.colorHex = selectedColor
        updated.isCompleted = currentAmount >= targetAmount
        
        dataController.saveGoal(updated)
        goal = updated
    }
}

