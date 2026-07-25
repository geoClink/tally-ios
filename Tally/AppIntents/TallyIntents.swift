//
//  TallyIntents.swift
//  Tally
//

import AppIntents
import Foundation

// MARK: - Dynamic client list (reads from App Group so Siri knows your clients)

struct ClientOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        UserDefaults(suiteName: AppGroupKey.suiteName)?
            .stringArray(forKey: AppGroupKey.recentClients) ?? []
    }
}

// MARK: - Start Timer (runs in background -- no app open required)

struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Tally Timer"
    static var description = IntentDescription("Start tracking time for a client.")

    @Parameter(title: "Client", description: "The client to track time for.",
               optionsProvider: ClientOptionsProvider())
    var client: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Write timer state to App Group -- app picks this up on foreground,
        // and TimerViewModel.init() picks it up on cold launch.
        await MainActor.run {
            AppGroupStore.writeTimerState(
                client: client,
                startDate: .now,
                isPaused: false,
                accumulated: 0
            )
        }
        if #available(iOS 17, *) {
            _ = try? await IntentDonationManager.shared.donate(intent: self)
        }
        return .result(dialog: "Timer started for \(client).")
    }
}

// MARK: - Stop Timer

struct StopTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Tally Timer"
    static var description = IntentDescription("Stop and save the current Tally timer.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            UserDefaults(suiteName: AppGroupKey.suiteName)?
                .set(true, forKey: AppGroupKey.pendingStop)
        }
        return .result(dialog: "Stopping your Tally timer.")
    }
}

// MARK: - Log Hours (fully offline, queued for Supabase sync on next app open)

struct LogHoursIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Hours in Tally"
    static var description = IntentDescription("Log hours for a client. Syncs to Tally next time you open the app.")

    @Parameter(title: "Hours", description: "Hours to log (e.g. 1.5 for 1h 30m).",
               controlStyle: .field, inclusiveRange: (0.25, 24.0))
    var hours: Double

    @Parameter(title: "Client", optionsProvider: ClientOptionsProvider())
    var client: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dateStr = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        await MainActor.run {
            AppGroupStore.appendPendingSession(PendingSession(client: client, hours: hours, date: dateStr))
        }
        if #available(iOS 17, *) {
            _ = try? await IntentDonationManager.shared.donate(intent: self)
        }
        return .result(dialog: "Logged \(formatHours(hours)) for \(client). It'll sync when you open Tally.")
    }

    private func formatHours(_ h: Double) -> String {
        let total = Int(h * 60)
        let hrs = total / 60; let mins = total % 60
        if mins == 0 { return hrs == 1 ? "1 hour" : "\(hrs) hours" }
        return "\(hrs)h \(mins)m"
    }
}

// MARK: - Siri Shortcuts (appears in Shortcuts app and Siri suggestions automatically)

struct TallyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start \(.applicationName) timer",
                "Track time in \(.applicationName)",
                "Begin \(.applicationName) session"
            ],
            shortTitle: "Start Timer",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: [
                "Stop \(.applicationName) timer",
                "Stop tracking in \(.applicationName)"
            ],
            shortTitle: "Stop Timer",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: LogHoursIntent(),
            phrases: [
                "Log hours in \(.applicationName)",
                "Add time to \(.applicationName)"
            ],
            shortTitle: "Log Hours",
            systemImageName: "plus.circle"
        )
    }
}
