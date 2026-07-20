//
//  RunningView.swift
//  Tally Watch Watch App
//

import SwiftUI

struct RunningView: View {
    let client: String
    @Binding var elapsedSeconds: Double
    @Binding var isRunning: Bool
    @Binding var isPaused: Bool
    @Binding var timer: Timer?
    @Binding var timerStartDate: Date
    @Binding var accumulatedSeconds: Double
    let onStop: (Double) -> Void

    private var timeDisplay: String {
        let total = Int(elapsedSeconds)
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(client)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(timeDisplay)
                .font(.system(size: 32, weight: .thin, design: .monospaced))
                .accessibilityLabel("Elapsed time \(timeDisplay)")
                .accessibilityAddTraits(.updatesFrequently)

            Text(isPaused ? "Paused" : "Running")
                .font(.caption2)
                .foregroundStyle(isPaused ? .orange : .green)

            HStack(spacing: 16) {
                Button {
                    let defaults = UserDefaults.standard
                    if isPaused {
                        isPaused = false
                        timerStartDate = Date()
                        defaults.set(false, forKey: "timerPaused")
                        defaults.set(timerStartDate.timeIntervalSince1970, forKey: "timerStartDate")
                        defaults.set(accumulatedSeconds, forKey: "timerAccumulated")
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            elapsedSeconds = accumulatedSeconds + Date().timeIntervalSince(timerStartDate)
                        }
                    } else {
                        isPaused = true
                        accumulatedSeconds = elapsedSeconds
                        timer?.invalidate()
                        timer = nil
                        defaults.set(true, forKey: "timerPaused")
                        defaults.set(accumulatedSeconds, forKey: "timerAccumulated")
                    }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.orange))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPaused ? "Resume timer" : "Pause timer")

                Button {
                    let hours = elapsedSeconds / 3600
                    timer?.invalidate()
                    timer = nil
                    isRunning = false
                    isPaused = false
                    elapsedSeconds = 0
                    UserDefaults.standard.set(false, forKey: "timerRunning")
                    onStop(hours)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop timer and save session")
            }
        }
        .padding(.horizontal, 4)
    }
}
