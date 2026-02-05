//
//  RecipeLibraryView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import SwiftUI
import SwiftData

struct RecipeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]
    @State private var showingImportRecipe = false
    @State private var showingCreateRecipe = false
    @State private var searchText = ""
    
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { recipe in
                recipe.name.localizedCaseInsensitiveContains(searchText) ||
                recipe.recipeDescription?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeCard(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingCreateRecipe = true
                        } label: {
                            Label("Create Recipe", systemImage: "pencil")
                        }
                        
                        Button {
                            showingImportRecipe = true
                        } label: {
                            Label("Import from Website", systemImage: "link")
                        }
                    } label: {
                        Label("Add Recipe", systemImage: "plus")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .sheet(isPresented: $showingImportRecipe) {
                RecipeImportView()
            }
            .sheet(isPresented: $showingCreateRecipe) {
                RecipeEditorView()
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "book.closed",
                        description: Text("Import your first recipe from a website")
                    )
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView.search
                }
            }
        }
    }
}

// MARK: - Recipe Card
struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(.orange.gradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if let description = recipe.recipeDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 24) {
                if recipe.prepTimeSeconds > 0 {
                    StatBadge(
                        icon: "clock",
                        value: formatDuration(recipe.prepTimeSeconds),
                        label: "Prep"
                    )
                }
                
                if recipe.cookTimeSeconds > 0 {
                    StatBadge(
                        icon: "flame",
                        value: formatDuration(recipe.cookTimeSeconds),
                        label: "Cook"
                    )
                }
                
                if recipe.totalTimeSeconds > 0 && recipe.prepTimeSeconds == 0 && recipe.cookTimeSeconds == 0 {
                    StatBadge(
                        icon: "clock",
                        value: formatDuration(recipe.totalTimeSeconds),
                        label: "Total"
                    )
                }
                
                StatBadge(
                    icon: "person.2",
                    value: "\(recipe.servings)",
                    label: "Servings"
                )
            }
            
            // Difficulty badge
            HStack {
                Image(systemName: difficultyIcon(for: recipe.difficulty))
                    .font(.caption2)
                Text(recipe.difficulty.rawValue)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(Color(.systemGray6))
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
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

#Preview {
    RecipeLibraryView()
        .modelContainer(for: [Recipe.self, RecipeIngredient.self, RecipeStep.self], inMemory: true)
}
