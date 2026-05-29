//
//  TimerViewModel.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import Foundation
import Combine

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
    
    func start(client: String) {
        guard !isRunning else { return }
        activeClient = client
        isRunning = true
        isPaused = false
        startTime = .now
        accumulatedSeconds = 0
        startTicking()
    }
    
    func pause() {
        guard isRunning && !isPaused else { return }
        isPaused = true
        accumulatedSeconds += secondsSinceStart()
        timer?.cancel()
    }
    
    func resume() {
        guard isPaused else { return }
        isPaused = false
        startTime = .now
        startTicking()
    }
    
    func stop() -> Double {
        let total = accumulatedSeconds + (isPaused ? 0 : secondsSinceStart())
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
