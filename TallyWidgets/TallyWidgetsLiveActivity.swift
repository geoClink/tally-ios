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
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(context.state.isPaused ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                        .frame(width: 46, height: 46)
                    Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(context.state.isPaused ? .orange : .blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.client)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(context.state.isPaused ? "Paused" : "Tracking time")
                        .font(.caption)
                        .foregroundStyle(context.state.isPaused ? .orange : .secondary)
                }

                Spacer()

                if context.state.isPaused {
                    Text(context.state.pausedElapsedText)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                } else {
                    Text(context.state.effectiveStartDate, style: .timer)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.client, systemImage: "timer")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.caption)
                        .foregroundStyle(context.state.isPaused ? .orange : .blue)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isPaused {
                        Text(context.state.pausedElapsedText)
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.orange)
                    } else {
                        Text(context.state.effectiveStartDate, style: .timer)
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.blue)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(context.state.isPaused ? .orange : .blue)
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
