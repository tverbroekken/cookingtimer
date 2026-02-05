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
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.glassProminent)
        .tint(.orange)
        .controlSize(.large)
        .padding(.horizontal, 32)
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
                // Outer glow
                Circle()
                    .fill(glowColor.gradient.opacity(glowIntensity * 0.5))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                
                // Burner plate with coils
                ZStack {
                    // Base plate
                    Circle()
                        .fill(Color(white: 0.15))
                        .frame(width: 160, height: 160)
                    
                    // Inner heating element
                    Circle()
                        .fill(burnerColor.gradient)
                        .frame(width: 140, height: 140)
                        .overlay {
                            // Coil rings for stove effect
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(
                                        Color.black.opacity(0.3),
                                        lineWidth: 2
                                    )
                                    .frame(width: CGFloat(120 - (index * 25)))
                            }
                        }
                    
                    // Ring border
                    Circle()
                        .stroke(ringColor.gradient, lineWidth: 6)
                        .frame(width: 160, height: 160)
                }
                .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                
                // Timer info overlay
                VStack(spacing: 6) {
                    Text(timer.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    
                    Text(formattedTime)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                    
                    if status != .waiting {
                        HStack(spacing: 4) {
                            Image(systemName: statusIcon)
                                .font(.caption2)
                            Text(statusText)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(.black.opacity(0.4))
                        }
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
            return Color(white: 0.25)
        case .running:
            return .orange
        case .paused:
            return .yellow
        case .completed:
            return .green
        }
    }
    
    private var ringColor: Color {
        switch status {
        case .waiting:
            return Color(white: 0.4)
        case .running:
            return .red
        case .paused:
            return .orange
        case .completed:
            return .mint
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
            return "Tap to Start"
        case .running:
            return "Cooking"
        case .paused:
            return "Paused"
        case .completed:
            return "Done!"
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .waiting:
            return "hand.tap.fill"
        case .running:
            return "flame.fill"
        case .paused:
            return "pause.fill"
        case .completed:
            return "checkmark.circle.fill"
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
        // Reset all timers to waiting state when entering cooking view
        for timer in meal.timers {
            timer.status = .waiting
            timer.startTime = nil
            timer.pausedTimeRemaining = nil
            timerStates[timer.id] = .waiting
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
        
        // Check if any other timers should start based on this one starting
        checkDependentTimersOnStart(for: timer)
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
        checkDependentTimersOnCompletion(for: timer)
    }
    
    private func checkDependentTimersOnStart(for startedTimer: CookingTimer) {
        for timer in meal.timers {
            if timer.status == .waiting && timer.triggerType == .afterTimer {
                if timer.triggerTimerID == startedTimer.id {
                    // Schedule to start after delay from when this timer started
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(timer.triggerDelay)) {
                        if timer.status == .waiting {
                            self.startTimer(timer)
                        }
                    }
                }
            }
        }
    }
    
    private func checkDependentTimersOnCompletion(for completedTimer: CookingTimer) {
        for timer in meal.timers {
            if timer.status == .waiting && timer.triggerType == .whenTimerCompletes {
                if timer.triggerTimerID == completedTimer.id {
                    startTimer(timer)
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
