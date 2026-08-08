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

    static let dailyReminderKey = "dailyReminderEnabled"
    static let weeklySummaryKey = "weeklySummaryEnabled"

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Goal warning (existing)

    func scheduleGoalWarning(current: Double, goal: Double) {
        let percentage = current / goal
        if percentage >= 1.0 {
            sendImmediate(
                title: "Weekly goal reached",
                body: "You've hit your \(TimeFormatter.shortFormat(goal)) weekly goal.",
                identifier: "goal-reached"
            )
        } else if percentage >= 0.8 {
            let remaining = goal - current
            sendImmediate(
                title: "Approaching weekly goal",
                body: "Only \(TimeFormatter.shortFormat(remaining)) left before your weekly goal.",
                identifier: "goal-warning"
            )
        }
    }

    // MARK: - Daily reminder

    func scheduleDailyReminder(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Have you tracked today?"
        content.body = "Tap to log your hours before the day is over."
        content.sound = .default

        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Weekly summary

    func scheduleWeeklySummary(weeklyHours: Double, enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your week in Tally"
        content.body = weeklyHours > 0
            ? "You tracked \(TimeFormatter.shortFormat(weeklyHours)) this week. Keep it up!"
            : "No hours logged this week yet — don't fall behind."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 6 // Friday
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "weekly-summary", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Private

    private func sendImmediate(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
