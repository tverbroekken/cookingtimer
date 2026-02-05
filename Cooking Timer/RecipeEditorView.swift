//
//  RecipeEditorView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import SwiftUI
import SwiftData

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var recipe: Recipe? // nil for new recipe, existing recipe for editing
    
    @State private var name: String = ""
    @State private var recipeDescription: String = ""
    @State private var servings: Int = 4
    @State private var prepTimeMinutes: Int = 0
    @State private var cookTimeMinutes: Int = 0
    @State private var difficulty: RecipeDifficulty = .medium
    @State private var ingredients: [IngredientEntry] = []
    @State private var steps: [StepEntry] = []
    @State private var showingAddIngredient = false
    @State private var showingAddStep = false
    
    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        
        if let recipe = recipe {
            _name = State(initialValue: recipe.name)
            _recipeDescription = State(initialValue: recipe.recipeDescription ?? "")
            _servings = State(initialValue: recipe.servings)
            _prepTimeMinutes = State(initialValue: recipe.prepTimeSeconds / 60)
            _cookTimeMinutes = State(initialValue: recipe.cookTimeSeconds / 60)
            _difficulty = State(initialValue: recipe.difficulty)
            _ingredients = State(initialValue: recipe.ingredients.map { ing in
                IngredientEntry(
                    id: ing.id,
                    name: ing.name,
                    quantity: ing.quantity,
                    unit: ing.unit,
                    notes: ing.notes
                )
            })
            _steps = State(initialValue: recipe.steps.sorted(by: { $0.orderIndex < $1.orderIndex }).map { step in
                StepEntry(
                    id: step.id,
                    orderIndex: step.orderIndex,
                    instruction: step.instruction,
                    durationMinutes: (step.durationSeconds ?? 0) / 60,
                    temperature: step.temperature
                )
            })
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("Recipe Name", text: $name)
                        .font(.title3)
                    
                    TextField("Description (optional)", text: $recipeDescription, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Basic Information")
                }
                
                // Details
                Section {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach([RecipeDifficulty.easy, .medium, .hard], id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                    
                    HStack {
                        Text("Prep Time")
                        Spacer()
                        TextField("Minutes", value: $prepTimeMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Cook Time")
                        Spacer()
                        TextField("Minutes", value: $cookTimeMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Details")
                }
                
                // Ingredients
                Section {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredients[index].name)
                                    .font(.subheadline)
                                
                                if ingredients[index].quantity > 0 {
                                    Text("\(formatQuantity(ingredients[index].quantity)) \(ingredients[index].unit)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                ingredients.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    Button {
                        showingAddIngredient = true
                    } label: {
                        Label("Add Ingredient", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Ingredients")
                }
                
                // Steps
                Section {
                    ForEach(steps.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.orange.gradient))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(steps[index].instruction)
                                    .font(.subheadline)
                                
                                if steps[index].durationMinutes > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "timer")
                                            .font(.caption2)
                                        Text("\(steps[index].durationMinutes) min")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                steps.remove(at: index)
                                // Reorder remaining steps
                                for i in steps.indices {
                                    steps[i].orderIndex = i
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { from, to in
                        steps.move(fromOffsets: from, toOffset: to)
                        // Update order indices
                        for i in steps.indices {
                            steps[i].orderIndex = i
                        }
                    }
                    
                    Button {
                        showingAddStep = true
                    } label: {
                        Label("Add Step", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Instructions")
                } footer: {
                    Text("Drag to reorder steps")
                }
            }
            .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(recipe == nil ? "Create" : "Save") {
                        saveRecipe()
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(name.isEmpty)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddIngredientView { ingredient in
                    ingredients.append(ingredient)
                }
            }
            .sheet(isPresented: $showingAddStep) {
                AddStepView(orderIndex: steps.count) { step in
                    steps.append(step)
                }
            }
        }
    }
    
    private func saveRecipe() {
        if let existingRecipe = recipe {
            // Update existing recipe
            existingRecipe.name = name
            existingRecipe.recipeDescription = recipeDescription.isEmpty ? nil : recipeDescription
            existingRecipe.servings = servings
            existingRecipe.prepTimeSeconds = prepTimeMinutes * 60
            existingRecipe.cookTimeSeconds = cookTimeMinutes * 60
            existingRecipe.difficulty = difficulty
            
            // Clear existing ingredients and steps
            for ingredient in existingRecipe.ingredients {
                modelContext.delete(ingredient)
            }
            for step in existingRecipe.steps {
                modelContext.delete(step)
            }
            existingRecipe.ingredients.removeAll()
            existingRecipe.steps.removeAll()
            
            // Add new ingredients
            for entry in ingredients {
                let ingredient = RecipeIngredient(
                    name: entry.name,
                    quantity: entry.quantity,
                    unit: entry.unit
                )
                ingredient.notes = entry.notes
                ingredient.recipe = existingRecipe
                existingRecipe.ingredients.append(ingredient)
                modelContext.insert(ingredient)
            }
            
            // Add new steps
            for entry in steps {
                let step = RecipeStep(
                    orderIndex: entry.orderIndex,
                    instruction: entry.instruction,
                    durationSeconds: entry.durationMinutes > 0 ? entry.durationMinutes * 60 : nil
                )
                step.temperature = entry.temperature
                step.recipe = existingRecipe
                existingRecipe.steps.append(step)
                modelContext.insert(step)
            }
        } else {
            // Create new recipe
            let newRecipe = Recipe(name: name, description: recipeDescription.isEmpty ? nil : recipeDescription)
            newRecipe.servings = servings
            newRecipe.prepTimeSeconds = prepTimeMinutes * 60
            newRecipe.cookTimeSeconds = cookTimeMinutes * 60
            newRecipe.difficulty = difficulty
            
            // Add ingredients
            for entry in ingredients {
                let ingredient = RecipeIngredient(
                    name: entry.name,
                    quantity: entry.quantity,
                    unit: entry.unit
                )
                ingredient.notes = entry.notes
                ingredient.recipe = newRecipe
                newRecipe.ingredients.append(ingredient)
                modelContext.insert(ingredient)
            }
            
            // Add steps
            for entry in steps {
                let step = RecipeStep(
                    orderIndex: entry.orderIndex,
                    instruction: entry.instruction,
                    durationSeconds: entry.durationMinutes > 0 ? entry.durationMinutes * 60 : nil
                )
                step.temperature = entry.temperature
                step.recipe = newRecipe
                newRecipe.steps.append(step)
                modelContext.insert(step)
            }
            
            modelContext.insert(newRecipe)
        }
        
        try? modelContext.save()
        dismiss()
    }
    
    private func formatQuantity(_ quantity: Double) -> String {
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(quantity))
        }
        return String(format: "%.1f", quantity)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Data Structures
struct IngredientEntry: Identifiable {
    var id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var notes: String?
}

struct StepEntry: Identifiable {
    var id = UUID()
    var orderIndex: Int
    var instruction: String
    var durationMinutes: Int
    var temperature: String?
}

// MARK: - Add Ingredient View
struct AddIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (IngredientEntry) -> Void
    
    @State private var name: String = ""
    @State private var quantity: Double = 0
    @State private var unit: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ingredient Name", text: $name)
                    
                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                        
                        TextField("Unit (cups, tbsp, g, etc.)", text: $unit)
                    }
                    
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(IngredientEntry(
                            name: name,
                            quantity: quantity,
                            unit: unit,
                            notes: notes.isEmpty ? nil : notes
                        ))
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Step View
struct AddStepView: View {
    @Environment(\.dismiss) private var dismiss
    let orderIndex: Int
    let onAdd: (StepEntry) -> Void
    
    @State private var instruction: String = ""
    @State private var durationMinutes: Int = 0
    @State private var temperature: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Instruction", text: $instruction, axis: .vertical)
                        .lineLimit(3...10)
                } header: {
                    Text("Step \(orderIndex + 1)")
                }
                
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Minutes", value: $durationMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                    
                    TextField("Temperature (optional)", text: $temperature)
                } header: {
                    Text("Optional Details")
                } footer: {
                    Text("Add a duration if this step requires a timer")
                }
            }
            .navigationTitle("Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(StepEntry(
                            orderIndex: orderIndex,
                            instruction: instruction,
                            durationMinutes: durationMinutes,
                            temperature: temperature.isEmpty ? nil : temperature
                        ))
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(instruction.isEmpty)
                }
            }
        }
    }
}

#Preview {
    RecipeEditorView()
        .modelContainer(for: [Recipe.self, RecipeIngredient.self, RecipeStep.self], inMemory: true)
}
