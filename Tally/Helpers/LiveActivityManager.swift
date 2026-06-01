//
//  LiveActivityManager.swift
//  Tally
//

#if !canImport(AppKit)
import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<TallyTimerAttributes>?

    private init() {}

    func start(client: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = TallyTimerAttributes.ContentState(
            isPaused: false,
            effectiveStartDate: .now,
            pausedElapsedText: ""
        )
        activity = try? Activity.request(
            attributes: TallyTimerAttributes(client: client),
            content: .init(state: state, staleDate: nil),
            pushType: nil
        )
    }

    func pause(accumulatedSeconds: Double) {
        guard let activity else { return }
        let state = TallyTimerAttributes.ContentState(
            isPaused: true,
            effectiveStartDate: .now,
            pausedElapsedText: formatSeconds(accumulatedSeconds)
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func resume(accumulatedSeconds: Double) {
        guard let activity else { return }
        // Shift effectiveStartDate back so Text(.timer) shows the correct cumulative elapsed
        let state = TallyTimerAttributes.ContentState(
            isPaused: false,
            effectiveStartDate: .now.addingTimeInterval(-accumulatedSeconds),
            pausedElapsedText: ""
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }

    private func formatSeconds(_ s: Double) -> String {
        let t = Int(s)
        let h = t / 3600; let m = (t % 3600) / 60; let sec = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }
}
#endif
