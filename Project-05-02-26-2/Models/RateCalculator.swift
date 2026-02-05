//
//  RateCalculator.swift
//  Hourly Rate Engineer
//
//  Core calculation engine for freelance rate computation
//

import Foundation
import SwiftUI

// MARK: - Rate Calculator
@Observable
@MainActor
final class RateCalculator {
    
    // MARK: - Calculation Result
    struct CalculationResult: Equatable {
        let hourlyRate: Double
        let dailyRate: Double
        let minimumProjectRate: Double
        let monthlyGrossIncome: Double
        let annualGrossIncome: Double
        
        // Breakdown components
        let netIncomeComponent: Double
        let taxComponent: Double
        let fixedCostsComponent: Double
        let amortizationComponent: Double
        let socialNetComponent: Double
        
        // Hours
        let annualBillableHours: Double
        let monthlyBillableHours: Double
        
        var breakdownPercentages: [BreakdownItem] {
            let total = netIncomeComponent + taxComponent + fixedCostsComponent + amortizationComponent + socialNetComponent
            guard total > 0 else { return [] }
            
            return [
                BreakdownItem(name: "Net Income", value: netIncomeComponent, percentage: netIncomeComponent / total, color: .blue),
                BreakdownItem(name: "Taxes", value: taxComponent, percentage: taxComponent / total, color: .red),
                BreakdownItem(name: "Fixed Costs", value: fixedCostsComponent, percentage: fixedCostsComponent / total, color: .orange),
                BreakdownItem(name: "Equipment", value: amortizationComponent, percentage: amortizationComponent / total, color: .purple),
                BreakdownItem(name: "Safety Net", value: socialNetComponent, percentage: socialNetComponent / total, color: .green)
            ]
        }
        
        static let empty = CalculationResult(
            hourlyRate: 0,
            dailyRate: 0,
            minimumProjectRate: 0,
            monthlyGrossIncome: 0,
            annualGrossIncome: 0,
            netIncomeComponent: 0,
            taxComponent: 0,
            fixedCostsComponent: 0,
            amortizationComponent: 0,
            socialNetComponent: 0,
            annualBillableHours: 0,
            monthlyBillableHours: 0
        )
    }
    
    struct BreakdownItem: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let value: Double
        let percentage: Double
        let color: BreakdownColor
        
        static func == (lhs: BreakdownItem, rhs: BreakdownItem) -> Bool {
            lhs.name == rhs.name && lhs.value == rhs.value
        }
    }
    
    enum BreakdownColor {
        case blue, red, orange, purple, green
    }
    
    // MARK: - Main Calculation
    
    /// Calculates the minimum hourly rate based on all inputs
    /// Formula: (Net Income + Taxes + Fixed Costs + Amortization + Social Net) / Billable Hours
    func calculate(
        incomeTarget: IncomeTargetData?,
        timeBudget: TimeBudgetData?,
        equipment: [EquipmentData],
        fixedCosts: [FixedCostData],
        socialNet: SocialNetData?,
        extraEquipmentCost: Double = 0,
        customHoursPerWeek: Double? = nil
    ) -> CalculationResult {
        
        guard let income = incomeTarget,
              let time = timeBudget else {
            return .empty
        }
        
        // 1. Calculate billable hours
        let annualBillableHours: Double
        let monthlyBillableHours: Double
        
        if let customHours = customHoursPerWeek {
            // Custom scenario hours
            let weeksPerYear = 52.0
            let totalWeeksOff = (Double(time.holidays) + Double(time.vacationDays) + Double(time.sickDays)) / Double(time.workingDaysPerWeek)
            let workingWeeks = weeksPerYear - totalWeeksOff
            annualBillableHours = customHours * workingWeeks * (1 - time.nonBillablePercent)
            monthlyBillableHours = annualBillableHours / 12.0
        } else {
            annualBillableHours = time.annualBillableHours
            monthlyBillableHours = time.monthlyBillableHours
        }
        
        guard annualBillableHours > 0 else { return .empty }
        
        // 2. Net income (annual)
        let annualNetIncome = income.netIncome * 12
        
        // 3. Calculate gross income needed (before tax)
        // grossIncome * (1 - taxRate) = netIncome
        // grossIncome = netIncome / (1 - taxRate)
        let taxMultiplier = 1 - income.taxRate
        let annualGrossFromNet = taxMultiplier > 0 ? annualNetIncome / taxMultiplier : annualNetIncome
        let taxAmount = annualGrossFromNet - annualNetIncome
        
        // 4. Fixed costs (annual)
        let annualFixedCosts = fixedCosts.reduce(0) { $0 + $1.amount } * 12
        
        // 5. Equipment amortization (annual)
        let annualAmortization = equipment.reduce(0) { $0 + $1.monthlyAmortization } * 12
        let extraAmortization = extraEquipmentCost / 3 // Assume 3-year lifespan for extra equipment
        let totalAmortization = annualAmortization + extraAmortization
        
        // 6. Social safety net contribution (annual)
        let annualSocialNet: Double
        if let social = socialNet {
            annualSocialNet = social.monthlyContribution(basedOnIncome: income.netIncome) * 12
        } else {
            annualSocialNet = 0
        }
        
        // 7. Total annual required gross income
        let totalAnnualRequired = annualGrossFromNet + annualFixedCosts + totalAmortization + annualSocialNet
        
        // 8. Calculate rates
        let hourlyRate = totalAnnualRequired / annualBillableHours
        let dailyRate = hourlyRate * (time.hoursPerDay * (1 - time.nonBillablePercent))
        let minimumProjectRate = dailyRate * 5 // Minimum 1 week project
        
        return CalculationResult(
            hourlyRate: hourlyRate,
            dailyRate: dailyRate,
            minimumProjectRate: minimumProjectRate,
            monthlyGrossIncome: totalAnnualRequired / 12,
            annualGrossIncome: totalAnnualRequired,
            netIncomeComponent: annualNetIncome / 12,
            taxComponent: taxAmount / 12,
            fixedCostsComponent: annualFixedCosts / 12,
            amortizationComponent: totalAmortization / 12,
            socialNetComponent: annualSocialNet / 12,
            annualBillableHours: annualBillableHours,
            monthlyBillableHours: monthlyBillableHours
        )
    }
    
    // MARK: - Scenario Calculation
    func calculateForScenario(
        baseResult: CalculationResult,
        hoursPerWeek: Double,
        extraEquipmentCost: Double,
        incomeTarget: IncomeTargetData?,
        timeBudget: TimeBudgetData?,
        equipment: [EquipmentData],
        fixedCosts: [FixedCostData],
        socialNet: SocialNetData?
    ) -> CalculationResult {
        return calculate(
            incomeTarget: incomeTarget,
            timeBudget: timeBudget,
            equipment: equipment,
            fixedCosts: fixedCosts,
            socialNet: socialNet,
            extraEquipmentCost: extraEquipmentCost,
            customHoursPerWeek: hoursPerWeek
        )
    }
}

