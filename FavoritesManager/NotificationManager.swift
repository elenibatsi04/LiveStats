//
//  NotificationManager.swift
//  LiveStats
//
//  Created by eleni on 2/1/26.
//


import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    // 1. Ask user for permission (Alerts, Sounds, Badges)
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else if granted {
                print("Notifications allowed!")
            } else {
                print("Notifications denied.")
            }
        }
    }
    
    // 2. Actually send the alert
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Trigger immediately (0.1s delay to be safe)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Add to queue
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
}
