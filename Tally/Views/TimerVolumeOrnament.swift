//
//  TimerVolumeOrnament.swift
//  Tally
//

#if os(visionOS)
import SwiftUI

struct TimerVolumeOrnament: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(TimerViewModel.self) private var timerViewModel

    var body: some View {
        Button {
            openWindow(id: "timer-volume")
        } label: {
            HStack(spacing: 8) {
                Image(systemName: timerViewModel.isRunning ? "timer" : "timer.circle")
                    .symbolEffect(.pulse, isActive: timerViewModel.isRunning)
                Text(timerViewModel.isRunning ? "View Timer in Space" : "Open Timer Volume")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .glassBackgroundEffect()
    }
}
#endif
