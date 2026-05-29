//
//  NotificationsManager.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    func scheduleGoalWarning(current: Double, goal: Double) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        let percentage = current / goal
        
        if percentage >= 1.0 {
            sendNotification(
                title: "Weekly limit reached",
                body: "You've hit your \(TimeFormatter.shortFormat(goal)) weekly goal.",
                identifier: "goal-reached"
            )
        } else if percentage >= 0.8 {
            let remaining = goal - current
            sendNotification(
                title: "Approaching weekly limit",
                body: "Only \(TimeFormatter.shortFormat(remaining)) left before your weekly goal.",
                identifier: "goal-warning"
            )
        }
    }
    
    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
