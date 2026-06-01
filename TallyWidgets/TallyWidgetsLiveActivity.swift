//
//  TallyWidgetsLiveActivity.swift
//  TallyWidgets
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TallyWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TallyTimerAttributes.self) { context in

            // Lock screen / banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.client)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.caption)
                        .foregroundStyle(context.state.isPaused ? .orange : .green)
                }
                Spacer()
                if context.state.isPaused {
                    Text(context.state.pausedElapsedText)
                        .font(.system(size: 28, weight: .thin, design: .monospaced))
                } else {
                    Text(context.state.effectiveStartDate, style: .timer)
                        .font(.system(size: 28, weight: .thin, design: .monospaced))
                        .monospacedDigit()
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.client, systemImage: "timer")
                        .font(.caption.bold())
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.caption2)
                        .foregroundStyle(context.state.isPaused ? .orange : .green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isPaused {
                        Text(context.state.pausedElapsedText)
                            .font(.system(size: 36, weight: .thin, design: .monospaced))
                    } else {
                        Text(context.state.effectiveStartDate, style: .timer)
                            .font(.system(size: 36, weight: .thin, design: .monospaced))
                            .monospacedDigit()
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(context.state.isPaused ? .orange : .green)
            } compactTrailing: {
                if context.state.isPaused {
                    Text(context.state.pausedElapsedText)
                        .font(.caption2.monospacedDigit())
                } else {
                    Text(context.state.effectiveStartDate, style: .timer)
                        .font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .foregroundStyle(context.state.isPaused ? .orange : .green)
            }
            .widgetURL(URL(string: "tally://home"))
            .keylineTint(.blue)
        }
    }
}

#Preview("Lock Screen", as: .content, using: TallyTimerAttributes(client: "tripsetta-android")) {
    TallyWidgetsLiveActivity()
} contentStates: {
    TallyTimerAttributes.ContentState(isPaused: false, effectiveStartDate: .now, pausedElapsedText: "")
    TallyTimerAttributes.ContentState(isPaused: true, effectiveStartDate: .now, pausedElapsedText: "1:23")
}
