//
//  MealEditorView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 04/02/2026.
//

import SwiftUI
import SwiftData

struct MealEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let meal: Meal
    
    @State private var showingAddTimer = false
    @State private var showingCookingView = false
    
    var body: some View {
        List {
            Section("Timers") {
                if meal.timers.isEmpty {
                    ContentUnavailableView(
                        "No Timers",
                        systemImage: "timer",
                        description: Text("Add timers for each dish in your meal")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(meal.timers) { timer in
                        NavigationLink {
                            TimerDetailView(timer: timer, meal: meal)
                        } label: {
                            TimerRow(timer: timer, meal: meal)
                        }
                    }
                    .onDelete(perform: deleteTimers)
                }
            }
            
            if !meal.timers.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Estimated Total Time", systemImage: "clock")
                            .font(.headline)
                        Text(formatDuration(meal.estimatedTotalTime))
                            .font(.title2)
                            .bold()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTimer = true
                } label: {
                    Label("Add Timer", systemImage: "plus")
                }
            }
            
            if !meal.timers.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingCookingView = true
                    } label: {
                        Label("Start Cooking", systemImage: "flame.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showingAddTimer) {
            AddTimerView(meal: meal)
        }
        .fullScreenCover(isPresented: $showingCookingView) {
            ActiveCookingView(meal: meal)
        }
    }
    
    private func deleteTimers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let timer = meal.timers[index]
                modelContext.delete(timer)
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Timer Row
struct TimerRow: View {
    let timer: CookingTimer
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(timer.name)
                .font(.headline)
            
            HStack {
                Label(formatDuration(timer.durationSeconds), systemImage: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Text(triggerDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var triggerDescription: String {
        switch timer.triggerType {
        case .manual:
            return "Manual start"
        case .withMeal:
            return "Start with meal"
        case .afterTimer:
            if let trigger = timer.triggerTimer {
                return "After \(trigger.name) starts"
            }
            return "After another timer"
        case .whenTimerCompletes:
            if let trigger = timer.triggerTimer {
                return "When \(trigger.name) completes"
            }
            return "When another timer completes"
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 && secs > 0 {
            return "\(minutes)m \(secs)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Add Timer View
struct AddTimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let meal: Meal
    
    @State private var timerName = ""
    @State private var minutes = 10
    @State private var seconds = 0
    @State private var triggerType: TriggerType = .withMeal
    @State private var selectedTriggerTimer: CookingTimer?
    @State private var triggerDelayMinutes = 0
    @State private var triggerDelaySeconds = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Timer Details") {
                    TextField("Name (e.g., Pasta, Sauce)", text: $timerName)
                    
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0...120, id: \.self) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                    
                    Picker("Seconds", selection: $seconds) {
                        ForEach(0...59, id: \.self) { sec in
                            Text("\(sec) sec").tag(sec)
                        }
                    }
                }
                
                Section("Start Trigger") {
                    Picker("When to Start", selection: $triggerType) {
                        Text("Manual").tag(TriggerType.manual)
                        Text("With Meal").tag(TriggerType.withMeal)
                        if !meal.timers.isEmpty {
                            Text("After Timer Starts").tag(TriggerType.afterTimer)
                            Text("When Timer Completes").tag(TriggerType.whenTimerCompletes)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if triggerType == .afterTimer || triggerType == .whenTimerCompletes {
                        Picker("Which Timer?", selection: $selectedTriggerTimer) {
                            Text("Select Timer").tag(nil as CookingTimer?)
                            ForEach(meal.timers) { timer in
                                Text(timer.name).tag(timer as CookingTimer?)
                            }
                        }
                        
                        if triggerType == .afterTimer {
                            Picker("Delay (Minutes)", selection: $triggerDelayMinutes) {
                                ForEach(0...60, id: \.self) { min in
                                    Text("\(min) min").tag(min)
                                }
                            }
                            
                            Picker("Delay (Seconds)", selection: $triggerDelaySeconds) {
                                ForEach(0...59, id: \.self) { sec in
                                    Text("\(sec) sec").tag(sec)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTimer()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard !timerName.isEmpty else { return false }
        guard minutes > 0 || seconds > 0 else { return false }
        
        if triggerType == .afterTimer || triggerType == .whenTimerCompletes {
            return selectedTriggerTimer != nil
        }
        
        return true
    }
    
    private func addTimer() {
        let totalSeconds = (minutes * 60) + seconds
        let delaySeconds = (triggerDelayMinutes * 60) + triggerDelaySeconds
        
        let newTimer = CookingTimer(
            name: timerName,
            durationSeconds: totalSeconds,
            triggerType: triggerType,
            triggerDelay: delaySeconds,
            triggerTimer: selectedTriggerTimer
        )
        
        newTimer.meal = meal
        modelContext.insert(newTimer)
        meal.timers.append(newTimer)
        
        dismiss()
    }
}

// MARK: - Timer Detail View (Placeholder)
struct TimerDetailView: View {
    let timer: CookingTimer
    let meal: Meal
    
    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Duration", value: formatDuration(timer.durationSeconds))
                LabeledContent("Trigger", value: triggerDescription)
            }
        }
        .navigationTitle(timer.name)
    }
    
    private var triggerDescription: String {
        switch timer.triggerType {
        case .manual:
            return "Manual start"
        case .withMeal:
            return "Start with meal"
        case .afterTimer:
            if let trigger = timer.triggerTimer {
                return "\(formatDuration(timer.triggerDelay)) after \(trigger.name) starts"
            }
            return "After another timer"
        case .whenTimerCompletes:
            if let trigger = timer.triggerTimer {
                return "When \(trigger.name) completes"
            }
            return "When another timer completes"
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 && secs > 0 {
            return "\(minutes)m \(secs)s"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(secs)s"
        }
    }
}


