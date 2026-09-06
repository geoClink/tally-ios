//
//  TallyTimerAttributes.swift
//  Tally + TallyWidgets (add this file to both targets in File Inspector)
//

import Foundation

#if !canImport(AppKit) && !os(visionOS)
import ActivityKit

struct TallyTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isPaused: Bool
        var effectiveStartDate: Date
        var pausedElapsedText: String
    }
    let client: String
}
#endif

enum AppGroupKey {
    static let suiteName             = "group.name.GeorgeClinkscales.Tally"
    // Widget
    static let todayHours            = "tallyTodayHours"
    static let weeklyHours           = "tallyWeeklyHours"
    static let weeklyGoal            = "tallyWeeklyGoal"
    static let topClientToday        = "tallyTopClientToday"
    static let recentClients         = "tallyRecentClients"
    static let weeklyEarnings        = "tallyWeeklyEarnings"
    // Background timer state (written by Siri intent + app)
    static let timerIsRunning        = "tallyTimerIsRunning"
    static let timerClient           = "tallyTimerClient"
    static let timerStartDate        = "tallyTimerStartDate"
    static let timerIsPaused         = "tallyTimerIsPaused"
    static let timerAccumulated      = "tallyTimerAccumulated"
    // Legacy pending intent flags
    static let pendingStartClient    = "tallyPendingStartClient"
    static let pendingStop           = "tallyPendingStop"
    // Offline session queue
    static let pendingSessionsQueue  = "tallyPendingSessionsQueue"
}
