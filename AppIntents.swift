//
//  AppIntents.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import Foundation
import AppIntents
import SwiftData
import SwiftUI

// MARK: - Meal Entity
struct MealEntity: AppEntity {
    let id: UUID
    let name: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal"
    static var defaultQuery = MealEntityQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

// MARK: - Meal Entity Query
struct MealEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [MealEntity] {
        let modelContainer = try await getModelContainer()
        let context = ModelContext(modelContainer)
        
        let fetchDescriptor = FetchDescriptor<Meal>()
        let meals = try context.fetch(fetchDescriptor)
        
        // Filter in memory
        let filteredMeals = meals.filter { identifiers.contains($0.id) }
        return filteredMeals.map { MealEntity(id: $0.id, name: $0.name) }
    }
    
    func suggestedEntities() async throws -> [MealEntity] {
        let modelContainer = try await getModelContainer()
        let context = ModelContext(modelContainer)
        
        let fetchDescriptor = FetchDescriptor<Meal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let meals = try context.fetch(fetchDescriptor)
        return meals.prefix(5).map { MealEntity(id: $0.id, name: $0.name) }
    }
    
    func defaultResult() async -> MealEntity? {
        try? await suggestedEntities().first
    }
    
    private func getModelContainer() async throws -> ModelContainer {
        try ModelContainer(for: Meal.self, CookingTimer.self)
    }
}

// MARK: - Start Cooking Intent
struct StartCookingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Cooking"
    static var description = IntentDescription("Start cooking a meal with all its timers")
    
    @Parameter(title: "Meal")
    var meal: MealEntity
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let modelContainer = try ModelContainer(for: Meal.self, CookingTimer.self)
        let context = ModelContext(modelContainer)
        
        // Find the meal
        let fetchDescriptor = FetchDescriptor<Meal>()
        let meals = try context.fetch(fetchDescriptor)
        
        guard meals.first(where: { $0.id == meal.id }) != nil else {
            throw $meal.needsValueError("Could not find meal '\(meal.name)'")
        }
        
        // Open the app to the active cooking view
        // This will be handled by the app's deep linking
        return .result(
            dialog: "Starting \(meal.name). Opening the app to begin cooking."
        )
    }
}

// MARK: - Add Timer Intent
struct AddTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Timer"
    static var description = IntentDescription("Add a new timer to a meal")
    
    @Parameter(title: "Meal")
    var meal: MealEntity
    
    @Parameter(title: "Timer Name")
    var timerName: String
    
    @Parameter(title: "Duration (minutes)")
    var durationMinutes: Int
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let modelContainer = try ModelContainer(for: Meal.self, CookingTimer.self)
        let context = ModelContext(modelContainer)
        
        // Find the meal
        let fetchDescriptor = FetchDescriptor<Meal>()
        let meals = try context.fetch(fetchDescriptor)
        
        guard let foundMeal = meals.first(where: { $0.id == meal.id }) else {
            throw $meal.needsValueError("Could not find meal '\(meal.name)'")
        }
        
        // Create and add the new timer
        let newTimer = CookingTimer(
            name: timerName,
            durationSeconds: durationMinutes * 60,
            triggerType: .withMeal
        )
        foundMeal.timers.append(newTimer)
        
        try context.save()
        
        return .result(
            dialog: "Added \(timerName) (\(durationMinutes) minutes) to \(meal.name)"
        )
    }
}

// MARK: - List Meals Intent
struct ListMealsIntent: AppIntent {
    static var title: LocalizedStringResource = "List My Meals"
    static var description = IntentDescription("Show all your saved meals")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & OpensIntent {
        let modelContainer = try ModelContainer(for: Meal.self, CookingTimer.self)
        let context = ModelContext(modelContainer)
        
        let fetchDescriptor = FetchDescriptor<Meal>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let meals = try context.fetch(fetchDescriptor)
        
        if meals.isEmpty {
            return .result(
                dialog: "You don't have any meals yet. Create one in the app!"
            )
        }
        
        let mealNames = meals.map { $0.name }.joined(separator: ", ")
        return .result(
            dialog: "You have \(meals.count) meal(s): \(mealNames)"
        )
    }
}

// MARK: - App Shortcuts Provider
struct CookingTimerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartCookingIntent(),
            phrases: [
                "Start cooking \(\.$meal) in \(.applicationName)",
                "Begin cooking \(\.$meal) in \(.applicationName)",
                "Cook \(\.$meal) with \(.applicationName)"
            ],
            shortTitle: "Start Cooking",
            systemImageName: "flame.fill"
        )
        
        AppShortcut(
            intent: ListMealsIntent(),
            phrases: [
                "List my meals in \(.applicationName)",
                "Show my meals in \(.applicationName)",
                "What meals do I have in \(.applicationName)"
            ],
            shortTitle: "List Meals",
            systemImageName: "list.bullet"
        )
    }
}