// MARK: - Currency Support
struct CurrencyInfo: Identifiable, Hashable {
    let id: String
    let code: String
    let symbol: String
    let name: String
    
    static let all: [CurrencyInfo] = [
        CurrencyInfo(id: "USD", code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyInfo(id: "EUR", code: "EUR", symbol: "€", name: "Euro"),
        CurrencyInfo(id: "GBP", code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyInfo(id: "JPY", code: "JPY", symbol: "¥", name: "Japanese Yen"),
        CurrencyInfo(id: "CNY", code: "CNY", symbol: "¥", name: "Chinese Yuan"),
        CurrencyInfo(id: "CHF", code: "CHF", symbol: "Fr", name: "Swiss Franc"),
        CurrencyInfo(id: "CAD", code: "CAD", symbol: "C$", name: "Canadian Dollar"),
        CurrencyInfo(id: "AUD", code: "AUD", symbol: "A$", name: "Australian Dollar"),
        CurrencyInfo(id: "NZD", code: "NZD", symbol: "NZ$", name: "New Zealand Dollar"),
        CurrencyInfo(id: "HKD", code: "HKD", symbol: "HK$", name: "Hong Kong Dollar"),
        CurrencyInfo(id: "SGD", code: "SGD", symbol: "S$", name: "Singapore Dollar"),
        CurrencyInfo(id: "SEK", code: "SEK", symbol: "kr", name: "Swedish Krona"),
        CurrencyInfo(id: "NOK", code: "NOK", symbol: "kr", name: "Norwegian Krone"),
        CurrencyInfo(id: "DKK", code: "DKK", symbol: "kr", name: "Danish Krone"),
        CurrencyInfo(id: "KRW", code: "KRW", symbol: "₩", name: "South Korean Won"),
        CurrencyInfo(id: "INR", code: "INR", symbol: "₹", name: "Indian Rupee"),
        CurrencyInfo(id: "RUB", code: "RUB", symbol: "₽", name: "Russian Ruble"),
        CurrencyInfo(id: "BRL", code: "BRL", symbol: "R$", name: "Brazilian Real"),
        CurrencyInfo(id: "MXN", code: "MXN", symbol: "$", name: "Mexican Peso"),
        CurrencyInfo(id: "ZAR", code: "ZAR", symbol: "R", name: "South African Rand"),
        CurrencyInfo(id: "TRY", code: "TRY", symbol: "₺", name: "Turkish Lira"),
        CurrencyInfo(id: "PLN", code: "PLN", symbol: "zł", name: "Polish Zloty"),
        CurrencyInfo(id: "THB", code: "THB", symbol: "฿", name: "Thai Baht"),
        CurrencyInfo(id: "IDR", code: "IDR", symbol: "Rp", name: "Indonesian Rupiah"),
        CurrencyInfo(id: "MYR", code: "MYR", symbol: "RM", name: "Malaysian Ringgit"),
        CurrencyInfo(id: "PHP", code: "PHP", symbol: "₱", name: "Philippine Peso"),
        CurrencyInfo(id: "CZK", code: "CZK", symbol: "Kč", name: "Czech Koruna"),
        CurrencyInfo(id: "HUF", code: "HUF", symbol: "Ft", name: "Hungarian Forint"),
        CurrencyInfo(id: "ILS", code: "ILS", symbol: "₪", name: "Israeli Shekel"),
        CurrencyInfo(id: "CLP", code: "CLP", symbol: "$", name: "Chilean Peso"),
        CurrencyInfo(id: "AED", code: "AED", symbol: "د.إ", name: "UAE Dirham"),
        CurrencyInfo(id: "SAR", code: "SAR", symbol: "﷼", name: "Saudi Riyal"),
        CurrencyInfo(id: "TWD", code: "TWD", symbol: "NT$", name: "Taiwan Dollar"),
        CurrencyInfo(id: "ARS", code: "ARS", symbol: "$", name: "Argentine Peso"),
        CurrencyInfo(id: "COP", code: "COP", symbol: "$", name: "Colombian Peso"),
        CurrencyInfo(id: "VND", code: "VND", symbol: "₫", name: "Vietnamese Dong"),
        CurrencyInfo(id: "EGP", code: "EGP", symbol: "£", name: "Egyptian Pound"),
        CurrencyInfo(id: "RON", code: "RON", symbol: "lei", name: "Romanian Leu"),
        CurrencyInfo(id: "UAH", code: "UAH", symbol: "₴", name: "Ukrainian Hryvnia"),
        CurrencyInfo(id: "BGN", code: "BGN", symbol: "лв", name: "Bulgarian Lev"),
        CurrencyInfo(id: "HRK", code: "HRK", symbol: "kn", name: "Croatian Kuna"),
        CurrencyInfo(id: "PKR", code: "PKR", symbol: "₨", name: "Pakistani Rupee")
    ]
    
    static func symbol(for code: String) -> String {
        all.first { $0.code == code }?.symbol ?? code
    }
}

// MARK: - Tax Regime Support
struct TaxRegimeInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let rate: Double
    let description: String
    
    static let all: [TaxRegimeInfo] = [
        TaxRegimeInfo(id: "NPD", name: "Self-Employed (NPD)", rate: 0.06, description: "6% flat rate for self-employed individuals"),
        TaxRegimeInfo(id: "IP", name: "Individual Entrepreneur (IP)", rate: 0.15, description: "15% simplified taxation system"),
        TaxRegimeInfo(id: "PATENT", name: "Patent System", rate: 0.04, description: "4% fixed patent-based taxation"),
        TaxRegimeInfo(id: "STANDARD", name: "Standard Income Tax", rate: 0.13, description: "13% standard personal income tax"),
        TaxRegimeInfo(id: "PROGRESSIVE", name: "Progressive Tax", rate: 0.22, description: "22% for higher income brackets"),
        TaxRegimeInfo(id: "CORPORATE", name: "Small Business", rate: 0.20, description: "20% corporate tax rate"),
        TaxRegimeInfo(id: "CUSTOM", name: "Custom Rate", rate: 0.0, description: "Enter your own tax rate")
    ]
    
    static func regime(for id: String) -> TaxRegimeInfo? {
        all.first { $0.id == id }
    }
}

// MARK: - Cost Categories
enum CostCategory: String, CaseIterable, Identifiable {
    case rent = "rent"
    case utilities = "utilities"
    case internet = "internet"
    case software = "software"
    case subscriptions = "subscriptions"
    case insurance = "insurance"
    case transport = "transport"
    case education = "education"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rent: return "Rent / Workspace"
        case .utilities: return "Utilities"
        case .internet: return "Internet & Phone"
        case .software: return "Software"
        case .subscriptions: return "Subscriptions"
        case .insurance: return "Insurance"
        case .transport: return "Transportation"
        case .education: return "Education & Training"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .rent: return "building.2"
        case .utilities: return "bolt.fill"
        case .internet: return "wifi"
        case .software: return "laptopcomputer"
        case .subscriptions: return "repeat"
        case .insurance: return "shield.fill"
        case .transport: return "car.fill"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle"
        }
    }
}
