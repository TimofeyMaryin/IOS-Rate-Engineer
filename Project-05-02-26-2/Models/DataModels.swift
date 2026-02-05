//
//  DataModels.swift
//  Hourly Rate Engineer
//
//  Value type data models for Core Data entities
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Basic Data Models

struct IncomeTargetData: Identifiable, Equatable, Codable {
    var id: UUID
    var netIncome: Double
    var taxRegime: String
    var taxRate: Double
    var currency: String
    
    init(id: UUID = UUID(), netIncome: Double = 0, taxRegime: String = "NPD", taxRate: Double = 0.06, currency: String = "USD") {
        self.id = id
        self.netIncome = netIncome
        self.taxRegime = taxRegime
        self.taxRate = taxRate
        self.currency = currency
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.netIncome = object.value(forKey: "netIncome") as? Double ?? 0
        self.taxRegime = object.value(forKey: "taxRegime") as? String ?? "NPD"
        self.taxRate = object.value(forKey: "taxRate") as? Double ?? 0.06
        self.currency = object.value(forKey: "currency") as? String ?? "USD"
    }
}

struct TimeBudgetData: Identifiable, Equatable, Codable {
    var id: UUID
    var workingDaysPerWeek: Int16
    var hoursPerDay: Double
    var holidays: Int16
    var vacationDays: Int16
    var sickDays: Int16
    var nonBillablePercent: Double
    
    init(id: UUID = UUID(), workingDaysPerWeek: Int16 = 5, hoursPerDay: Double = 8, holidays: Int16 = 10, vacationDays: Int16 = 20, sickDays: Int16 = 5, nonBillablePercent: Double = 0.2) {
        self.id = id
        self.workingDaysPerWeek = workingDaysPerWeek
        self.hoursPerDay = hoursPerDay
        self.holidays = holidays
        self.vacationDays = vacationDays
        self.sickDays = sickDays
        self.nonBillablePercent = nonBillablePercent
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.workingDaysPerWeek = object.value(forKey: "workingDaysPerWeek") as? Int16 ?? 5
        self.hoursPerDay = object.value(forKey: "hoursPerDay") as? Double ?? 8
        self.holidays = object.value(forKey: "holidays") as? Int16 ?? 10
        self.vacationDays = object.value(forKey: "vacationDays") as? Int16 ?? 20
        self.sickDays = object.value(forKey: "sickDays") as? Int16 ?? 5
        self.nonBillablePercent = object.value(forKey: "nonBillablePercent") as? Double ?? 0.2
    }
    
    var annualWorkingDays: Int {
        let weeksPerYear = 52
        let totalWorkingDays = Int(workingDaysPerWeek) * weeksPerYear
        return totalWorkingDays - Int(holidays) - Int(vacationDays) - Int(sickDays)
    }
    
    var annualBillableHours: Double {
        let totalHours = Double(annualWorkingDays) * hoursPerDay
        return totalHours * (1 - nonBillablePercent)
    }
    
    var monthlyBillableHours: Double {
        annualBillableHours / 12.0
    }
}

struct EquipmentData: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var cost: Double
    var lifespan: Int16
    var purchaseDate: Date?
    
    init(id: UUID = UUID(), name: String = "", cost: Double = 0, lifespan: Int16 = 3, purchaseDate: Date? = nil) {
        self.id = id
        self.name = name
        self.cost = cost
        self.lifespan = lifespan
        self.purchaseDate = purchaseDate
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.name = object.value(forKey: "name") as? String ?? ""
        self.cost = object.value(forKey: "cost") as? Double ?? 0
        self.lifespan = object.value(forKey: "lifespan") as? Int16 ?? 3
        self.purchaseDate = object.value(forKey: "purchaseDate") as? Date
    }
    
    var monthlyAmortization: Double {
        guard lifespan > 0 else { return 0 }
        return cost / (Double(lifespan) * 12)
    }
    
    var remainingValue: Double {
        guard let purchaseDate = purchaseDate, lifespan > 0 else { return cost }
        let monthsSincePurchase = Calendar.current.dateComponents([.month], from: purchaseDate, to: Date()).month ?? 0
        let totalMonths = Int(lifespan) * 12
        let remainingMonths = max(0, totalMonths - monthsSincePurchase)
        return cost * (Double(remainingMonths) / Double(totalMonths))
    }
}

