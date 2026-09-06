//
//  TimerViewModel.swift
//  Tally
//

import Foundation
import Combine
import AppIntents
#if os(iOS)
import UserNotifications
#endif

@MainActor
@Observable
class TimerViewModel {
    var activeClient: String = ""
    var isRunning: Bool = false
    var isPaused: Bool = false
    var elapsedSeconds: Double = 0
    var accumulatedSeconds: Double = 0

    private var timer: AnyCancellable?
    private var startTime: Date?

    init() {
        // Resume a timer that was started via Siri while the app was closed
        if let state = AppGroupStore.readTimerState() {
            activeClient = state.client
            isRunning = true
            isPaused = state.isPaused
            accumulatedSeconds = state.accumulated
            if state.isPaused {
                elapsedSeconds = state.accumulated
            } else {
                startTime = state.startDate
                elapsedSeconds = state.accumulated + Date.now.timeIntervalSince(state.startDate)
                startTicking()
            }
        }
    }

    func start(client: String) {
        guard !isRunning else { return }
        activeClient = client
        isRunning = true
        isPaused = false
        startTime = .now
        accumulatedSeconds = 0
        startTicking()
        AppGroupStore.writeTimerState(client: client, startDate: .now, isPaused: false, accumulated: 0)
        #if os(iOS)
        scheduleIdleNotification(client: client)
        #endif
        #if !canImport(AppKit) && !os(visionOS)
        LiveActivityManager.shared.start(client: client)
        #endif
        if #available(iOS 17, *) {
            Task {
                let intent = StartTimerIntent()
                intent.client = client
                _ = try? await IntentDonationManager.shared.donate(intent: intent)
            }
        }
    }

    func pause() {
        guard isRunning && !isPaused else { return }
        isPaused = true
        accumulatedSeconds += secondsSinceStart()
        timer?.cancel()
        AppGroupStore.writeTimerState(
            client: activeClient,
            startDate: startTime ?? .now,
            isPaused: true,
            accumulated: accumulatedSeconds
        )
        #if !canImport(AppKit) && !os(visionOS)
        LiveActivityManager.shared.pause(accumulatedSeconds: accumulatedSeconds)
        #endif
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        startTime = .now
        startTicking()
        AppGroupStore.writeTimerState(
            client: activeClient,
            startDate: .now,
            isPaused: false,
            accumulated: accumulatedSeconds
        )
        #if !canImport(AppKit) && !os(visionOS)
        LiveActivityManager.shared.resume(accumulatedSeconds: accumulatedSeconds)
        #endif
    }

    func stop() -> Double {
        let total = accumulatedSeconds + (isPaused ? 0 : secondsSinceStart())
        AppGroupStore.clearTimerState()
        #if os(iOS)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["tally.idle"])
        #endif
        #if !canImport(AppKit) && !os(visionOS)
        LiveActivityManager.shared.end()
        #endif
        reset()
        return total / 3600
    }

    func reset() {
        timer?.cancel()
        isRunning = false
        isPaused = false
        elapsedSeconds = 0
        accumulatedSeconds = 0
        startTime = nil
        activeClient = ""
    }

    #if os(iOS)
    private func scheduleIdleNotification(client: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["tally.idle"])
        let content = UNMutableNotificationContent()
        content.title = "Still working?"
        content.body = "Your Tally timer for \(client) has been running for 2 hours."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
        let request = UNNotificationRequest(identifier: "tally.idle", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    #endif

    private func startTicking() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsedSeconds = self.accumulatedSeconds + self.secondsSinceStart()
            }
    }

    private func secondsSinceStart() -> Double {
        guard let start = startTime else { return 0 }
        return Date.now.timeIntervalSince(start)
    }
}
