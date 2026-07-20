//
//  ContentView.swift
//  Tally Watch Watch App
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var selectedClient = ""
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var elapsedSeconds: Double = 0
    @State private var timer: Timer?
    @State private var timerStartDate: Date = Date()
    @State private var accumulatedSeconds: Double = 0

    var body: some View {
        Group {
            if isRunning {
                RunningView(
                    client: selectedClient,
                    elapsedSeconds: $elapsedSeconds,
                    isRunning: $isRunning,
                    isPaused: $isPaused,
                    timer: $timer,
                    timerStartDate: $timerStartDate,
                    accumulatedSeconds: $accumulatedSeconds,
                    onStop: { hours in
                        sessionManager.sendSession(client: selectedClient, hours: hours)
                    }
                )
            } else if sessionManager.clients.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Open Tally on your iPhone to sync clients")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                ClientScrollView(
                    clients: sessionManager.clients,
                    selectedClient: $selectedClient,
                    isRunning: $isRunning,
                    timer: $timer,
                    elapsedSeconds: $elapsedSeconds,
                    timerStartDate: $timerStartDate,
                    accumulatedSeconds: $accumulatedSeconds
                )
            }
        }
        .onAppear { restoreTimerIfNeeded() }
    }

    private func restoreTimerIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "timerRunning") else { return }
        selectedClient = defaults.string(forKey: "timerClient") ?? ""
        accumulatedSeconds = defaults.double(forKey: "timerAccumulated")
        isPaused = defaults.bool(forKey: "timerPaused")
        isRunning = true
        guard !isPaused else {
            elapsedSeconds = accumulatedSeconds
            return
        }
        let savedStart = defaults.double(forKey: "timerStartDate")
        timerStartDate = savedStart > 0 ? Date(timeIntervalSince1970: savedStart) : Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds = accumulatedSeconds + Date().timeIntervalSince(timerStartDate)
        }
    }
}
