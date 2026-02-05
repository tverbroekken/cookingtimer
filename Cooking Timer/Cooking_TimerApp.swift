//
//  Cooking_TimerApp.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 04/02/2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct Cooking_TimerApp: App {
    
    init() {
        // Request notification permissions on launch
        requestNotificationPermissions()
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Meal.self,
            CookingTimer.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If there's a schema mismatch, print error for debugging
            print("ModelContainer creation failed: \(error)")
            
            // Try to create a fresh container by deleting old data
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            
            // Create a new container
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}
