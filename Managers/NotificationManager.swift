//
//  NotificationManager.swift
//  MyApp
//
//  Created by eleni on 23/11/26.
//


import Foundation
import UserNotifications

class NotificationManager {
    // shared so we can call it from anywhere
    static let shared = NotificationManager()

    // asks the user if we can send notifications
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

    // sends a notification right away
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // tiny delay, it didnt like 0 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        // random id so notifications dont replace each other
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
}