struct FixedCostData: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var amount: Double
    var category: String
    
    init(id: UUID = UUID(), name: String = "", amount: Double = 0, category: String = "other") {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.name = object.value(forKey: "name") as? String ?? ""
        self.amount = object.value(forKey: "amount") as? Double ?? 0
        self.category = object.value(forKey: "category") as? String ?? "other"
    }
    
    static let categories = [
        "workspace": "Workspace",
        "utilities": "Utilities",
        "software": "Software",
        "insurance": "Insurance",
        "education": "Education",
        "marketing": "Marketing",
        "other": "Other"
    ]
    
    var categoryName: String {
        Self.categories[category] ?? "Other"
    }
}

struct SocialNetData: Identifiable, Equatable, Codable {
    var id: UUID
    var sickFundMonths: Double
    var safetyNetMonths: Double
    var targetSavingMonths: Int16
    
    init(id: UUID = UUID(), sickFundMonths: Double = 1, safetyNetMonths: Double = 3, targetSavingMonths: Int16 = 12) {
        self.id = id
        self.sickFundMonths = sickFundMonths
        self.safetyNetMonths = safetyNetMonths
        self.targetSavingMonths = targetSavingMonths
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.sickFundMonths = object.value(forKey: "sickFundMonths") as? Double ?? 1
        self.safetyNetMonths = object.value(forKey: "safetyNetMonths") as? Double ?? 3
        self.targetSavingMonths = object.value(forKey: "targetSavingMonths") as? Int16 ?? 12
    }
    
    func monthlyContribution(basedOnIncome monthlyIncome: Double) -> Double {
        let totalMonthsNeeded = sickFundMonths + safetyNetMonths
        guard targetSavingMonths > 0 else { return 0 }
        return (totalMonthsNeeded * monthlyIncome) / Double(targetSavingMonths)
    }
}

struct ScenarioData: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var hoursPerWeek: Double
    var extraEquipmentCost: Double
    var createdAt: Date
    var calculatedHourlyRate: Double
    
    init(id: UUID = UUID(), name: String = "", hoursPerWeek: Double = 40, extraEquipmentCost: Double = 0, createdAt: Date = Date(), calculatedHourlyRate: Double = 0) {
        self.id = id
        self.name = name
        self.hoursPerWeek = hoursPerWeek
        self.extraEquipmentCost = extraEquipmentCost
        self.createdAt = createdAt
        self.calculatedHourlyRate = calculatedHourlyRate
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.name = object.value(forKey: "name") as? String ?? ""
        self.hoursPerWeek = object.value(forKey: "hoursPerWeek") as? Double ?? 40
        self.extraEquipmentCost = object.value(forKey: "extraEquipmentCost") as? Double ?? 0
        self.createdAt = object.value(forKey: "createdAt") as? Date ?? Date()
        self.calculatedHourlyRate = object.value(forKey: "calculatedHourlyRate") as? Double ?? 0
    }
}

// MARK: - Extended Data Models

struct RateHistoryData: Identifiable, Equatable, Codable {
    var id: UUID
    var date: Date
    var hourlyRate: Double
    var dailyRate: Double
    var monthlyGross: Double
    var currency: String
    var netIncome: Double
    var taxAmount: Double
    var fixedCostsTotal: Double
    var amortizationTotal: Double
    var socialNetTotal: Double
    var billableHours: Double
    var notes: String
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        hourlyRate: Double = 0,
        dailyRate: Double = 0,
        monthlyGross: Double = 0,
        currency: String = "USD",
        netIncome: Double = 0,
        taxAmount: Double = 0,
        fixedCostsTotal: Double = 0,
        amortizationTotal: Double = 0,
        socialNetTotal: Double = 0,
        billableHours: Double = 0,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.hourlyRate = hourlyRate
        self.dailyRate = dailyRate
        self.monthlyGross = monthlyGross
        self.currency = currency
        self.netIncome = netIncome
        self.taxAmount = taxAmount
        self.fixedCostsTotal = fixedCostsTotal
        self.amortizationTotal = amortizationTotal
        self.socialNetTotal = socialNetTotal
        self.billableHours = billableHours
        self.notes = notes
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.date = object.value(forKey: "date") as? Date ?? Date()
        self.hourlyRate = object.value(forKey: "hourlyRate") as? Double ?? 0
        self.dailyRate = object.value(forKey: "dailyRate") as? Double ?? 0
        self.monthlyGross = object.value(forKey: "monthlyGross") as? Double ?? 0
        self.currency = object.value(forKey: "currency") as? String ?? "USD"
        self.netIncome = object.value(forKey: "netIncome") as? Double ?? 0
        self.taxAmount = object.value(forKey: "taxAmount") as? Double ?? 0
        self.fixedCostsTotal = object.value(forKey: "fixedCostsTotal") as? Double ?? 0
        self.amortizationTotal = object.value(forKey: "amortizationTotal") as? Double ?? 0
        self.socialNetTotal = object.value(forKey: "socialNetTotal") as? Double ?? 0
        self.billableHours = object.value(forKey: "billableHours") as? Double ?? 0
        self.notes = object.value(forKey: "notes") as? String ?? ""
    }
    
    var totalCosts: Double {
        taxAmount + fixedCostsTotal + amortizationTotal + socialNetTotal
    }
}

