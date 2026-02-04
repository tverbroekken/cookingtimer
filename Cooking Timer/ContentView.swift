//
//  ContentView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 04/02/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.createdAt, order: .reverse) private var meals: [Meal]
    @State private var showingAddMeal = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(meals) { meal in
                    NavigationLink {
                        MealEditorView(meal: meal)
                    } label: {
                        MealRow(meal: meal)
                    }
                }
                .onDelete(perform: deleteMeals)
            }
            .navigationTitle("My Meals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddMeal = true }) {
                        Label("Add Meal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
            .overlay {
                if meals.isEmpty {
                    ContentUnavailableView(
                        "No Meals Yet",
                        systemImage: "fork.knife",
                        description: Text("Add your first meal to get started")
                    )
                }
            }
        }
    }

    private func deleteMeals(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(meals[index])
            }
        }
    }
}

// MARK: - Meal Row
struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.name)
                .font(.headline)
            
            HStack {
                Label("\(meal.timers.count) timers", systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if meal.estimatedTotalTime > 0 {
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(formatDuration(meal.estimatedTotalTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Add Meal View
struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var mealName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Meal Name", text: $mealName)
            }
            .navigationTitle("New Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMeal()
                    }
                    .disabled(mealName.isEmpty)
                }
            }
        }
    }
    
    private func addMeal() {
        withAnimation {
            let newMeal = Meal(name: mealName)
            modelContext.insert(newMeal)
            dismiss()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Meal.self, inMemory: true)
}
