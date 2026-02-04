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
        ScrollView {
            VStack(spacing: 20) {
                // Header Card with total time
                if !meal.timers.isEmpty {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Total Cooking Time", systemImage: "clock.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(formatDuration(meal.estimatedTotalTime))
                                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                    .foregroundStyle(.orange.gradient)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "timer")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange.opacity(0.3))
                        }
                        
                        Button {
                            showingCookingView = true
                        } label: {
                            Label("Start Cooking", systemImage: "flame.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.orange)
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                    }
                    .padding(.horizontal)
                }
                
                // Timers Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Timers")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if meal.timers.isEmpty {
                        ContentUnavailableView(
                            "No Timers Yet",
                            systemImage: "timer",
                            description: Text("Add timers for each dish in your meal")
                        )
                        .padding(.vertical, 60)
                    } else {
                        ForEach(meal.timers) { timer in
                            NavigationLink {
                                TimerDetailView(timer: timer, meal: meal)
                            } label: {
                                TimerCard(timer: timer, meal: meal)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTimer = true
                } label: {
                    Label("Add Timer", systemImage: "plus")
                }
                .buttonStyle(.glassProminent)
            }
        }
        .sheet(isPresented: $showingAddTimer) {
            AddTimerView(meal: meal)
        }
        .fullScreenCover(isPresented: $showingCookingView) {
            ActiveCookingView(meal: meal)
        }
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

// MARK: - Timer Card
struct TimerCard: View {
    let timer: CookingTimer
    let meal: Meal
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(triggerColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: triggerIcon)
                    .font(.title3)
                    .foregroundStyle(triggerColor.gradient)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(timer.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    Label(formatDuration(timer.durationSeconds), systemImage: "timer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(triggerDescription)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }
    
    private var triggerIcon: String {
        switch timer.triggerType {
        case .manual:
            return "hand.tap.fill"
        case .withMeal:
            return "play.circle.fill"
        case .afterTimer:
            return "clock.arrow.circlepath"
        case .whenTimerCompletes:
            return "checkmark.circle.fill"
        }
    }
    
    private var triggerColor: Color {
        switch timer.triggerType {
        case .manual:
            return .blue
        case .withMeal:
            return .green
        case .afterTimer:
            return .orange
        case .whenTimerCompletes:
            return .purple
        }
    }
    
    private var triggerDescription: String {
        switch timer.triggerType {
        case .manual:
            return "Manual start"
        case .withMeal:
            return "With meal"
        case .afterTimer:
            if let trigger = timer.getTriggerTimer(from: meal) {
                return "After \(trigger.name)"
            }
            return "After timer"
        case .whenTimerCompletes:
            if let trigger = timer.getTriggerTimer(from: meal) {
                return "When \(trigger.name) ends"
            }
            return "After completion"
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
    @State private var selectedTriggerTimerID: UUID?
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
                    .onChange(of: triggerType) { oldValue, newValue in
                        // Reset dependent timer selection when trigger type changes
                        if newValue != .afterTimer && newValue != .whenTimerCompletes {
                            selectedTriggerTimerID = nil
                        }
                    }
                    
                    if triggerType == .afterTimer || triggerType == .whenTimerCompletes {
                        if meal.timers.isEmpty {
                            Text("Add other timers first to create dependencies")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Which Timer?", selection: $selectedTriggerTimerID) {
                                Text("Select Timer").tag(nil as UUID?)
                                ForEach(meal.timers) { timer in
                                    Text(timer.name).tag(timer.id as UUID?)
                                }
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
            return selectedTriggerTimerID != nil
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
            triggerTimerID: selectedTriggerTimerID
        )
        
        newTimer.meal = meal
        modelContext.insert(newTimer)
        meal.timers.append(newTimer)
        
        dismiss()
    }
}

// MARK: - Timer Detail View
struct TimerDetailView: View {
    let timer: CookingTimer
    let meal: Meal
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Duration", value: formatDuration(timer.durationSeconds))
                LabeledContent("Trigger", value: triggerDescription)
            }
        }
        .navigationTitle(timer.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTimerView(timer: timer, meal: meal)
        }
    }
    
    private var triggerDescription: String {
        switch timer.triggerType {
        case .manual:
            return "Manual start"
        case .withMeal:
            return "Start with meal"
        case .afterTimer:
            if let trigger = timer.getTriggerTimer(from: meal) {
                return "\(formatDuration(timer.triggerDelay)) after \(trigger.name) starts"
            }
            return "After another timer"
        case .whenTimerCompletes:
            if let trigger = timer.getTriggerTimer(from: meal) {
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

// MARK: - Edit Timer View
struct EditTimerView: View {
    @Environment(\.dismiss) private var dismiss
    let timer: CookingTimer
    let meal: Meal
    
    @State private var timerName: String
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var triggerType: TriggerType
    @State private var selectedTriggerTimerID: UUID?
    @State private var triggerDelayMinutes: Int
    @State private var triggerDelaySeconds: Int
    
    init(timer: CookingTimer, meal: Meal) {
        self.timer = timer
        self.meal = meal
        
        _timerName = State(initialValue: timer.name)
        _minutes = State(initialValue: timer.durationSeconds / 60)
        _seconds = State(initialValue: timer.durationSeconds % 60)
        _triggerType = State(initialValue: timer.triggerType)
        _selectedTriggerTimerID = State(initialValue: timer.triggerTimerID)
        _triggerDelayMinutes = State(initialValue: timer.triggerDelay / 60)
        _triggerDelaySeconds = State(initialValue: timer.triggerDelay % 60)
    }
    
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
                        if availableTimers.count > 0 {
                            Text("After Timer Starts").tag(TriggerType.afterTimer)
                            Text("When Timer Completes").tag(TriggerType.whenTimerCompletes)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: triggerType) { oldValue, newValue in
                        if newValue != .afterTimer && newValue != .whenTimerCompletes {
                            selectedTriggerTimerID = nil
                        }
                    }
                    
                    if triggerType == .afterTimer || triggerType == .whenTimerCompletes {
                        if availableTimers.isEmpty {
                            Text("No other timers available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Which Timer?", selection: $selectedTriggerTimerID) {
                                Text("Select Timer").tag(nil as UUID?)
                                ForEach(availableTimers) { availableTimer in
                                    Text(availableTimer.name).tag(availableTimer.id as UUID?)
                                }
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
            .navigationTitle("Edit Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var availableTimers: [CookingTimer] {
        meal.timers.filter { $0.id != timer.id }
    }
    
    private var isValid: Bool {
        guard !timerName.isEmpty else { return false }
        guard minutes > 0 || seconds > 0 else { return false }
        
        if triggerType == .afterTimer || triggerType == .whenTimerCompletes {
            return selectedTriggerTimerID != nil
        }
        
        return true
    }
    
    private func saveChanges() {
        timer.name = timerName
        timer.durationSeconds = (minutes * 60) + seconds
        timer.triggerType = triggerType
        timer.triggerDelay = (triggerDelayMinutes * 60) + triggerDelaySeconds
        timer.triggerTimerID = selectedTriggerTimerID
        
        dismiss()
    }
}


