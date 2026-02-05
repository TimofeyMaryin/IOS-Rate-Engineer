//
//  DataController.swift
//  Hourly Rate Engineer
//
//  Core Data stack with programmatic model creation
//  Extended with History, Projects, Goals, Market Rates
//

import Foundation
import CoreData
import SwiftUI
import UserNotifications

// MARK: - Core Data Controller
@Observable
@MainActor
final class DataController {
    static let shared = DataController()
    
    let container: NSPersistentContainer
    
    // Basic data
    var incomeTarget: IncomeTargetData?
    var timeBudget: TimeBudgetData?
    var equipment: [EquipmentData] = []
    var fixedCosts: [FixedCostData] = []
    var socialNet: SocialNetData?
    var scenarios: [ScenarioData] = []
    
    // Extended data
    var rateHistory: [RateHistoryData] = []
    var projects: [ProjectData] = []
    var timeEntries: [TimeEntryData] = []
    var goals: [GoalData] = []
    var marketRates: [MarketRateData] = []
    var currencyRates: [CurrencyRateData] = []
    var reminders: [ReminderData] = []
    
    private init() {
        // Create programmatic Core Data model
        let model = DataController.createModel()
        container = NSPersistentContainer(name: "HourlyRateEngineer", managedObjectModel: model)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        loadAllData()
    }
    
    // MARK: - Programmatic Model Creation
    nonisolated private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // ============ BASIC ENTITIES ============
        
        // IncomeTarget Entity
        let incomeTargetEntity = NSEntityDescription()
        incomeTargetEntity.name = "IncomeTarget"
        incomeTargetEntity.managedObjectClassName = "IncomeTarget"
        incomeTargetEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("netIncome", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("taxRegime", type: .stringAttributeType, defaultValue: "NPD"),
            createAttribute("taxRate", type: .doubleAttributeType, defaultValue: 0.06),
            createAttribute("currency", type: .stringAttributeType, defaultValue: "USD")
        ]
        
