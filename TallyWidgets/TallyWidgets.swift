//
//  TallyWidgets.swift
//  TallyWidgets
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct TallyWidgetEntry: TimelineEntry {
    var date: Date
    var todayHours: Double
    var weeklyHours: Double
    var weeklyGoal: Double
    var topClient: String

    static var placeholder: TallyWidgetEntry {
        TallyWidgetEntry(date: .now, todayHours: 3.5, weeklyHours: 14.0, weeklyGoal: 40.0, topClient: "tripsetta")
    }

    static var fromAppGroup: TallyWidgetEntry {
        let d = UserDefaults(suiteName: AppGroupKey.suiteName) ?? .standard
        return TallyWidgetEntry(
            date: .now,
            todayHours: d.double(forKey: AppGroupKey.todayHours),
            weeklyHours: d.double(forKey: AppGroupKey.weeklyHours),
            weeklyGoal: max(d.double(forKey: AppGroupKey.weeklyGoal), 1),
            topClient: d.string(forKey: AppGroupKey.topClientToday) ?? "--"
        )
    }
}

// MARK: - Timeline Provider

struct TallyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallyWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (TallyWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : .fromAppGroup)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TallyWidgetEntry>) -> Void) {
        let entry = TallyWidgetEntry.fromAppGroup
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Helpers

private func formatHours(_ hours: Double) -> String {
    let total = Int(hours * 60)
    let h = total / 60
    let m = total % 60
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}

// MARK: - Small Widget View

struct TallySmallWidgetView: View {
    let entry: TallyWidgetEntry

    private var progress: Double { min(entry.weeklyHours / entry.weeklyGoal, 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatHours(entry.todayHours))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("today")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            ProgressView(value: progress)
                .tint(.blue)
            Text("\(Int(progress * 100))% of weekly goal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Medium Widget View

struct TallyMediumWidgetView: View {
    let entry: TallyWidgetEntry

    private var progress: Double { min(entry.weeklyHours / entry.weeklyGoal, 1.0) }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatHours(entry.todayHours))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Spacer()
                if entry.topClient != "--" {
                    Label(entry.topClient, systemImage: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("This Week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatHours(entry.weeklyHours))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Spacer()
                ProgressView(value: progress)
                    .tint(.blue)
                Text("of \(formatHours(entry.weeklyGoal)) goal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Entry View Router

struct TallyWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TallyWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium: TallyMediumWidgetView(entry: entry)
        default:            TallySmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct TallyWidgets: Widget {
    let kind = "TallyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TallyWidgetProvider()) { entry in
            TallyWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tally")
        .description("See your hours at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TallyWidgets()
} timeline: {
    TallyWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    TallyWidgets()
} timeline: {
    TallyWidgetEntry.placeholder
}