struct ProjectData: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var clientName: String
    var hourlyRate: Double
    var estimatedHours: Double
    var currency: String
    var status: String // active, completed, paused
    var createdAt: Date
    var completedAt: Date?
    var notes: String
    var colorHex: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        clientName: String = "",
        hourlyRate: Double = 0,
        estimatedHours: Double = 0,
        currency: String = "USD",
        status: String = "active",
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        notes: String = "",
        colorHex: String = "007AFF"
    ) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.hourlyRate = hourlyRate
        self.estimatedHours = estimatedHours
        self.currency = currency
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.notes = notes
        self.colorHex = colorHex
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.name = object.value(forKey: "name") as? String ?? ""
        self.clientName = object.value(forKey: "clientName") as? String ?? ""
        self.hourlyRate = object.value(forKey: "hourlyRate") as? Double ?? 0
        self.estimatedHours = object.value(forKey: "estimatedHours") as? Double ?? 0
        self.currency = object.value(forKey: "currency") as? String ?? "USD"
        self.status = object.value(forKey: "status") as? String ?? "active"
        self.createdAt = object.value(forKey: "createdAt") as? Date ?? Date()
        self.completedAt = object.value(forKey: "completedAt") as? Date
        self.notes = object.value(forKey: "notes") as? String ?? ""
        self.colorHex = object.value(forKey: "colorHex") as? String ?? "007AFF"
    }
    
    var estimatedTotal: Double {
        hourlyRate * estimatedHours
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var statusIcon: String {
        switch status {
        case "active": return "play.circle.fill"
        case "completed": return "checkmark.circle.fill"
        case "paused": return "pause.circle.fill"
        default: return "circle"
        }
    }
    
    var statusColor: Color {
        switch status {
        case "active": return .green
        case "completed": return .blue
        case "paused": return .orange
        default: return .gray
        }
    }
    
    static let projectColors = [
        "007AFF", "34C759", "FF9500", "FF3B30", "5856D6",
        "AF52DE", "FF2D55", "00C7BE", "FFD60A", "8E8E93"
    ]
}

struct TimeEntryData: Identifiable, Equatable, Codable {
    var id: UUID
    var projectId: UUID
    var startTime: Date
    var endTime: Date?
    var duration: Double // в секундах
    var notes: String
    var isRunning: Bool
    
    init(
        id: UUID = UUID(),
        projectId: UUID,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: Double = 0,
        notes: String = "",
        isRunning: Bool = false
    ) {
        self.id = id
        self.projectId = projectId
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.notes = notes
        self.isRunning = isRunning
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.projectId = object.value(forKey: "projectId") as? UUID ?? UUID()
        self.startTime = object.value(forKey: "startTime") as? Date ?? Date()
        self.endTime = object.value(forKey: "endTime") as? Date
        self.duration = object.value(forKey: "duration") as? Double ?? 0
        self.notes = object.value(forKey: "notes") as? String ?? ""
        self.isRunning = object.value(forKey: "isRunning") as? Bool ?? false
    }
    
