//
//  ProjectsView.swift
//  Hourly Rate Engineer
//
//  Калькулятор проектов с таймером
//

import SwiftUI
import Charts

struct ProjectsView: View {
    @Environment(DataController.self) private var dataController
    @State private var showingAddProject = false
    @State private var selectedProject: ProjectData?
    @State private var selectedTab: ProjectTab = .active
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: ProjectData?
    
    enum ProjectTab: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"
    }
    
    var filteredProjects: [ProjectData] {
        switch selectedTab {
        case .active:
            return dataController.projects.filter { $0.status == "active" || $0.status == "paused" }
        case .completed:
            return dataController.projects.filter { $0.status == "completed" }
        case .all:
            return dataController.projects
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                    .padding()
                
                if filteredProjects.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "folder.badge.plus",
                        description: Text("Add your first project to start tracking time")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Statistics
                            if selectedTab == .active {
                                activeProjectsStats
                            }
                            
                            ForEach(filteredProjects) { project in
                                ProjectCard(project: project)
                                    .onTapGesture {
                                        selectedProject = project
                                    }
                                    .contextMenu {
                                        Button {
                                            selectedProject = project
                                        } label: {
                                            Label("View Details", systemImage: "eye")
                                        }
                                        
                                        Button(role: .destructive) {
                                            projectToDelete = project
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddProject = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectSheet()
            }
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
            .alert("Delete Project", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        dataController.deleteProject(project)
                    }
                }
            } message: {
                Text("This will also delete all time entries for this project.")
            }
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProjectTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTab == tab {
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
    
    private var activeProjectsStats: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Active",
                value: "\(dataController.activeProjects().count)",
                icon: "play.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Total Hours",
                value: String(format: "%.1f", totalActiveHours),
                icon: "clock.fill",
                color: .blue
            )
            
            StatCard(
                title: "Earnings",
                value: CurrencyHelper.format(totalActiveEarnings, currency: "USD"),
                icon: "dollarsign.circle.fill",
                color: .orange
            )
        }
    }
    
    private var totalActiveHours: Double {
        dataController.activeProjects().reduce(0) { sum, project in
            sum + dataController.totalHoursForProject(project.id)
        }
    }
    
    private var totalActiveEarnings: Double {
        dataController.activeProjects().reduce(0) { sum, project in
            sum + dataController.totalEarningsForProject(project)
        }
    }
}

// MARK: - ProjectCard

struct ProjectCard: View {
    @Environment(DataController.self) private var dataController
    let project: ProjectData
    
    var totalHours: Double {
        dataController.totalHoursForProject(project.id)
    }
    
    var totalEarnings: Double {
        dataController.totalEarningsForProject(project)
    }
    
    var progress: Double {
        guard project.estimatedHours > 0 else { return 0 }
        return min(totalHours / project.estimatedHours, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(project.color)
                    .frame(width: 12, height: 12)
                
                Text(project.name)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: project.statusIcon)
                    .foregroundStyle(project.statusColor)
            }
            
