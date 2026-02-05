//
//  ExportView.swift
//  Hourly Rate Engineer
//
//  Расширенный экспорт данных (CSV, PDF)
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(DataController.self) private var dataController
    @State private var selectedExportType: ExportType = .rateHistory
    @State private var exportFormat: ExportFormat = .csv
    @State private var dateRange: DateRange = .allTime
    @State private var customStartDate = Date().addingTimeInterval(-30 * 24 * 3600)
    @State private var customEndDate = Date()
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    enum ExportType: String, CaseIterable {
        case rateHistory = "Rate History"
        case projects = "Projects"
        case goals = "Goals"
        case timeEntries = "Time Entries"
        case marketRates = "Market Rates"
        case fullReport = "Full Report"
    }
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
        case json = "JSON"
    }
    
    enum DateRange: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastQuarter = "Last 3 Months"
        case lastYear = "Last Year"
        case allTime = "All Time"
        case custom = "Custom"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                exportTypeSection
                formatSection
                dateRangeSection
                previewSection
                exportButtonSection
            }
            .navigationTitle("Export Data")
            .alert("Export", isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    // MARK: - Section Views
    
    private var exportTypeSection: some View {
        Section("Data to Export") {
            ForEach(ExportType.allCases, id: \.self) { type in
                ExportTypeRow(
                    type: type,
                    isSelected: selectedExportType == type,
                    count: countForType(type)
                ) {
                    selectedExportType = type
                }
            }
        }
    }
    
    private var formatSection: some View {
        Section("Format") {
            Picker("Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    HStack {
                        Image(systemName: iconForFormat(format))
                        Text(format.rawValue)
                    }
                    .tag(format)
                }
            }
            .pickerStyle(.segmented)
            
            Text(descriptionForFormat(exportFormat))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var dateRangeSection: some View {
        Section("Date Range") {
            Picker("Range", selection: $dateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            
            if dateRange == .custom {
                DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                DatePicker("To", selection: $customEndDate, displayedComponents: .date)
            }
        }
    }
    
    private var previewSection: some View {
        Section("Preview") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconForExportType(selectedExportType))
                        .foregroundStyle(Color.accentColor)
                    Text(selectedExportType.rawValue)
                        .font(.headline)
                }
                
                Text("\(filteredDataCount) records")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Format: \(exportFormat.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Date range: \(dateRangeDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var exportButtonSection: some View {
        Section {
            Button {
                performExport()
            } label: {
                HStack {
                    Spacer()
                    if isExporting {
                        ProgressView()
                            .padding(.trailing, 8)
                    }
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .disabled(isExporting || filteredDataCount == 0)
        }
    }
    
    // MARK: - Helpers
    
    private func iconForExportType(_ type: ExportType) -> String {
        switch type {
        case .rateHistory: return "chart.line.uptrend.xyaxis"
        case .projects: return "folder"
        case .goals: return "target"
        case .timeEntries: return "clock"
        case .marketRates: return "chart.bar"
        case .fullReport: return "doc.richtext"
        }
    }
    
    private func iconForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return "tablecells"
        case .pdf: return "doc.fill"
        case .json: return "curlybraces"
        }
    }
    
    private func descriptionForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return "Spreadsheet format, compatible with Excel and Numbers"
        case .pdf: return "Formatted document, ready for printing or sharing"
        case .json: return "Data format, suitable for backup or import"
        }
    }
    
    private func countForType(_ type: ExportType) -> Int {
        switch type {
        case .rateHistory: return dataController.rateHistory.count
        case .projects: return dataController.projects.count
        case .goals: return dataController.goals.count
        case .timeEntries: return dataController.timeEntries.count
        case .marketRates: return dataController.marketRates.count
        case .fullReport: return -1
        }
    }
    
    private var filteredDataCount: Int {
        let startDate = dateRangeStartDate
        let endDate = dateRangeEndDate
        
        switch selectedExportType {
        case .rateHistory:
            return dataController.rateHistory.filter { $0.date >= startDate && $0.date <= endDate }.count
        case .projects:
            return dataController.projects.filter { $0.createdAt >= startDate && $0.createdAt <= endDate }.count
        case .goals:
            return dataController.goals.filter { $0.createdAt >= startDate && $0.createdAt <= endDate }.count
        case .timeEntries:
            return dataController.timeEntries.filter { $0.startTime >= startDate && $0.startTime <= endDate }.count
        case .marketRates:
            return dataController.marketRates.filter { $0.updatedAt >= startDate && $0.updatedAt <= endDate }.count
        case .fullReport:
            return 1
        }
    }
    
    private var dateRangeStartDate: Date {
        switch dateRange {
        case .lastWeek:
            return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        case .lastMonth:
            return Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .lastQuarter:
            return Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .lastYear:
            return Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .allTime:
            return Date.distantPast
        case .custom:
            return customStartDate
        }
    }
    
    private var dateRangeEndDate: Date {
        switch dateRange {
        case .custom:
            return customEndDate
        default:
            return Date()
        }
    }
    
    private var dateRangeDescription: String {
        if dateRange == .allTime {
            return "All time"
        } else if dateRange == .custom {
            return "\(customStartDate.formatted(date: .abbreviated, time: .omitted)) - \(customEndDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            return "\(dateRangeStartDate.formatted(date: .abbreviated, time: .omitted)) - Now"
        }
    }
    
    // MARK: - Export Functions
    
    private func performExport() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileURL: URL?
            
            switch exportFormat {
            case .csv:
                fileURL = exportToCSV()
            case .pdf:
                fileURL = exportToPDF()
            case .json:
                fileURL = exportToJSON()
            }
            
            DispatchQueue.main.async {
                isExporting = false
                
                if let url = fileURL {
                    exportedFileURL = url
                    showingShareSheet = true
                } else {
                    alertMessage = "Failed to create export file"
                    showingAlert = true
                }
            }
        }
    }
    
    private func exportToCSV() -> URL? {
        var csvContent = ""
        
        switch selectedExportType {
        case .rateHistory:
            csvContent = generateRateHistoryCSV()
        case .projects:
            csvContent = generateProjectsCSV()
        case .goals:
            csvContent = generateGoalsCSV()
        case .timeEntries:
            csvContent = generateTimeEntriesCSV()
        case .marketRates:
            csvContent = generateMarketRatesCSV()
        case .fullReport:
            csvContent = generateFullReportCSV()
        }
        
        return saveToFile(content: csvContent, extension: "csv")
    }
    
    private func exportToPDF() -> URL? {
        let pdfContent = generatePDFContent()
        return createPDF(from: pdfContent)
    }
    
    private func exportToJSON() -> URL? {
        var jsonData: Data?
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            switch selectedExportType {
            case .rateHistory:
                jsonData = try encoder.encode(filterByDate(dataController.rateHistory, keyPath: \.date))
            case .projects:
                jsonData = try encoder.encode(filterByDate(dataController.projects, keyPath: \.createdAt))
            case .goals:
                jsonData = try encoder.encode(filterByDate(dataController.goals, keyPath: \.createdAt))
            case .timeEntries:
                jsonData = try encoder.encode(filterByDate(dataController.timeEntries, keyPath: \.startTime))
            case .marketRates:
                jsonData = try encoder.encode(filterByDate(dataController.marketRates, keyPath: \.updatedAt))
            case .fullReport:
                let report: [String: Any] = [
                    "exportDate": ISO8601DateFormatter().string(from: Date()),
                    "rateHistory": dataController.rateHistory.count,
                    "projects": dataController.projects.count,
                    "goals": dataController.goals.count,
                    "timeEntries": dataController.timeEntries.count,
                    "marketRates": dataController.marketRates.count
                ]
                jsonData = try JSONSerialization.data(withJSONObject: report, options: .prettyPrinted)
            }
        } catch {
            return nil
        }
        
        guard let data = jsonData, let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return saveToFile(content: content, extension: "json")
    }
    
    private func filterByDate<T>(_ array: [T], keyPath: KeyPath<T, Date>) -> [T] {
        array.filter { item in
            let date = item[keyPath: keyPath]
            return date >= dateRangeStartDate && date <= dateRangeEndDate
        }
    }
    
    // MARK: - CSV Generators
    
    private func generateRateHistoryCSV() -> String {
        var csv = "Date,Hourly Rate,Daily Rate,Monthly Gross,Net Income,Tax,Fixed Costs,Amortization,Social Net,Billable Hours,Currency,Notes\n"
        
        for entry in filterByDate(dataController.rateHistory, keyPath: \.date) {
            csv += "\(entry.date.ISO8601Format()),\(entry.hourlyRate),\(entry.dailyRate),\(entry.monthlyGross),\(entry.netIncome),\(entry.taxAmount),\(entry.fixedCostsTotal),\(entry.amortizationTotal),\(entry.socialNetTotal),\(entry.billableHours),\(entry.currency),\"\(entry.notes.replacingOccurrences(of: "\"", with: "\"\""))\"\n"
        }
        
        return csv
    }
    
    private func generateProjectsCSV() -> String {
        var csv = "Name,Client,Hourly Rate,Estimated Hours,Status,Created,Completed,Currency,Notes\n"
        
        for project in filterByDate(dataController.projects, keyPath: \.createdAt) {
            let completedStr = project.completedAt?.ISO8601Format() ?? ""
            csv += "\"\(project.name)\",\"\(project.clientName)\",\(project.hourlyRate),\(project.estimatedHours),\(project.status),\(project.createdAt.ISO8601Format()),\(completedStr),\(project.currency),\"\(project.notes.replacingOccurrences(of: "\"", with: "\"\""))\"\n"
        }
        
        return csv
    }
    
    private func generateGoalsCSV() -> String {
        var csv = "Name,Target Amount,Current Amount,Progress %,Category,Deadline,Is Completed,Currency,Notes\n"
        
        for goal in filterByDate(dataController.goals, keyPath: \.createdAt) {
            let deadlineStr = goal.deadline?.ISO8601Format() ?? ""
            csv += "\"\(goal.name)\",\(goal.targetAmount),\(goal.currentAmount),\(goal.progress * 100),\(goal.category),\(deadlineStr),\(goal.isCompleted),\(goal.currency),\"\(goal.notes.replacingOccurrences(of: "\"", with: "\"\""))\"\n"
        }
        
        return csv
    }
    
    private func generateTimeEntriesCSV() -> String {
        var csv = "Project ID,Start Time,End Time,Duration (hours),Notes\n"
        
        for entry in filterByDate(dataController.timeEntries, keyPath: \.startTime) {
            let endStr = entry.endTime?.ISO8601Format() ?? ""
            csv += "\(entry.projectId),\(entry.startTime.ISO8601Format()),\(endStr),\(entry.durationHours),\"\(entry.notes.replacingOccurrences(of: "\"", with: "\"\""))\"\n"
        }
        
        return csv
    }
    
    private func generateMarketRatesCSV() -> String {
        var csv = "Role,Min Rate,Max Rate,Average Rate,Region,Source,Currency,Updated,Notes\n"
        
        for rate in filterByDate(dataController.marketRates, keyPath: \.updatedAt) {
            csv += "\"\(rate.name)\",\(rate.minRate),\(rate.maxRate),\(rate.averageRate),\"\(rate.region)\",\"\(rate.source)\",\(rate.currency),\(rate.updatedAt.ISO8601Format()),\"\(rate.notes.replacingOccurrences(of: "\"", with: "\"\""))\"\n"
        }
        
        return csv
    }
    
    private func generateFullReportCSV() -> String {
        var csv = "=== HOURLY RATE ENGINEER EXPORT ===\n"
        csv += "Export Date: \(Date().formatted())\n\n"
        
        csv += "=== RATE HISTORY ===\n"
        csv += generateRateHistoryCSV()
        
        csv += "\n=== PROJECTS ===\n"
        csv += generateProjectsCSV()
        
        csv += "\n=== GOALS ===\n"
        csv += generateGoalsCSV()
        
        csv += "\n=== TIME ENTRIES ===\n"
        csv += generateTimeEntriesCSV()
        
        csv += "\n=== MARKET RATES ===\n"
        csv += generateMarketRatesCSV()
        
        return csv
    }
    
    // MARK: - PDF Generator
    
    private func generatePDFContent() -> NSAttributedString {
        let content = NSMutableAttributedString()
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.label
        ]
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.systemBlue
        ]
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
        
        // Title
        content.append(NSAttributedString(string: "Hourly Rate Engineer Report\n\n", attributes: titleAttributes))
        content.append(NSAttributedString(string: "Generated: \(Date().formatted())\n", attributes: bodyAttributes))
        content.append(NSAttributedString(string: "Report Type: \(selectedExportType.rawValue)\n", attributes: bodyAttributes))
        content.append(NSAttributedString(string: "Date Range: \(dateRangeDescription)\n\n", attributes: bodyAttributes))
        
        switch selectedExportType {
        case .rateHistory:
            content.append(NSAttributedString(string: "Rate History\n\n", attributes: headerAttributes))
            for entry in filterByDate(dataController.rateHistory, keyPath: \.date) {
                content.append(NSAttributedString(string: "• \(entry.date.formatted(date: .abbreviated, time: .omitted)): \(CurrencyHelper.format(entry.hourlyRate, currency: entry.currency))/hr\n", attributes: bodyAttributes))
            }
            
        case .projects:
            content.append(NSAttributedString(string: "Projects\n\n", attributes: headerAttributes))
            for project in filterByDate(dataController.projects, keyPath: \.createdAt) {
                content.append(NSAttributedString(string: "• \(project.name) (\(project.status))\n  Rate: \(CurrencyHelper.format(project.hourlyRate, currency: project.currency))/hr\n", attributes: bodyAttributes))
            }
            
        case .goals:
            content.append(NSAttributedString(string: "Financial Goals\n\n", attributes: headerAttributes))
            for goal in filterByDate(dataController.goals, keyPath: \.createdAt) {
                content.append(NSAttributedString(string: "• \(goal.name): \(String(format: "%.1f%%", goal.progress * 100)) complete\n  Target: \(CurrencyHelper.format(goal.targetAmount, currency: goal.currency))\n", attributes: bodyAttributes))
            }
            
        case .timeEntries:
            content.append(NSAttributedString(string: "Time Entries\n\n", attributes: headerAttributes))
            let totalHours = filterByDate(dataController.timeEntries, keyPath: \.startTime).reduce(0) { $0 + $1.durationHours }
            content.append(NSAttributedString(string: "Total Hours: \(String(format: "%.1f", totalHours))\n", attributes: bodyAttributes))
            content.append(NSAttributedString(string: "Entries: \(filteredDataCount)\n", attributes: bodyAttributes))
            
        case .marketRates:
            content.append(NSAttributedString(string: "Market Rates\n\n", attributes: headerAttributes))
            for rate in filterByDate(dataController.marketRates, keyPath: \.updatedAt) {
                content.append(NSAttributedString(string: "• \(rate.name)\n  Range: \(rate.rateRange)\n", attributes: bodyAttributes))
            }
            
        case .fullReport:
            content.append(NSAttributedString(string: "Summary\n\n", attributes: headerAttributes))
            content.append(NSAttributedString(string: "Rate History Entries: \(dataController.rateHistory.count)\n", attributes: bodyAttributes))
            content.append(NSAttributedString(string: "Projects: \(dataController.projects.count)\n", attributes: bodyAttributes))
            content.append(NSAttributedString(string: "Goals: \(dataController.goals.count)\n", attributes: bodyAttributes))
            content.append(NSAttributedString(string: "Time Entries: \(dataController.timeEntries.count)\n", attributes: bodyAttributes))
            content.append(NSAttributedString(string: "Market Rates: \(dataController.marketRates.count)\n", attributes: bodyAttributes))
        }
        
        return content
    }
    
    private func createPDF(from content: NSAttributedString) -> URL? {
        let pageWidth: CGFloat = 612 // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Hourly Rate Engineer",
            kCGPDFContextTitle: "Export Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let textRect = CGRect(x: margin, y: margin, width: pageWidth - 2 * margin, height: pageHeight - 2 * margin)
            content.draw(in: textRect)
        }
        
        return saveDataToFile(data: data, extension: "pdf")
    }
    
    // MARK: - File Helpers
    
    private func saveToFile(content: String, extension ext: String) -> URL? {
        guard let data = content.data(using: .utf8) else { return nil }
        return saveDataToFile(data: data, extension: ext)
    }
    
    private func saveDataToFile(data: Data, extension ext: String) -> URL? {
        let fileName = "HourlyRateEngineer_\(selectedExportType.rawValue.replacingOccurrences(of: " ", with: "_"))_\(Date().ISO8601Format().prefix(10)).\(ext)"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}

// MARK: - ExportTypeRow

struct ExportTypeRow: View {
    let type: ExportView.ExportType
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconForType)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .foregroundStyle(.primary)
                    
                    if count >= 0 {
                        Text("\(count) records")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
    
    var iconForType: String {
        switch type {
        case .rateHistory: return "chart.line.uptrend.xyaxis"
        case .projects: return "folder"
        case .goals: return "target"
        case .timeEntries: return "clock"
        case .marketRates: return "chart.bar"
        case .fullReport: return "doc.richtext"
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
