//
//  RecipeDetailView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let recipe: Recipe
    @State private var showingDeleteAlert = false
    @State private var showingCreateMeal = false
    @State private var newMealName = ""
    @State private var createdMeal: Meal?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                VStack(alignment: .leading, spacing: 12) {
                    // Recipe metadata
                    HStack(spacing: 16) {
                        if recipe.prepTimeSeconds > 0 {
                            MetadataItem(
                                icon: "clock",
                                label: "Prep",
                                value: formatDuration(recipe.prepTimeSeconds)
                            )
                        }
                        
                        if recipe.cookTimeSeconds > 0 {
                            MetadataItem(
                                icon: "flame",
                                label: "Cook",
                                value: formatDuration(recipe.cookTimeSeconds)
                            )
                        }
                        
                        MetadataItem(
                            icon: "person.2",
                            label: "Servings",
                            value: "\(recipe.servings)"
                        )
                        
                        MetadataItem(
                            icon: difficultyIcon(for: recipe.difficulty),
                            label: "Difficulty",
                            value: recipe.difficulty.rawValue
                        )
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    }
                    
                    // Description
                    if let description = recipe.recipeDescription {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Ingredients section
                if !recipe.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(recipe.ingredients.sorted(by: { $0.name < $1.name })) { ingredient in
                                IngredientRow(ingredient: ingredient)
                            }
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.background)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Instructions section
                if !recipe.steps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            ForEach(recipe.steps.sorted(by: { $0.orderIndex < $1.orderIndex })) { step in
                                StepRow(step: step)
                            }
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.background)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Create Meal button
                Button {
                    newMealName = recipe.name
                    showingCreateMeal = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Meal from Recipe")
                        Spacer()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.orange.gradient)
                    }
                }
                .padding(.horizontal)
                
                // Source link
                if let sourceURL = recipe.sourceURL, !sourceURL.isEmpty {
                    Link(destination: URL(string: sourceURL)!) {
                        HStack {
                            Image(systemName: "link")
                            Text("View Original Recipe")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray6))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete Recipe?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showingCreateMeal) {
            CreateMealFromRecipeView(recipe: recipe, mealName: $newMealName, createdMeal: $createdMeal)
        }
        .navigationDestination(item: $createdMeal) { meal in
            MealEditorView(meal: meal)
        }
    }
    
    private func deleteRecipe() {
        modelContext.delete(recipe)
        try? modelContext.save()
        dismiss()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
    }
    
    private func difficultyIcon(for difficulty: RecipeDifficulty) -> String {
        switch difficulty {
        case .easy:
            return "star.fill"
        case .medium:
            return "star.leadinghalf.filled"
        case .hard:
            return "star.slash"
        }
    }
}

// MARK: - Metadata Item
struct MetadataItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange.gradient)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ingredient Row
struct IngredientRow: View {
    let ingredient: RecipeIngredient
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(.orange)
            
            if ingredient.quantity > 0 {
                Text(formatQuantity(ingredient.quantity))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 40, alignment: .trailing)
                
                if !ingredient.unit.isEmpty {
                    Text(ingredient.unit)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 60, alignment: .leading)
                }
            }
            
            Text(ingredient.name)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
    
    private func formatQuantity(_ quantity: Double) -> String {
        // Format as fraction if possible
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(quantity))
        } else if quantity == 0.5 {
            return "½"
        } else if quantity == 0.25 {
            return "¼"
        } else if quantity == 0.75 {
            return "¾"
        } else if quantity == 0.33 {
            return "⅓"
        } else if quantity == 0.67 {
            return "⅔"
        } else {
            return String(format: "%.1f", quantity)
        }
    }
}

// MARK: - Step Row
struct StepRow: View {
    let step: RecipeStep
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number badge
            Text("\(step.orderIndex + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background {
                    Circle()
                        .fill(.orange.gradient)
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(step.instruction)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                // Duration badge if available
                if let duration = step.durationSeconds, duration > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text(formatDuration(duration))
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(Color(.systemGray6))
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Create Meal from Recipe View
struct CreateMealFromRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let recipe: Recipe
    @Binding var mealName: String
    @Binding var createdMeal: Meal?
    @State private var selectedSteps: Set<UUID> = []
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Meal Name", text: $mealName)
                        .font(.title3)
                } header: {
                    Text("Meal Name")
                } footer: {
                    Text("Give your meal a descriptive name")
                }
                
