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

    var body: some View {
        if isRunning {
            RunningView(
                client: selectedClient,
                elapsedSeconds: $elapsedSeconds,
                isRunning: $isRunning,
                isPaused: $isPaused,
                timer: $timer,
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
                elapsedSeconds: $elapsedSeconds
            )
        }
    }
}
