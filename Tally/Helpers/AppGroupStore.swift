//
//  AppGroupStore.swift
//  Tally
//

import Foundation

struct PendingSession: Codable {
    let client: String
    let hours: Double
    let date: String
}

enum AppGroupStore {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppGroupKey.suiteName) ?? .standard
    }

    // MARK: - Widget summary

    static func writeSummary(
        todayHours: Double,
        weeklyHours: Double,
        weeklyGoal: Double,
        topClient: String,
        recentClients: [String],
        weeklyEarnings: Double = 0,
        isPro: Bool = false
    ) {
        defaults.set(todayHours,       forKey: AppGroupKey.todayHours)
        defaults.set(weeklyHours,      forKey: AppGroupKey.weeklyHours)
        defaults.set(weeklyGoal,       forKey: AppGroupKey.weeklyGoal)
        defaults.set(topClient,        forKey: AppGroupKey.topClientToday)
        defaults.set(recentClients,    forKey: AppGroupKey.recentClients)
        defaults.set(weeklyEarnings,   forKey: AppGroupKey.weeklyEarnings)
        defaults.set(isPro,            forKey: "isPro")
    }

    static func readIsPro() -> Bool {
        defaults.bool(forKey: "isPro")
    }

    // MARK: - Background timer state

    static func writeTimerState(
        client: String,
        startDate: Date,
        isPaused: Bool,
        accumulated: Double
    ) {
        defaults.set(true,        forKey: AppGroupKey.timerIsRunning)
        defaults.set(client,      forKey: AppGroupKey.timerClient)
        defaults.set(startDate,   forKey: AppGroupKey.timerStartDate)
        defaults.set(isPaused,    forKey: AppGroupKey.timerIsPaused)
        defaults.set(accumulated, forKey: AppGroupKey.timerAccumulated)
    }

    static func clearTimerState() {
        defaults.set(false, forKey: AppGroupKey.timerIsRunning)
        defaults.removeObject(forKey: AppGroupKey.timerClient)
        defaults.removeObject(forKey: AppGroupKey.timerStartDate)
        defaults.set(false, forKey: AppGroupKey.timerIsPaused)
        defaults.set(0.0,   forKey: AppGroupKey.timerAccumulated)
    }

    struct TimerState {
        let client: String
        let startDate: Date
        let isPaused: Bool
        let accumulated: Double
    }

    static func readTimerState() -> TimerState? {
        guard defaults.bool(forKey: AppGroupKey.timerIsRunning),
              let client = defaults.string(forKey: AppGroupKey.timerClient), !client.isEmpty,
              let startDate = defaults.object(forKey: AppGroupKey.timerStartDate) as? Date
        else { return nil }
        return TimerState(
            client: client,
            startDate: startDate,
            isPaused: defaults.bool(forKey: AppGroupKey.timerIsPaused),
            accumulated: defaults.double(forKey: AppGroupKey.timerAccumulated)
        )
    }

    // MARK: - Offline session queue

    static func pendingSessionsQueue() -> [PendingSession] {
        guard let data = defaults.data(forKey: AppGroupKey.pendingSessionsQueue),
              let queue = try? JSONDecoder().decode([PendingSession].self, from: data)
        else { return [] }
        return queue
    }

    static func appendPendingSession(_ session: PendingSession) {
        var queue = pendingSessionsQueue()
        queue.append(session)
        if let data = try? JSONEncoder().encode(queue) {
            defaults.set(data, forKey: AppGroupKey.pendingSessionsQueue)
        }
    }

    static func clearPendingSessionsQueue() {
        defaults.removeObject(forKey: AppGroupKey.pendingSessionsQueue)
    }

    // MARK: - Legacy pending intents

    static func pendingStartClient() -> String? {
        let val = defaults.string(forKey: AppGroupKey.pendingStartClient)
        return (val?.isEmpty == false) ? val : nil
    }

    static func pendingStop() -> Bool {
        defaults.bool(forKey: AppGroupKey.pendingStop)
    }

    static func clearPendingIntents() {
        defaults.removeObject(forKey: AppGroupKey.pendingStartClient)
        defaults.set(false, forKey: AppGroupKey.pendingStop)
    }
}