    var durationHours: Double {
        duration / 3600.0
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct GoalData: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var currency: String
    var deadline: Date?
    var createdAt: Date
    var category: String // savings, income, equipment, other
    var isCompleted: Bool
    var notes: String
    var colorHex: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        targetAmount: Double = 0,
        currentAmount: Double = 0,
        currency: String = "USD",
        deadline: Date? = nil,
        createdAt: Date = Date(),
        category: String = "savings",
        isCompleted: Bool = false,
        notes: String = "",
        colorHex: String = "34C759"
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.currency = currency
        self.deadline = deadline
        self.createdAt = createdAt
        self.category = category
        self.isCompleted = isCompleted
        self.notes = notes
        self.colorHex = colorHex
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.name = object.value(forKey: "name") as? String ?? ""
        self.targetAmount = object.value(forKey: "targetAmount") as? Double ?? 0
        self.currentAmount = object.value(forKey: "currentAmount") as? Double ?? 0
        self.currency = object.value(forKey: "currency") as? String ?? "USD"
        self.deadline = object.value(forKey: "deadline") as? Date
        self.createdAt = object.value(forKey: "createdAt") as? Date ?? Date()
        self.category = object.value(forKey: "category") as? String ?? "savings"
        self.isCompleted = object.value(forKey: "isCompleted") as? Bool ?? false
        self.notes = object.value(forKey: "notes") as? String ?? ""
        self.colorHex = object.value(forKey: "colorHex") as? String ?? "34C759"
    }
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    var remainingAmount: Double {
        max(0, targetAmount - currentAmount)
    }
    
    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }
    
    var requiredDailyAmount: Double? {
        guard let days = daysRemaining, days > 0 else { return nil }
        return remainingAmount / Double(days)
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var categoryIcon: String {
        switch category {
        case "savings": return "banknote"
        case "income": return "chart.line.uptrend.xyaxis"
        case "equipment": return "desktopcomputer"
        case "other": return "star"
        default: return "target"
        }
    }
    
    static let categories = [
        "savings": "Savings",
        "income": "Income Target",
        "equipment": "Equipment",
        "other": "Other"
    ]
    
    static let goalColors = [
        "34C759", "007AFF", "FF9500", "FF3B30", "5856D6",
        "AF52DE", "FF2D55", "00C7BE", "FFD60A"
    ]
}

struct MarketRateData: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String // e.g., "Junior iOS Developer"
    var minRate: Double
    var maxRate: Double
    var averageRate: Double
    var currency: String
    var region: String // e.g., "USA", "Europe"
    var source: String // где узнал ставку
    var updatedAt: Date
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String = "",
        minRate: Double = 0,
        maxRate: Double = 0,
        averageRate: Double = 0,
        currency: String = "USD",
        region: String = "",
        source: String = "",
        updatedAt: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.minRate = minRate
        self.maxRate = maxRate
        self.averageRate = averageRate
        self.currency = currency
        self.region = region
        self.source = source
        self.updatedAt = updatedAt
        self.notes = notes
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.name = object.value(forKey: "name") as? String ?? ""
        self.minRate = object.value(forKey: "minRate") as? Double ?? 0
        self.maxRate = object.value(forKey: "maxRate") as? Double ?? 0
        self.averageRate = object.value(forKey: "averageRate") as? Double ?? 0
        self.currency = object.value(forKey: "currency") as? String ?? "USD"
        self.region = object.value(forKey: "region") as? String ?? ""
        self.source = object.value(forKey: "source") as? String ?? ""
        self.updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
        self.notes = object.value(forKey: "notes") as? String ?? ""
    }
    
    var rateRange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        
        let min = formatter.string(from: NSNumber(value: minRate)) ?? "\(Int(minRate))"
        let max = formatter.string(from: NSNumber(value: maxRate)) ?? "\(Int(maxRate))"
        
        return "\(min) - \(max)"
    }
    
    func positionInRange(_ rate: Double) -> Double {
        guard maxRate > minRate else { return 0.5 }
        return (rate - minRate) / (maxRate - minRate)
    }
}

struct CurrencyRateData: Identifiable, Equatable, Codable {
    var id: UUID
    var fromCurrency: String
    var toCurrency: String
    var rate: Double
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        fromCurrency: String = "USD",
        toCurrency: String = "EUR",
        rate: Double = 1.0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.rate = rate
        self.updatedAt = updatedAt
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.fromCurrency = object.value(forKey: "fromCurrency") as? String ?? "USD"
        self.toCurrency = object.value(forKey: "toCurrency") as? String ?? "EUR"
        self.rate = object.value(forKey: "rate") as? Double ?? 1.0
        self.updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
    }
    
    var displayName: String {
        "\(fromCurrency) → \(toCurrency)"
    }
    
    func convert(_ amount: Double) -> Double {
        amount * rate
    }
}

