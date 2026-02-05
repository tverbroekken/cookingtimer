//
//  ContentView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 04/02/2026.
//

import SwiftUI
import SwiftData
import AppIntents

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.createdAt, order: .reverse) private var meals: [Meal]
    @State private var showingAddMeal = false
    @State private var showSiriTip = true

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Siri Tip
                    if !meals.isEmpty && showSiriTip {
                        SiriTipView(intent: ListMealsIntent(), isVisible: $showSiriTip)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    ForEach(meals) { meal in
                        NavigationLink {
                            MealEditorView(meal: meal)
                        } label: {
                            MealCard(meal: meal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Meals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddMeal = true }) {
                        Label("Add Meal", systemImage: "plus")
                    }
                    .buttonStyle(.glassProminent)
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

// MARK: - Meal Card
struct MealCard: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange.gradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(meal.createdAt, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 24) {
                StatBadge(
                    icon: "timer",
                    value: "\(meal.timers.count)",
                    label: "Timers"
                )
                
                if meal.estimatedTotalTime > 0 {
                    StatBadge(
                        icon: "clock",
                        value: formatDuration(meal.estimatedTotalTime),
                        label: "Duration"
                    )
                }
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
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
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
                Section {
                    TextField("Meal Name", text: $mealName)
                        .font(.title3)
                } header: {
                    Text("What are you cooking?")
                } footer: {
                    Text("Give your meal a descriptive name like 'Pasta Dinner' or 'Sunday Roast'")
                }
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
                    .buttonStyle(.glassProminent)
                    .disabled(mealName.isEmpty)
                }
            }
        }
    }
    
    private func addMeal() {
        withAnimation(.smooth) {
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
