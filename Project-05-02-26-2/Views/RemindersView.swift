//
//  RemindersView.swift
//  Hourly Rate Engineer
//
//  Умные напоминания с Local Notifications
//

import SwiftUI
import UserNotifications

struct RemindersView: View {
    @Environment(DataController.self) private var dataController
    @State private var showingAddReminder = false
    @State private var selectedReminder: ReminderData?
    @State private var showingDeleteAlert = false
    @State private var reminderToDelete: ReminderData?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var activeReminders: [ReminderData] {
        dataController.reminders.filter { $0.isEnabled }.sorted { $0.triggerDate < $1.triggerDate }
    }
    
    var inactiveReminders: [ReminderData] {
        dataController.reminders.filter { !$0.isEnabled }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Notification permission banner
                    if notificationStatus != .authorized {
                        notificationPermissionBanner
                    }
                    
                    // Quick add buttons
                    quickAddSection
                    
                    // Active reminders
                    if !activeReminders.isEmpty {
                        reminderSection(title: "Active Reminders", reminders: activeReminders)
                    }
                    
                    // Inactive reminders
                    if !inactiveReminders.isEmpty {
                        reminderSection(title: "Disabled Reminders", reminders: inactiveReminders, isInactive: true)
                    }
                    
                    // Empty state
                    if dataController.reminders.isEmpty {
                        ContentUnavailableView(
                            "No Reminders",
                            systemImage: "bell.badge",
                            description: Text("Set up reminders to stay on top of your rate reviews")
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddReminder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderSheet()
            }
            .sheet(item: $selectedReminder) { reminder in
                ReminderDetailSheet(reminder: reminder)
            }
            .alert("Delete Reminder", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let reminder = reminderToDelete {
                        dataController.deleteReminder(reminder)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this reminder?")
            }
            .onAppear {
                checkNotificationStatus()
            }
        }
    }
    
    // MARK: - Notification Permission Banner
    private var notificationPermissionBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bell.slash")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications Disabled")
                        .font(.headline)
                    Text("Enable notifications to receive reminders")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Button {
                requestNotificationPermission()
            } label: {
                Text("Enable Notifications")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange.gradient, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Quick Add Section
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                QuickAddButton(
                    title: "Rate Review",
                    subtitle: "Monthly",
                    icon: "dollarsign.circle",
                    color: .green
                ) {
                    addQuickReminder(type: "rate_review", interval: "monthly")
                }
                
                QuickAddButton(
                    title: "Equipment Check",
                    subtitle: "Quarterly",
                    icon: "desktopcomputer",
                    color: .blue
                ) {
                    addQuickReminder(type: "equipment_check", interval: "quarterly")
                }
                
                QuickAddButton(
                    title: "Goal Progress",
                    subtitle: "Weekly",
                    icon: "target",
                    color: .purple
                ) {
                    addQuickReminder(type: "goal_check", interval: "weekly")
                }
                
                QuickAddButton(
                    title: "Custom",
                    subtitle: "Any time",
                    icon: "bell.badge",
                    color: .orange
                ) {
                    showingAddReminder = true
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Reminder Section
    private func reminderSection(title: String, reminders: [ReminderData], isInactive: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(reminders.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(reminders) { reminder in
                    ReminderRow(reminder: reminder, isInactive: isInactive) {
                        toggleReminder(reminder)
                    }
                    .onTapGesture {
                        selectedReminder = reminder
                    }
                    .contextMenu {
                        Button {
                            selectedReminder = reminder
                        } label: {
                            Label("View Details", systemImage: "eye")
                        }
                        
                        Button {
                            toggleReminder(reminder)
                        } label: {
                            Label(reminder.isEnabled ? "Disable" : "Enable", 
                                  systemImage: reminder.isEnabled ? "bell.slash" : "bell")
                        }
                        
                        Button(role: .destructive) {
                            reminderToDelete = reminder
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Functions
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                checkNotificationStatus()
            }
        }
    }
    
    private func toggleReminder(_ reminder: ReminderData) {
        var updated = reminder
        updated.isEnabled.toggle()
        dataController.saveReminder(updated)
    }
    
    private func addQuickReminder(type: String, interval: String) {
        let title: String
        let message: String
        let triggerDate: Date
        
        switch type {
        case "rate_review":
            title = "Rate Review Reminder"
            message = "Time to review and update your hourly rate!"
        case "equipment_check":
            title = "Equipment Check"
            message = "Review your equipment and update amortization."
        case "goal_check":
            title = "Goal Progress Check"
            message = "Check your financial goals progress!"
        default:
            title = "Reminder"
            message = "Custom reminder"
        }
        
        switch interval {
        case "weekly":
            triggerDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        case "monthly":
            triggerDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        case "quarterly":
            triggerDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        default:
            triggerDate = Date().addingTimeInterval(86400) // +1 day
        }
        
        let reminder = ReminderData(
            title: title,
            message: message,
            type: type,
            triggerDate: triggerDate,
            repeatInterval: interval,
            isEnabled: true
        )
        
        dataController.saveReminder(reminder)
    }
}

// MARK: - QuickAddButton

struct QuickAddButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - ReminderRow

struct ReminderRow: View {
    let reminder: ReminderData
    var isInactive: Bool = false
    let toggleAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.typeIcon)
                .font(.title2)
                .foregroundStyle(isInactive ? .secondary : typeColor)
                .frame(width: 44, height: 44)
                .background((isInactive ? Color.gray : typeColor).opacity(0.15), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isInactive ? .secondary : .primary)
                
                HStack(spacing: 6) {
                    Text(reminder.triggerDate.formatted(date: .abbreviated, time: .shortened))
                    
                    if reminder.repeatInterval != "none" {
                        Text("•")
                        Text(reminder.repeatIntervalName)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(reminder.isEnabled))
                .labelsHidden()
                .tint(typeColor)
                .onTapGesture {
                    toggleAction()
                }
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
    
    var typeColor: Color {
        switch reminder.type {
        case "rate_review": return .green
        case "equipment_check": return .blue
        case "goal_check": return .purple
        default: return .orange
        }
    }
}

// MARK: - AddReminderSheet

struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    
    @State private var title = ""
    @State private var message = ""
    @State private var type = "custom"
    @State private var triggerDate = Date().addingTimeInterval(3600)
    @State private var repeatInterval = "none"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder Info") {
                    TextField("Title", text: $title)
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(Array(ReminderData.types.keys.sorted()), id: \.self) { key in
                            Label(ReminderData.types[key] ?? key, systemImage: iconForType(key))
                                .tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Schedule") {
                    DatePicker("Date & Time", selection: $triggerDate)
                    
                    Picker("Repeat", selection: $repeatInterval) {
                        ForEach(Array(ReminderData.intervals.keys.sorted()), id: \.self) { key in
                            Text(ReminderData.intervals[key] ?? key).tag(key)
                        }
                    }
                }
                
                // Preview
                Section("Preview") {
                    HStack {
                        Image(systemName: iconForType(type))
                            .foregroundStyle(colorForType(type))
                        
                        VStack(alignment: .leading) {
                            Text(title.isEmpty ? "Reminder Title" : title)
                                .font(.subheadline.weight(.medium))
                            Text(triggerDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Reminder")
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
                    .disabled(title.isEmpty)
                }
            }
            .onChange(of: type) { _, newType in
                if title.isEmpty {
                    switch newType {
                    case "rate_review":
                        title = "Rate Review Reminder"
                        message = "Time to review and update your hourly rate!"
                    case "equipment_check":
                        title = "Equipment Check"
                        message = "Review your equipment and update amortization."
                    case "goal_check":
                        title = "Goal Progress Check"
                        message = "Check your financial goals progress!"
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "rate_review": return "dollarsign.circle"
        case "equipment_check": return "desktopcomputer"
        case "goal_check": return "target"
        default: return "bell"
        }
    }
    
    private func colorForType(_ type: String) -> Color {
        switch type {
        case "rate_review": return .green
        case "equipment_check": return .blue
        case "goal_check": return .purple
        default: return .orange
        }
    }
    
    private func save() {
        let reminder = ReminderData(
            title: title,
            message: message,
            type: type,
            triggerDate: triggerDate,
            repeatInterval: repeatInterval,
            isEnabled: true
        )
        dataController.saveReminder(reminder)
    }
}

// MARK: - ReminderDetailSheet

struct ReminderDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataController.self) private var dataController
    let reminder: ReminderData
    
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedMessage: String = ""
    @State private var editedTriggerDate: Date = Date()
    @State private var editedRepeatInterval: String = "none"
    
    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    if isEditing {
                        TextField("Title", text: $editedTitle)
                        TextField("Message", text: $editedMessage, axis: .vertical)
                            .lineLimit(2...4)
                    } else {
                        LabeledContent("Title", value: reminder.title)
                        if !reminder.message.isEmpty {
                            Text(reminder.message)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Type") {
                    LabeledContent("Type", value: ReminderData.types[reminder.type] ?? reminder.type)
                }
                
                Section("Schedule") {
                    if isEditing {
                        DatePicker("Date & Time", selection: $editedTriggerDate)
                        
                        Picker("Repeat", selection: $editedRepeatInterval) {
                            ForEach(Array(ReminderData.intervals.keys.sorted()), id: \.self) { key in
                                Text(ReminderData.intervals[key] ?? key).tag(key)
                            }
                        }
                    } else {
                        LabeledContent("Date", value: reminder.triggerDate.formatted(date: .long, time: .shortened))
                        LabeledContent("Repeat", value: reminder.repeatIntervalName)
                    }
                }
                
                Section("Status") {
                    HStack {
                        Text("Enabled")
                        Spacer()
                        Image(systemName: reminder.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(reminder.isEnabled ? .green : .red)
                    }
                    
                    if let lastTriggered = reminder.lastTriggered {
                        LabeledContent("Last Triggered", value: lastTriggered.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }
            .navigationTitle("Reminder Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                    } else {
                        Button("Done") { dismiss() }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveEdits()
                            isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                    }
                }
            }
        }
    }
    
    private func startEditing() {
        editedTitle = reminder.title
        editedMessage = reminder.message
        editedTriggerDate = reminder.triggerDate
        editedRepeatInterval = reminder.repeatInterval
        isEditing = true
    }
    
    private func saveEdits() {
        var updated = reminder
        updated.title = editedTitle
        updated.message = editedMessage
        updated.triggerDate = editedTriggerDate
        updated.repeatInterval = editedRepeatInterval
        dataController.saveReminder(updated)
    }
}