struct ReminderData: Identifiable, Equatable, Codable {
    var id: UUID
    var title: String
    var message: String
    var type: String // rate_review, equipment_check, goal_check, custom
    var triggerDate: Date
    var repeatInterval: String // none, weekly, monthly, quarterly
    var isEnabled: Bool
    var lastTriggered: Date?
    
    init(
        id: UUID = UUID(),
        title: String = "",
        message: String = "",
        type: String = "rate_review",
        triggerDate: Date = Date(),
        repeatInterval: String = "none",
        isEnabled: Bool = true,
        lastTriggered: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.triggerDate = triggerDate
        self.repeatInterval = repeatInterval
        self.isEnabled = isEnabled
        self.lastTriggered = lastTriggered
    }
    
    init(from object: NSManagedObject) {
        self.id = object.value(forKey: "id") as? UUID ?? UUID()
        self.title = object.value(forKey: "title") as? String ?? ""
        self.message = object.value(forKey: "message") as? String ?? ""
        self.type = object.value(forKey: "type") as? String ?? "rate_review"
        self.triggerDate = object.value(forKey: "triggerDate") as? Date ?? Date()
        self.repeatInterval = object.value(forKey: "repeatInterval") as? String ?? "none"
        self.isEnabled = object.value(forKey: "isEnabled") as? Bool ?? true
        self.lastTriggered = object.value(forKey: "lastTriggered") as? Date
    }
    
    var typeIcon: String {
        switch type {
        case "rate_review": return "dollarsign.circle"
        case "equipment_check": return "desktopcomputer"
        case "goal_check": return "target"
        case "custom": return "bell"
        default: return "bell"
        }
    }
    
    var repeatIntervalName: String {
        switch repeatInterval {
        case "none": return "One time"
        case "weekly": return "Weekly"
        case "monthly": return "Monthly"
        case "quarterly": return "Quarterly"
        default: return "Unknown"
        }
    }
    
    static let types = [
        "rate_review": "Rate Review",
        "equipment_check": "Equipment Check",
        "goal_check": "Goal Progress",
        "custom": "Custom"
    ]
    
    static let intervals = [
        "none": "One time",
        "weekly": "Weekly",
        "monthly": "Monthly",
        "quarterly": "Quarterly"
    ]
}

// MARK: - Currency Helper
struct CurrencyHelper {
    static let availableCurrencies = [
        "USD": "US Dollar",
        "EUR": "Euro",
        "GBP": "British Pound",
        "JPY": "Japanese Yen",
        "CHF": "Swiss Franc",
        "CAD": "Canadian Dollar",
        "AUD": "Australian Dollar",
        "NZD": "New Zealand Dollar",
        "CNY": "Chinese Yuan",
        "INR": "Indian Rupee",
        "RUB": "Russian Ruble",
        "BRL": "Brazilian Real",
        "MXN": "Mexican Peso",
        "SGD": "Singapore Dollar",
        "HKD": "Hong Kong Dollar",
        "KRW": "South Korean Won",
        "TRY": "Turkish Lira",
        "PLN": "Polish Zloty",
        "SEK": "Swedish Krona",
        "NOK": "Norwegian Krone",
        "DKK": "Danish Krone",
        "CZK": "Czech Koruna",
        "THB": "Thai Baht",
        "IDR": "Indonesian Rupiah",
        "MYR": "Malaysian Ringgit",
        "PHP": "Philippine Peso",
        "ZAR": "South African Rand",
        "AED": "UAE Dirham",
        "SAR": "Saudi Riyal",
        "ILS": "Israeli Shekel",
        "UAH": "Ukrainian Hryvnia",
        "KZT": "Kazakhstani Tenge",
        "VND": "Vietnamese Dong",
        "TWD": "Taiwan Dollar",
        "CLP": "Chilean Peso",
        "COP": "Colombian Peso",
        "PEN": "Peruvian Sol",
        "ARS": "Argentine Peso",
        "EGP": "Egyptian Pound",
        "NGN": "Nigerian Naira"
    ]
    
    static func symbol(for code: String) -> String {
        let locale = Locale(identifier: "en_US")
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        
        return formatter.currencySymbol ?? code
    }
    
    static func format(_ amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(amount)"
    }
}
