//
//  Models.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 04/02/2026.
//

import Foundation
import SwiftData

// MARK: - Timer Trigger Type
enum TriggerType: String, Codable {
    case manual              // Start manually
    case withMeal           // Start when meal starts
    case afterTimer         // Start X seconds after another timer begins
    case whenTimerCompletes // Start when another timer finishes
}

// MARK: - Timer Status
enum TimerStatus: String, Codable {
    case waiting    // Not started yet
    case running    // Currently running
    case paused     // Paused
    case completed  // Finished
}

// MARK: - Timer Model
@Model
final class CookingTimer {
    var id: UUID
    var name: String
    var durationSeconds: Int
    var statusRawValue: String
    var triggerTypeRawValue: String
    var triggerDelay: Int  // Offset in seconds for dependent timers
    var startTime: Date?
    var pausedTimeRemaining: Int?
    var triggerTimerID: UUID?  // ID of the timer we depend on (instead of direct relationship)
    
    // Relationship
    var meal: Meal?
    
    init(
        name: String,
        durationSeconds: Int,
        triggerType: TriggerType = .manual,
        triggerDelay: Int = 0,
        triggerTimerID: UUID? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.durationSeconds = durationSeconds
        self.statusRawValue = TimerStatus.waiting.rawValue
        self.triggerTypeRawValue = triggerType.rawValue
        self.triggerDelay = triggerDelay
        self.triggerTimerID = triggerTimerID
    }
    
    // Helper computed properties for enum access
    var status: TimerStatus {
        get { TimerStatus(rawValue: statusRawValue) ?? .waiting }
        set { statusRawValue = newValue.rawValue }
    }
    
    var triggerType: TriggerType {
        get { TriggerType(rawValue: triggerTypeRawValue) ?? .manual }
        set { triggerTypeRawValue = newValue.rawValue }
    }
    
    // Helper method to get the trigger timer from the meal
    func getTriggerTimer(from meal: Meal) -> CookingTimer? {
        guard let triggerID = triggerTimerID else { return nil }
        return meal.timers.first { $0.id == triggerID }
    }
    
    // Computed property for remaining time
    var remainingSeconds: Int {
        guard let startTime = startTime else {
            return durationSeconds
        }
        
        if let pausedRemaining = pausedTimeRemaining {
            return pausedRemaining
        }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        return max(0, durationSeconds - elapsed)
    }
    
    // Computed property for progress (0.0 to 1.0)
    var progress: Double {
        guard durationSeconds > 0 else { return 1.0 }
        let remaining = Double(remainingSeconds)
        return 1.0 - (remaining / Double(durationSeconds))
    }
}

// MARK: - Meal Model
@Model
final class Meal {
    var id: UUID
    var name: String
    var createdAt: Date
    var timers: [CookingTimer]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.timers = []
    }
    
    // Computed property for total estimated cooking time
    var estimatedTotalTime: Int {
        // Calculate the longest chain of dependent timers
        return timers.map { calculateTimerEndTime($0) }.max() ?? 0
    }
    
    private func calculateTimerEndTime(_ timer: CookingTimer) -> Int {
        switch timer.triggerType {
        case .manual:
            return timer.durationSeconds
        case .withMeal:
            return timer.durationSeconds
        case .afterTimer:
            guard timer.triggerTimerID != nil else { return timer.durationSeconds }
            return timer.triggerDelay + timer.durationSeconds
        case .whenTimerCompletes:
            guard let trigger = timer.getTriggerTimer(from: self) else { return timer.durationSeconds }
            return calculateTimerEndTime(trigger) + timer.durationSeconds
        }
    }
}
