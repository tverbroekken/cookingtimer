//
//  ActiveCookingView.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 04/02/2026.
//

import SwiftUI
import Combine

struct ActiveCookingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let meal: Meal
    
    @State private var timerManager: TimerManager
    
    init(meal: Meal) {
        self.meal = meal
        _timerManager = State(initialValue: TimerManager(meal: meal))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Burner Grid
                        burnerGrid
                        
                        // Controls
                        if !timerManager.hasStarted {
                            startButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        timerManager.stopAll()
                        dismiss()
                    }
                }
            }
            .onAppear {
                timerManager.setupTimers()
            }
            .onDisappear {
                timerManager.stopAll()
            }
        }
    }
    
    private var burnerGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
        
        return LazyVGrid(columns: columns, spacing: 20) {
            ForEach(meal.timers) { timer in
                BurnerView(
                    timer: timer,
                    status: timerManager.timerStates[timer.id] ?? .waiting,
                    onTap: {
                        timerManager.togglePause(timer)
                    }
                )
            }
        }
    }
    
    private var startButton: some View {
        Button {
            timerManager.startMeal()
        } label: {
            Label("Start Cooking", systemImage: "flame.fill")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.orange.gradient)
                )
        }
        .padding(.horizontal)
    }
}

// MARK: - Burner View
struct BurnerView: View {
    let timer: CookingTimer
    let status: TimerStatus
    let onTap: () -> Void
    
    @State private var glowIntensity: Double = 0
    @State private var remainingTime: Int = 0
    
    let timerPublisher = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Burner base
                Circle()
                    .fill(burnerColor)
                    .frame(width: 150, height: 150)
                    .overlay(
                        Circle()
                            .stroke(lineWidth: 8)
                            .fill(ringColor)
                    )
                    .shadow(color: glowColor.opacity(glowIntensity), radius: 30)
                
                // Timer info
                VStack(spacing: 8) {
                    Text(timer.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text(formattedTime)
                        .font(.title2)
                        .fontDesign(.monospaced)
                        .bold()
                        .foregroundStyle(.white)
                    
                    if status != .waiting {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
        .onReceive(timerPublisher) { _ in
            updateTimer()
        }
        .onAppear {
            updateTimer()
        }
    }
    
    private var burnerColor: Color {
        switch status {
        case .waiting:
            return Color(white: 0.2)
        case .running:
            return Color.orange.opacity(0.3)
        case .paused:
            return Color.yellow.opacity(0.2)
        case .completed:
            return Color.green.opacity(0.2)
        }
    }
    
    private var ringColor: Color {
        switch status {
        case .waiting:
            return Color(white: 0.3)
        case .running:
            return Color.orange
        case .paused:
            return Color.yellow
        case .completed:
            return Color.green
        }
    }
    
    private var glowColor: Color {
        switch status {
        case .waiting:
            return .clear
        case .running:
            return .orange
        case .paused:
            return .yellow
        case .completed:
            return .green
        }
    }
    
    private var statusText: String {
        switch status {
        case .waiting:
            return "Waiting"
        case .running:
            return "Cooking"
        case .paused:
            return "Paused"
        case .completed:
            return "Done!"
        }
    }
    
    private var formattedTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateTimer() {
        remainingTime = timer.remainingSeconds
        
        // Update glow intensity based on progress
        if status == .running {
            glowIntensity = 0.3 + (sin(Date().timeIntervalSinceReferenceDate * 2) * 0.2)
        } else {
            glowIntensity = status == .completed ? 0.5 : 0
        }
    }
}

// MARK: - Timer Manager
@Observable
class TimerManager {
    let meal: Meal
    var timerStates: [UUID: TimerStatus] = [:]
    var hasStarted = false
    
    private var updateTimer: Timer?
    
    init(meal: Meal) {
        self.meal = meal
    }
    
    func setupTimers() {
        for timer in meal.timers {
            timerStates[timer.id] = timer.status
        }
    }
    
    func startMeal() {
        hasStarted = true
        
        // Start all timers that should start with the meal
        for timer in meal.timers {
            if timer.triggerType == .withMeal {
                startTimer(timer)
            }
        }
        
        // Start monitoring for dependent timers
        startMonitoring()
    }
    
    func startTimer(_ timer: CookingTimer) {
        timer.status = .running
        timer.startTime = Date()
        timerStates[timer.id] = .running
        
        // Check if any other timers should start based on this one
        checkDependentTimers(for: timer)
    }
    
    func togglePause(_ timer: CookingTimer) {
        if timer.status == .running {
            timer.status = .paused
            timer.pausedTimeRemaining = timer.remainingSeconds
            timerStates[timer.id] = .paused
        } else if timer.status == .paused {
            timer.status = .running
            timer.startTime = Date().addingTimeInterval(-Double(timer.durationSeconds - (timer.pausedTimeRemaining ?? 0)))
            timer.pausedTimeRemaining = nil
            timerStates[timer.id] = .running
        } else if timer.status == .waiting {
            startTimer(timer)
        }
    }
    
    func stopAll() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateTimers()
        }
    }
    
    private func updateTimers() {
        for timer in meal.timers {
            if timer.status == .running {
                if timer.remainingSeconds <= 0 {
                    completeTimer(timer)
                }
            }
        }
    }
    
    private func completeTimer(_ timer: CookingTimer) {
        timer.status = .completed
        timerStates[timer.id] = .completed
        
        // Play completion sound/haptic
        playCompletionFeedback()
        
        // Check if any timers should start when this one completes
        checkDependentTimers(for: timer)
    }
    
    private func checkDependentTimers(for completedTimer: CookingTimer) {
        for timer in meal.timers {
            if timer.status == .waiting {
                switch timer.triggerType {
                case .afterTimer:
                    if timer.triggerTimer?.id == completedTimer.id {
                        // Schedule to start after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(timer.triggerDelay)) {
                            if timer.status == .waiting {
                                self.startTimer(timer)
                            }
                        }
                    }
                case .whenTimerCompletes:
                    if timer.triggerTimer?.id == completedTimer.id && completedTimer.status == .completed {
                        startTimer(timer)
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func playCompletionFeedback() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // TODO: Add sound notification
    }
}