        // TimeBudget Entity
        let timeBudgetEntity = NSEntityDescription()
        timeBudgetEntity.name = "TimeBudget"
        timeBudgetEntity.managedObjectClassName = "TimeBudget"
        timeBudgetEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("workingDaysPerWeek", type: .integer16AttributeType, defaultValue: 5),
            createAttribute("hoursPerDay", type: .doubleAttributeType, defaultValue: 8.0),
            createAttribute("holidays", type: .integer16AttributeType, defaultValue: 10),
            createAttribute("vacationDays", type: .integer16AttributeType, defaultValue: 20),
            createAttribute("sickDays", type: .integer16AttributeType, defaultValue: 5),
            createAttribute("nonBillablePercent", type: .doubleAttributeType, defaultValue: 0.2)
        ]
        
        // Equipment Entity
        let equipmentEntity = NSEntityDescription()
        equipmentEntity.name = "Equipment"
        equipmentEntity.managedObjectClassName = "Equipment"
        equipmentEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("name", type: .stringAttributeType, defaultValue: ""),
            createAttribute("cost", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("lifespan", type: .integer16AttributeType, defaultValue: 3),
            createAttribute("sortOrder", type: .integer16AttributeType, defaultValue: 0),
            createAttribute("purchaseDate", type: .dateAttributeType)
        ]
        
        // FixedCost Entity
        let fixedCostEntity = NSEntityDescription()
        fixedCostEntity.name = "FixedCost"
        fixedCostEntity.managedObjectClassName = "FixedCost"
        fixedCostEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("name", type: .stringAttributeType, defaultValue: ""),
            createAttribute("amount", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("category", type: .stringAttributeType, defaultValue: "other"),
            createAttribute("sortOrder", type: .integer16AttributeType, defaultValue: 0)
        ]
        
        // SocialNet Entity
        let socialNetEntity = NSEntityDescription()
        socialNetEntity.name = "SocialNet"
        socialNetEntity.managedObjectClassName = "SocialNet"
        socialNetEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("sickFundMonths", type: .doubleAttributeType, defaultValue: 1.0),
            createAttribute("safetyNetMonths", type: .doubleAttributeType, defaultValue: 3.0),
            createAttribute("targetSavingMonths", type: .integer16AttributeType, defaultValue: 12)
        ]
        
        // Scenario Entity
        let scenarioEntity = NSEntityDescription()
        scenarioEntity.name = "Scenario"
        scenarioEntity.managedObjectClassName = "Scenario"
        scenarioEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("name", type: .stringAttributeType, defaultValue: ""),
            createAttribute("hoursPerWeek", type: .doubleAttributeType, defaultValue: 40.0),
            createAttribute("extraEquipmentCost", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("createdAt", type: .dateAttributeType),
            createAttribute("calculatedHourlyRate", type: .doubleAttributeType, defaultValue: 0.0)
        ]
        
        // ============ EXTENDED ENTITIES ============
        
        // RateHistory Entity - для истории расчётов
        let rateHistoryEntity = NSEntityDescription()
        rateHistoryEntity.name = "RateHistory"
        rateHistoryEntity.managedObjectClassName = "RateHistory"
        rateHistoryEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("date", type: .dateAttributeType),
            createAttribute("hourlyRate", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("dailyRate", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("monthlyGross", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("currency", type: .stringAttributeType, defaultValue: "USD"),
            createAttribute("netIncome", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("taxAmount", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("fixedCostsTotal", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("amortizationTotal", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("socialNetTotal", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("billableHours", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("notes", type: .stringAttributeType, defaultValue: "")
        ]
        
        // Project Entity - для проектов
        let projectEntity = NSEntityDescription()
        projectEntity.name = "Project"
        projectEntity.managedObjectClassName = "Project"
        projectEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("name", type: .stringAttributeType, defaultValue: ""),
            createAttribute("clientName", type: .stringAttributeType, defaultValue: ""),
            createAttribute("hourlyRate", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("estimatedHours", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("currency", type: .stringAttributeType, defaultValue: "USD"),
            createAttribute("status", type: .stringAttributeType, defaultValue: "active"), // active, completed, paused
            createAttribute("createdAt", type: .dateAttributeType),
            createAttribute("completedAt", type: .dateAttributeType),
            createAttribute("notes", type: .stringAttributeType, defaultValue: ""),
            createAttribute("colorHex", type: .stringAttributeType, defaultValue: "007AFF")
        ]
        
        // TimeEntry Entity - записи времени для проектов
        let timeEntryEntity = NSEntityDescription()
        timeEntryEntity.name = "TimeEntry"
        timeEntryEntity.managedObjectClassName = "TimeEntry"
        timeEntryEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("projectId", type: .UUIDAttributeType),
            createAttribute("startTime", type: .dateAttributeType),
            createAttribute("endTime", type: .dateAttributeType),
            createAttribute("duration", type: .doubleAttributeType, defaultValue: 0.0), // в секундах
            createAttribute("notes", type: .stringAttributeType, defaultValue: ""),
            createAttribute("isRunning", type: .booleanAttributeType, defaultValue: false)
        ]
        
        // Goal Entity - финансовые цели
        let goalEntity = NSEntityDescription()
        goalEntity.name = "Goal"
        goalEntity.managedObjectClassName = "Goal"
        goalEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("name", type: .stringAttributeType, defaultValue: ""),
            createAttribute("targetAmount", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("currentAmount", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("currency", type: .stringAttributeType, defaultValue: "USD"),
            createAttribute("deadline", type: .dateAttributeType),
            createAttribute("createdAt", type: .dateAttributeType),
            createAttribute("category", type: .stringAttributeType, defaultValue: "savings"), // savings, income, equipment, other
            createAttribute("isCompleted", type: .booleanAttributeType, defaultValue: false),
            createAttribute("notes", type: .stringAttributeType, defaultValue: ""),
            createAttribute("colorHex", type: .stringAttributeType, defaultValue: "34C759")
        ]
        
        // MarketRate Entity - рыночные ставки для сравнения
        let marketRateEntity = NSEntityDescription()
        marketRateEntity.name = "MarketRate"
        marketRateEntity.managedObjectClassName = "MarketRate"
        marketRateEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("name", type: .stringAttributeType, defaultValue: ""), // e.g., "Junior iOS Developer"
            createAttribute("minRate", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("maxRate", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("averageRate", type: .doubleAttributeType, defaultValue: 0.0),
            createAttribute("currency", type: .stringAttributeType, defaultValue: "USD"),
            createAttribute("region", type: .stringAttributeType, defaultValue: ""), // e.g., "USA", "Europe"
            createAttribute("source", type: .stringAttributeType, defaultValue: ""), // где узнал ставку
            createAttribute("updatedAt", type: .dateAttributeType),
            createAttribute("notes", type: .stringAttributeType, defaultValue: "")
        ]
        
        // CurrencyRate Entity - пользовательские курсы валют
        let currencyRateEntity = NSEntityDescription()
        currencyRateEntity.name = "CurrencyRate"
        currencyRateEntity.managedObjectClassName = "CurrencyRate"
        currencyRateEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("fromCurrency", type: .stringAttributeType, defaultValue: "USD"),
            createAttribute("toCurrency", type: .stringAttributeType, defaultValue: "EUR"),
            createAttribute("rate", type: .doubleAttributeType, defaultValue: 1.0),
            createAttribute("updatedAt", type: .dateAttributeType)
        ]
        
        // Reminder Entity - напоминания
        let reminderEntity = NSEntityDescription()
        reminderEntity.name = "Reminder"
        reminderEntity.managedObjectClassName = "Reminder"
        reminderEntity.properties = [
            createAttribute("id", type: .UUIDAttributeType),
            createAttribute("title", type: .stringAttributeType, defaultValue: ""),
            createAttribute("message", type: .stringAttributeType, defaultValue: ""),
            createAttribute("type", type: .stringAttributeType, defaultValue: "rate_review"), // rate_review, equipment_check, goal_check
            createAttribute("triggerDate", type: .dateAttributeType),
            createAttribute("repeatInterval", type: .stringAttributeType, defaultValue: "none"), // none, weekly, monthly, quarterly
            createAttribute("isEnabled", type: .booleanAttributeType, defaultValue: true),
            createAttribute("lastTriggered", type: .dateAttributeType)
        ]
        
        model.entities = [
            incomeTargetEntity, timeBudgetEntity, equipmentEntity, fixedCostEntity,
            socialNetEntity, scenarioEntity, rateHistoryEntity, projectEntity,
            timeEntryEntity, goalEntity, marketRateEntity, currencyRateEntity, reminderEntity
        ]
        
        return model
    }
    
    // Helper to create attributes
    nonisolated private static func createAttribute(_ name: String, type: NSAttributeType, defaultValue: Any? = nil) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        if let defaultValue = defaultValue {
            attr.defaultValue = defaultValue
        }
        return attr
    }
    
    // MARK: - Data Loading
    func loadAllData() {
        loadIncomeTarget()
        loadTimeBudget()
        loadEquipment()
        loadFixedCosts()
        loadSocialNet()
        loadScenarios()
        loadRateHistory()
        loadProjects()
        loadTimeEntries()
        loadGoals()
        loadMarketRates()
        loadCurrencyRates()
        loadReminders()
    }
    
    private func loadIncomeTarget() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "IncomeTarget")
        request.fetchLimit = 1
        
        do {
            let results = try container.viewContext.fetch(request)
            if let first = results.first {
                incomeTarget = IncomeTargetData(from: first)
            }
        } catch {
            print("Failed to load income target: \(error)")
        }
    }
    
    private func loadTimeBudget() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TimeBudget")
        request.fetchLimit = 1
        
        do {
            let results = try container.viewContext.fetch(request)
            if let first = results.first {
                timeBudget = TimeBudgetData(from: first)
            }
        } catch {
            print("Failed to load time budget: \(error)")
        }
    }
    
    private func loadEquipment() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Equipment")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let results = try container.viewContext.fetch(request)
            equipment = results.map { EquipmentData(from: $0) }
        } catch {
            print("Failed to load equipment: \(error)")
        }
    }
    
    private func loadFixedCosts() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FixedCost")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        
        do {
            let results = try container.viewContext.fetch(request)
            fixedCosts = results.map { FixedCostData(from: $0) }
        } catch {
            print("Failed to load fixed costs: \(error)")
        }
    }
    
    private func loadSocialNet() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SocialNet")
        request.fetchLimit = 1
        
        do {
            let results = try container.viewContext.fetch(request)
            if let first = results.first {
                socialNet = SocialNetData(from: first)
            }
        } catch {
            print("Failed to load social net: \(error)")
        }
    }
    
    private func loadScenarios() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Scenario")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            scenarios = results.map { ScenarioData(from: $0) }
        } catch {
            print("Failed to load scenarios: \(error)")
        }
    }
    
    private func loadRateHistory() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "RateHistory")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            rateHistory = results.map { RateHistoryData(from: $0) }
        } catch {
            print("Failed to load rate history: \(error)")
        }
    }
    
    private func loadProjects() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Project")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            projects = results.map { ProjectData(from: $0) }
        } catch {
            print("Failed to load projects: \(error)")
        }
    }
    
    private func loadTimeEntries() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TimeEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            timeEntries = results.map { TimeEntryData(from: $0) }
        } catch {
            print("Failed to load time entries: \(error)")
        }
    }
    
    private func loadGoals() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Goal")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            goals = results.map { GoalData(from: $0) }
        } catch {
            print("Failed to load goals: \(error)")
        }
    }
    
    private func loadMarketRates() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MarketRate")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            marketRates = results.map { MarketRateData(from: $0) }
        } catch {
            print("Failed to load market rates: \(error)")
        }
    }
    
    private func loadCurrencyRates() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CurrencyRate")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            currencyRates = results.map { CurrencyRateData(from: $0) }
        } catch {
            print("Failed to load currency rates: \(error)")
        }
    }
    
    private func loadReminders() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Reminder")
        request.sortDescriptors = [NSSortDescriptor(key: "triggerDate", ascending: true)]
        
        do {
            let results = try container.viewContext.fetch(request)
            reminders = results.map { ReminderData(from: $0) }
        } catch {
            print("Failed to load reminders: \(error)")
        }
    }
    
    // MARK: - Basic Save Methods
    func saveIncomeTarget(_ data: IncomeTargetData) {
        let context = container.viewContext
        deleteAll(entityName: "IncomeTarget")
        
        let entity = NSEntityDescription.entity(forEntityName: "IncomeTarget", in: context)!
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(data.id, forKey: "id")
        object.setValue(data.netIncome, forKey: "netIncome")
        object.setValue(data.taxRegime, forKey: "taxRegime")
        object.setValue(data.taxRate, forKey: "taxRate")
        object.setValue(data.currency, forKey: "currency")
        
        saveContext()
        incomeTarget = data
    }
    
    func saveTimeBudget(_ data: TimeBudgetData) {
        let context = container.viewContext
        deleteAll(entityName: "TimeBudget")
        
        let entity = NSEntityDescription.entity(forEntityName: "TimeBudget", in: context)!
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(data.id, forKey: "id")
        object.setValue(data.workingDaysPerWeek, forKey: "workingDaysPerWeek")
        object.setValue(data.hoursPerDay, forKey: "hoursPerDay")
        object.setValue(data.holidays, forKey: "holidays")
        object.setValue(data.vacationDays, forKey: "vacationDays")
        object.setValue(data.sickDays, forKey: "sickDays")
        object.setValue(data.nonBillablePercent, forKey: "nonBillablePercent")
        
        saveContext()
        timeBudget = data
    }
    
    func saveEquipment(_ items: [EquipmentData]) {
        let context = container.viewContext
        deleteAll(entityName: "Equipment")
        
        for (index, item) in items.enumerated() {
            let entity = NSEntityDescription.entity(forEntityName: "Equipment", in: context)!
            let object = NSManagedObject(entity: entity, insertInto: context)
            object.setValue(item.id, forKey: "id")
            object.setValue(item.name, forKey: "name")
            object.setValue(item.cost, forKey: "cost")
            object.setValue(item.lifespan, forKey: "lifespan")
            object.setValue(Int16(index), forKey: "sortOrder")
            object.setValue(item.purchaseDate, forKey: "purchaseDate")
        }
        
        saveContext()
        equipment = items
    }
    
    func saveFixedCosts(_ items: [FixedCostData]) {
        let context = container.viewContext
        deleteAll(entityName: "FixedCost")
        
        for (index, item) in items.enumerated() {
            let entity = NSEntityDescription.entity(forEntityName: "FixedCost", in: context)!
            let object = NSManagedObject(entity: entity, insertInto: context)
            object.setValue(item.id, forKey: "id")
            object.setValue(item.name, forKey: "name")
            object.setValue(item.amount, forKey: "amount")
            object.setValue(item.category, forKey: "category")
            object.setValue(Int16(index), forKey: "sortOrder")
        }
        
        saveContext()
        fixedCosts = items
    }
    
    func saveSocialNet(_ data: SocialNetData) {
        let context = container.viewContext
        deleteAll(entityName: "SocialNet")
        
        let entity = NSEntityDescription.entity(forEntityName: "SocialNet", in: context)!
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(data.id, forKey: "id")
        object.setValue(data.sickFundMonths, forKey: "sickFundMonths")
        object.setValue(data.safetyNetMonths, forKey: "safetyNetMonths")
        object.setValue(data.targetSavingMonths, forKey: "targetSavingMonths")
        
        saveContext()
        socialNet = data
    }
    
    func saveScenario(_ data: ScenarioData) {
        let context = container.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Scenario", in: context)!
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(data.id, forKey: "id")
        object.setValue(data.name, forKey: "name")
        object.setValue(data.hoursPerWeek, forKey: "hoursPerWeek")
        object.setValue(data.extraEquipmentCost, forKey: "extraEquipmentCost")
        object.setValue(data.createdAt, forKey: "createdAt")
        object.setValue(data.calculatedHourlyRate, forKey: "calculatedHourlyRate")
        
        saveContext()
        loadScenarios()
    }
    
    func deleteScenario(_ data: ScenarioData) {
        deleteById(entityName: "Scenario", id: data.id)
        loadScenarios()
    }
    
    // MARK: - Extended Save Methods
    
    func saveRateHistory(_ data: RateHistoryData) {
        let context = container.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "RateHistory", in: context)!
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(data.id, forKey: "id")
        object.setValue(data.date, forKey: "date")
        object.setValue(data.hourlyRate, forKey: "hourlyRate")
        object.setValue(data.dailyRate, forKey: "dailyRate")
        object.setValue(data.monthlyGross, forKey: "monthlyGross")
        object.setValue(data.currency, forKey: "currency")
        object.setValue(data.netIncome, forKey: "netIncome")
        object.setValue(data.taxAmount, forKey: "taxAmount")
        object.setValue(data.fixedCostsTotal, forKey: "fixedCostsTotal")
        object.setValue(data.amortizationTotal, forKey: "amortizationTotal")
        object.setValue(data.socialNetTotal, forKey: "socialNetTotal")
        object.setValue(data.billableHours, forKey: "billableHours")
        object.setValue(data.notes, forKey: "notes")
        
        saveContext()
        loadRateHistory()
    }
    
    func deleteRateHistory(_ data: RateHistoryData) {
        deleteById(entityName: "RateHistory", id: data.id)
        loadRateHistory()
    }
    
    func saveProject(_ data: ProjectData) {
        let context = container.viewContext
        
        // Check if exists
        let request = NSFetchRequest<NSManagedObject>(entityName: "Project")
        request.predicate = NSPredicate(format: "id == %@", data.id as CVarArg)
        
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "Project", in: context)!
            object = NSManagedObject(entity: entity, insertInto: context)
        }
        
        object.setValue(data.id, forKey: "id")
        object.setValue(data.name, forKey: "name")
        object.setValue(data.clientName, forKey: "clientName")
        object.setValue(data.hourlyRate, forKey: "hourlyRate")
        object.setValue(data.estimatedHours, forKey: "estimatedHours")
        object.setValue(data.currency, forKey: "currency")
        object.setValue(data.status, forKey: "status")
        object.setValue(data.createdAt, forKey: "createdAt")
        object.setValue(data.completedAt, forKey: "completedAt")
        object.setValue(data.notes, forKey: "notes")
        object.setValue(data.colorHex, forKey: "colorHex")
        
        saveContext()
        loadProjects()
    }
    
    func deleteProject(_ data: ProjectData) {
        // Also delete related time entries
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "TimeEntry")
        request.predicate = NSPredicate(format: "projectId == %@", data.id as CVarArg)
        if let results = try? context.fetch(request) {
            results.forEach { context.delete($0) }
        }
        
        deleteById(entityName: "Project", id: data.id)
        loadProjects()
        loadTimeEntries()
    }
    
    func saveTimeEntry(_ data: TimeEntryData) {
        let context = container.viewContext
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "TimeEntry")
        request.predicate = NSPredicate(format: "id == %@", data.id as CVarArg)
        
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "TimeEntry", in: context)!
            object = NSManagedObject(entity: entity, insertInto: context)
        }
        
        object.setValue(data.id, forKey: "id")
        object.setValue(data.projectId, forKey: "projectId")
        object.setValue(data.startTime, forKey: "startTime")
        object.setValue(data.endTime, forKey: "endTime")
        object.setValue(data.duration, forKey: "duration")
        object.setValue(data.notes, forKey: "notes")
        object.setValue(data.isRunning, forKey: "isRunning")
        
        saveContext()
        loadTimeEntries()
    }
    
    func deleteTimeEntry(_ data: TimeEntryData) {
        deleteById(entityName: "TimeEntry", id: data.id)
        loadTimeEntries()
    }
    
    func saveGoal(_ data: GoalData) {
        let context = container.viewContext
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "Goal")
        request.predicate = NSPredicate(format: "id == %@", data.id as CVarArg)
        
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "Goal", in: context)!
            object = NSManagedObject(entity: entity, insertInto: context)
        }
        
        object.setValue(data.id, forKey: "id")
        object.setValue(data.name, forKey: "name")
        object.setValue(data.targetAmount, forKey: "targetAmount")
        object.setValue(data.currentAmount, forKey: "currentAmount")
        object.setValue(data.currency, forKey: "currency")
        object.setValue(data.deadline, forKey: "deadline")
        object.setValue(data.createdAt, forKey: "createdAt")
        object.setValue(data.category, forKey: "category")
        object.setValue(data.isCompleted, forKey: "isCompleted")
        object.setValue(data.notes, forKey: "notes")
        object.setValue(data.colorHex, forKey: "colorHex")
        
        saveContext()
        loadGoals()
    }
    
    func deleteGoal(_ data: GoalData) {
        deleteById(entityName: "Goal", id: data.id)
        loadGoals()
    }
    
    func saveMarketRate(_ data: MarketRateData) {
        let context = container.viewContext
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "MarketRate")
        request.predicate = NSPredicate(format: "id == %@", data.id as CVarArg)
        
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "MarketRate", in: context)!
            object = NSManagedObject(entity: entity, insertInto: context)
        }
        
        object.setValue(data.id, forKey: "id")
        object.setValue(data.name, forKey: "name")
        object.setValue(data.minRate, forKey: "minRate")
        object.setValue(data.maxRate, forKey: "maxRate")
        object.setValue(data.averageRate, forKey: "averageRate")
        object.setValue(data.currency, forKey: "currency")
        object.setValue(data.region, forKey: "region")
        object.setValue(data.source, forKey: "source")
        object.setValue(data.updatedAt, forKey: "updatedAt")
        object.setValue(data.notes, forKey: "notes")
        
        saveContext()
        loadMarketRates()
    }
    
    func deleteMarketRate(_ data: MarketRateData) {
        deleteById(entityName: "MarketRate", id: data.id)
        loadMarketRates()
    }
    
    func saveCurrencyRate(_ data: CurrencyRateData) {
        let context = container.viewContext
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "CurrencyRate")
        request.predicate = NSPredicate(format: "id == %@", data.id as CVarArg)
        
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "CurrencyRate", in: context)!
            object = NSManagedObject(entity: entity, insertInto: context)
        }
        
        object.setValue(data.id, forKey: "id")
        object.setValue(data.fromCurrency, forKey: "fromCurrency")
        object.setValue(data.toCurrency, forKey: "toCurrency")
        object.setValue(data.rate, forKey: "rate")
        object.setValue(data.updatedAt, forKey: "updatedAt")
        
        saveContext()
        loadCurrencyRates()
    }
    
    func deleteCurrencyRate(_ data: CurrencyRateData) {
        deleteById(entityName: "CurrencyRate", id: data.id)
        loadCurrencyRates()
    }
    
    func saveReminder(_ data: ReminderData) {
        let context = container.viewContext
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "Reminder")
        request.predicate = NSPredicate(format: "id == %@", data.id as CVarArg)
        
        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "Reminder", in: context)!
            object = NSManagedObject(entity: entity, insertInto: context)
        }
        
        object.setValue(data.id, forKey: "id")
        object.setValue(data.title, forKey: "title")
        object.setValue(data.message, forKey: "message")
        object.setValue(data.type, forKey: "type")
        object.setValue(data.triggerDate, forKey: "triggerDate")
        object.setValue(data.repeatInterval, forKey: "repeatInterval")
        object.setValue(data.isEnabled, forKey: "isEnabled")
        object.setValue(data.lastTriggered, forKey: "lastTriggered")
        
        saveContext()
        loadReminders()
        
        // Schedule notification if enabled
        if data.isEnabled {
            scheduleNotification(for: data)
        } else {
            cancelNotification(for: data)
        }
    }
    
    func deleteReminder(_ data: ReminderData) {
        cancelNotification(for: data)
        deleteById(entityName: "Reminder", id: data.id)
        loadReminders()
    }
    
    // MARK: - Notification Scheduling
    private func scheduleNotification(for reminder: ReminderData) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: reminder.repeatInterval != "none")
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func cancelNotification(for reminder: ReminderData) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    // MARK: - Helper Methods
    private func deleteAll(entityName: String) {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        if let results = try? context.fetch(request) {
            results.forEach { context.delete($0) }
        }
    }
    
    private func deleteById(entityName: String, id: UUID) {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let results = try? context.fetch(request) {
            results.forEach { context.delete($0) }
            saveContext()
        }
    }
    
    private func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    // MARK: - Computed Properties for Analytics
    func timeEntriesForProject(_ projectId: UUID) -> [TimeEntryData] {
        timeEntries.filter { $0.projectId == projectId }
    }
    
    func totalHoursForProject(_ projectId: UUID) -> Double {
        timeEntriesForProject(projectId).reduce(0) { $0 + $1.duration } / 3600.0
    }
    
    func totalEarningsForProject(_ project: ProjectData) -> Double {
        totalHoursForProject(project.id) * project.hourlyRate
    }
    
    func activeProjects() -> [ProjectData] {
        projects.filter { $0.status == "active" }
    }
    
    func completedProjects() -> [ProjectData] {
        projects.filter { $0.status == "completed" }
    }
    
    func activeGoals() -> [GoalData] {
        goals.filter { !$0.isCompleted }
    }
    
    func completedGoals() -> [GoalData] {
        goals.filter { $0.isCompleted }
    }
    
    // Convert amount between currencies
    func convert(_ amount: Double, from: String, to: String) -> Double {
        if from == to { return amount }
        
        // Try direct rate
        if let rate = currencyRates.first(where: { $0.fromCurrency == from && $0.toCurrency == to }) {
            return amount * rate.rate
        }
        
        // Try inverse rate
        if let rate = currencyRates.first(where: { $0.fromCurrency == to && $0.toCurrency == from }) {
            return amount / rate.rate
        }
        
        // No rate found, return original amount
        return amount
    }
    
    // MARK: - Reset All Data
    func resetAllData() {
        let entities = [
            "IncomeTarget", "TimeBudget", "Equipment", "FixedCost", "SocialNet", "Scenario",
            "RateHistory", "Project", "TimeEntry", "Goal", "MarketRate", "CurrencyRate", "Reminder"
        ]
        
        for entityName in entities {
            deleteAll(entityName: entityName)
        }
        
        saveContext()
        
        incomeTarget = nil
        timeBudget = nil
        equipment = []
        fixedCosts = []
        socialNet = nil
        scenarios = []
        rateHistory = []
        projects = []
        timeEntries = []
        goals = []
        marketRates = []
        currencyRates = []
        reminders = []
        
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        // Cancel all notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
