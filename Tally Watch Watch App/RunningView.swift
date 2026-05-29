//
//  Untitled.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct RunningView: View {
    let client: String
    @Binding var elapsedSeconds: Double
    @Binding var isRunning: Bool
    @Binding var isPaused: Bool
    @Binding var timer: Timer?
    
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
                // Pause / Resume
                Button {
                    if isPaused {
                        isPaused = false
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            elapsedSeconds += 1
                        }
                    } else {
                        isPaused = true
                        timer?.invalidate()
                        timer = nil
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
                
                // Stop
                Button {
                    timer?.invalidate()
                    timer = nil
                    isRunning = false
                    isPaused = false
                    elapsedSeconds = 0
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.red))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop timer")
            }
        }
        .padding(.horizontal, 4)
    }
}
