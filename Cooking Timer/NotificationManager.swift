//
//  NotificationManager.swift
//  Cooking Timer
//
//  Created by Tom Verbroekken on 05/02/2026.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Don't show notification banner when app is in foreground (we show full-screen view instead)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Only add to notification list, don't show banner or play sound
        // The full-screen TimerCompletionView handles that
        completionHandler([.list])
    }
    
    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "STOP_TIMER":
            // User tapped "Stop" - notification is dismissed
            print("Timer stopped via notification")
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself - open app
            print("Notification tapped - opening app")
        default:
            break
        }
        
        completionHandler()
    }
}
