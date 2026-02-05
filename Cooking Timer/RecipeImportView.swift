//
//  RecipeImportView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import SwiftUI
import SwiftData

struct RecipeImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var recipeURL: String = ""
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var isValid: Bool {
        !recipeURL.isEmpty && (recipeURL.starts(with: "http://") || recipeURL.starts(with: "https://"))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Recipe URL", text: $recipeURL)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("Import from Website")
                } footer: {
                    Text("Paste a URL from popular recipe websites like AllRecipes, Food Network, or Bon Appétit")
                }
                
                if isImporting {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Importing recipe...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        Task {
                            await importRecipe()
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.orange)
                    .disabled(!isValid || isImporting)
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to import recipe")
            }
        }
    }
    
    private func importRecipe() async {
        isImporting = true
        errorMessage = nil
        
        do {
            let parser = RecipeParser()
            let parsed = try await parser.parseRecipe(from: recipeURL)
            
            // Create Recipe model
            let recipe = Recipe(
                name: parsed.name,
                description: parsed.description,
                sourceURL: parsed.sourceURL
            )
            recipe.prepTimeSeconds = parsed.prepTimeSeconds
            recipe.cookTimeSeconds = parsed.cookTimeSeconds
            recipe.servings = parsed.servings
            
            // Add ingredients
            for parsedIng in parsed.ingredients {
                let ingredient = RecipeIngredient(
                    name: parsedIng.name,
                    quantity: parsedIng.quantity,
                    unit: parsedIng.unit
                )
                ingredient.recipe = recipe
                recipe.ingredients.append(ingredient)
                modelContext.insert(ingredient)
            }
            
            // Add steps
            for parsedStep in parsed.steps {
                let step = RecipeStep(
                    orderIndex: parsedStep.orderIndex,
                    instruction: parsedStep.instruction,
                    durationSeconds: parsedStep.durationSeconds
                )
                step.recipe = recipe
                recipe.steps.append(step)
                modelContext.insert(step)
            }
            
            modelContext.insert(recipe)
            try modelContext.save()
            
            dismiss()
        } catch let error as RecipeParser.ParserError {
            switch error {
            case .invalidURL:
                errorMessage = "Invalid URL. Please enter a valid recipe URL."
            case .networkError(let underlying):
                errorMessage = "Network error: \(underlying.localizedDescription)"
            case .parsingError:
                errorMessage = "Could not parse recipe. The website may not be supported."
            case .noRecipeFound:
                errorMessage = "No recipe found at this URL."
            }
            showError = true
            isImporting = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isImporting = false
        }
    }
}

#Preview {
    RecipeImportView()
        .modelContainer(for: [Recipe.self, RecipeIngredient.self, RecipeStep.self], inMemory: true)
}