                if !recipe.steps.isEmpty {
                    Section {
                        ForEach(recipe.steps.sorted(by: { $0.orderIndex < $1.orderIndex })) { step in
                            if step.durationSeconds != nil && step.durationSeconds! > 0 {
                                Toggle(isOn: Binding(
                                    get: { selectedSteps.contains(step.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedSteps.insert(step.id)
                                        } else {
                                            selectedSteps.remove(step.id)
                                        }
                                    }
                                )) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Step \(step.orderIndex + 1)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text(step.instruction)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                        
                                        if let duration = step.durationSeconds {
                                            HStack(spacing: 4) {
                                                Image(systemName: "timer")
                                                    .font(.caption2)
                                                Text(formatDuration(duration))
                                                    .font(.caption2)
                                            }
                                            .foregroundStyle(.orange)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    } header: {
                        Text("Select Timers to Create")
                    } footer: {
                        Text("Choose which recipe steps should become timers in your meal")
                    }
                }
                
                if recipe.steps.filter({ $0.durationSeconds != nil && $0.durationSeconds! > 0 }).isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This recipe has no timed steps")
                                .foregroundStyle(.secondary)
                            
                            if recipe.cookTimeSeconds > 0 || recipe.totalTimeSeconds > 0 {
                                Text("A timer will be created based on the recipe's total cooking time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Auto-select all timed steps
                let timedSteps = recipe.steps.filter { 
                    $0.durationSeconds != nil && $0.durationSeconds! > 0 
                }
                selectedSteps = Set(timedSteps.map { $0.id })
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        createMeal()
                    } label: {
                        if selectedSteps.isEmpty {
                            Text("Create")
                        } else {
                            Text("Create (\(selectedSteps.count))")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(mealName.isEmpty || isCreating)
                }
            }
        }
    }
    
    private func createMeal() {
        isCreating = true
        
        withAnimation(.smooth) {
            // Create new meal
            let newMeal = Meal(name: mealName)
            
            // Link recipe to meal
            recipe.mealID = newMeal.id
            
            // Create timers from selected steps
            let stepsToConvert = recipe.steps.filter { selectedSteps.contains($0.id) }
            
            if !stepsToConvert.isEmpty {
                // Create timers from recipe steps
                let sortedSteps = stepsToConvert.sorted(by: { $0.orderIndex < $1.orderIndex })
                var isFirstTimer = true
                var timerIndex = 0
                
                for step in sortedSteps {
                    guard let duration = step.durationSeconds, duration > 0 else { continue }
                    
                    let timer = CookingTimer(
                        name: "Step \(step.orderIndex + 1): \(step.instruction.prefix(50))",
                        durationSeconds: duration,
                        triggerType: isFirstTimer ? .withMeal : .whenTimerCompletes,
                        triggerDelay: 0,
                        triggerTimerID: isFirstTimer ? nil : newMeal.timers.last?.id,
                        orderIndex: timerIndex
                    )
                    timer.meal = newMeal
                    
                    newMeal.timers.append(timer)
                    modelContext.insert(timer)
                    
                    isFirstTimer = false
                    timerIndex += 1
                }
            } else if recipe.cookTimeSeconds > 0 || recipe.totalTimeSeconds > 0 {
                // Fallback: Create a single timer based on cooking time
                let duration = recipe.cookTimeSeconds > 0 ? recipe.cookTimeSeconds : recipe.totalTimeSeconds
                let timer = CookingTimer(
                    name: recipe.name,
                    durationSeconds: duration,
                    triggerType: .withMeal,
                    triggerDelay: 0,
                    triggerTimerID: nil,
                    orderIndex: 0
                )
                timer.meal = newMeal
                
                newMeal.timers.append(timer)
                modelContext.insert(timer)
            }
            
            modelContext.insert(newMeal)
            
            try? modelContext.save()
            
            // Set the created meal to trigger navigation
            createdMeal = newMeal
            
            dismiss()
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: {
            let recipe = Recipe(name: "Pasta Carbonara", description: "Classic Italian pasta dish")
            recipe.prepTimeSeconds = 600
            recipe.cookTimeSeconds = 900
            recipe.servings = 4
            recipe.difficulty = .medium
            
            let ing1 = RecipeIngredient(name: "Spaghetti", quantity: 400, unit: "g")
            let ing2 = RecipeIngredient(name: "Eggs", quantity: 4, unit: "")
            recipe.ingredients = [ing1, ing2]
            
            let step1 = RecipeStep(orderIndex: 0, instruction: "Boil water and cook pasta", durationSeconds: 600)
            let step2 = RecipeStep(orderIndex: 1, instruction: "Mix eggs and cheese")
            recipe.steps = [step1, step2]
            
            return recipe
        }())
    }
    .modelContainer(for: [Recipe.self, RecipeIngredient.self, RecipeStep.self], inMemory: true)
}