            if !project.clientName.isEmpty {
                Text(project.clientName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Progress bar
            if project.estimatedHours > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(project.color.gradient)
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text(String(format: "%.1f / %.1f hrs", totalHours, project.estimatedHours))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.caption.bold())
                            .foregroundStyle(project.color)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Label(CurrencyHelper.format(project.hourlyRate, currency: project.currency) + "/hr", systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Total: " + CurrencyHelper.format(totalEarnings, currency: project.currency))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - AddProjectSheet

struct AddProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    
    @State private var name = ""
    @State private var clientName = ""
    @State private var hourlyRate: Double = 0
    @State private var estimatedHours: Double = 0
    @State private var currency = "USD"
    @State private var notes = ""
    @State private var selectedColor = "007AFF"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Info") {
                    TextField("Project Name", text: $name)
                    TextField("Client Name", text: $clientName)
                }
                
                Section("Billing") {
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("0", value: $hourlyRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Estimated Hours")
                        Spacer()
                        TextField("0", value: $estimatedHours, format: .number)
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
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(ProjectData.projectColors, id: \.self) { color in
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
                
                if hourlyRate > 0 && estimatedHours > 0 {
                    Section("Estimated Total") {
                        Text(CurrencyHelper.format(hourlyRate * estimatedHours, currency: currency))
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("New Project")
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
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let project = ProjectData(
            name: name,
            clientName: clientName,
            hourlyRate: hourlyRate,
            estimatedHours: estimatedHours,
            currency: currency,
            notes: notes,
            colorHex: selectedColor
        )
        dataController.saveProject(project)
    }
}

// MARK: - ProjectDetailView

struct ProjectDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    @State var project: ProjectData
    
    @State private var showingAddTimeEntry = false
    @State private var quickHours: Double = 0
    @State private var quickNotes = ""
    
    var timeEntries: [TimeEntryData] {
        dataController.timeEntriesForProject(project.id).sorted { $0.startTime > $1.startTime }
    }
    
    var totalHours: Double {
        dataController.totalHoursForProject(project.id)
    }
    
    var totalEarnings: Double {
        dataController.totalEarningsForProject(project)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Project header
                    projectHeader
                    
                    // Quick add hours section
                    quickAddSection
                    
                    // Statistics
                    statsSection
                    
                    // Time entries chart
                    if !timeEntries.isEmpty {
                        timeEntriesChart
                    }
                    
                    // Time entries list
                    timeEntriesList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddTimeEntry = true
                        } label: {
                            Label("Add Detailed Entry", systemImage: "plus")
                        }
                        
                        Divider()
                        
                        if project.status != "completed" {
                            Button {
                                completeProject()
                            } label: {
                                Label("Mark Complete", systemImage: "checkmark.circle")
                            }
                        }
                        
                        if project.status == "active" {
                            Button {
                                pauseProject()
                            } label: {
                                Label("Pause Project", systemImage: "pause.circle")
                            }
                        } else if project.status == "paused" {
                            Button {
                                resumeProject()
                            } label: {
                                Label("Resume Project", systemImage: "play.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddTimeEntry) {
                AddTimeEntrySheet(projectId: project.id, projectRate: project.hourlyRate)
            }
        }
    }
    
    // MARK: - Project Header
    private var projectHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(project.color)
                    .frame(width: 16, height: 16)
                
                Text(project.name)
                    .font(.title2.bold())
                
                Spacer()
                
                Text(project.status.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(project.statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(project.statusColor.opacity(0.15), in: Capsule())
            }
            
            if !project.clientName.isEmpty {
                HStack {
                    Image(systemName: "person")
                        .foregroundStyle(.secondary)
                    Text(project.clientName)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundStyle(.secondary)
                Text(CurrencyHelper.format(project.hourlyRate, currency: project.currency) + "/hr")
                    .foregroundStyle(.secondary)
                Spacer()
                
                if project.estimatedHours > 0 {
                    Text(String(format: "Est: %.0f hrs", project.estimatedHours))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Quick Add Section
    private var quickAddSection: some View {
        VStack(spacing: 16) {
            Text("Log Hours")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Hours input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("0", value: $quickHours, format: .number)
                        .keyboardType(.decimalPad)
                        .font(.title2.bold())
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                
                // Earnings preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Earnings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyHelper.format(quickHours * project.hourlyRate, currency: project.currency))
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Notes field
            TextField("What did you work on? (optional)", text: $quickNotes)
                .padding()
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            
            // Quick hour buttons
            HStack(spacing: 8) {
                ForEach([0.5, 1.0, 2.0, 4.0, 8.0], id: \.self) { hours in
                    Button {
                        quickHours = hours
                    } label: {
                        Text(hours == 0.5 ? "30m" : "\(Int(hours))h")
                            .font(.caption.bold())
                            .foregroundStyle(quickHours == hours ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                quickHours == hours ? project.color : Color(.tertiarySystemGroupedBackground),
                                in: Capsule()
                            )
                    }
                }
            }
            
            // Add button
            Button {
                addQuickEntry()
            } label: {
                Label("Add Entry", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(project.color.gradient, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(quickHours <= 0 || project.status == "completed")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func addQuickEntry() {
        let seconds = quickHours * 3600
        let entry = TimeEntryData(
            projectId: project.id,
            startTime: Date(),
            endTime: Date().addingTimeInterval(seconds),
            duration: seconds,
            notes: quickNotes,
            isRunning: false
        )
        dataController.saveTimeEntry(entry)
        
        // Reset fields
        quickHours = 0
        quickNotes = ""
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(String(format: "%.1f", totalHours))
                    .font(.title2.bold())
                    .foregroundStyle(.blue)
                Text("Hours")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 4) {
                Text(CurrencyHelper.format(totalEarnings, currency: project.currency))
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Earned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 4) {
                Text("\(timeEntries.count)")
                    .font(.title2.bold())
                    .foregroundStyle(.purple)
                Text("Entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Time Entries Chart
    private var timeEntriesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hours by Day")
                .font(.headline)
            
            Chart {
                ForEach(groupedEntriesByDay, id: \.date) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(project.color.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var groupedEntriesByDay: [(date: Date, hours: Double)] {
        let grouped = Dictionary(grouping: timeEntries) { entry in
            Calendar.current.startOfDay(for: entry.startTime)
        }
        
        return grouped.map { (date: $0.key, hours: $0.value.reduce(0) { $0 + $1.durationHours }) }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Time Entries List
    private var timeEntriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Entries")
                .font(.headline)
            
            if timeEntries.isEmpty {
                Text("No time entries yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(timeEntries) { entry in
                        TimeEntryRow(entry: entry, hourlyRate: project.hourlyRate, currency: project.currency)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Project Actions
    private func completeProject() {
        var updated = project
        updated.status = "completed"
        updated.completedAt = Date()
        dataController.saveProject(updated)
        project = updated
    }
    
    private func pauseProject() {
        var updated = project
        updated.status = "paused"
        dataController.saveProject(updated)
        project = updated
    }
    
    private func resumeProject() {
        var updated = project
        updated.status = "active"
        dataController.saveProject(updated)
        project = updated
    }
}

// MARK: - TimeEntryRow

struct TimeEntryRow: View {
    let entry: TimeEntryData
    let hourlyRate: Double
    let currency: String
    
    var earnings: Double {
        entry.durationHours * hourlyRate
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.formattedDuration)
                    .font(.subheadline.monospaced())
                
                Text(CurrencyHelper.format(earnings, currency: currency))
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - AddTimeEntrySheet

struct AddTimeEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    
    let projectId: UUID
    let projectRate: Double
    
    @State private var date = Date()
    @State private var hours: Double = 0
    @State private var minutes: Double = 0
    @State private var notes = ""
    
    var totalSeconds: Double {
        (hours * 3600) + (minutes * 60)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Duration") {
                    HStack {
                        Text("Hours")
                        Spacer()
                        TextField("0", value: $hours, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Minutes")
                        Spacer()
                        TextField("0", value: $minutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    if totalSeconds > 0 {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(String(format: "%.2f hours", totalSeconds / 3600))
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Earnings")
                            Spacer()
                            Text(CurrencyHelper.format((totalSeconds / 3600) * projectRate, currency: "USD"))
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("What did you work on?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Time Entry")
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
                    .disabled(totalSeconds <= 0)
                }
            }
        }
    }
    
    private func save() {
        let entry = TimeEntryData(
            projectId: projectId,
            startTime: date,
            endTime: date.addingTimeInterval(totalSeconds),
            duration: totalSeconds,
            notes: notes,
            isRunning: false
        )
        dataController.saveTimeEntry(entry)
    }
}

