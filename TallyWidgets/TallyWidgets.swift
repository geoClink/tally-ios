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
    var weeklyEarnings: Double

    static var placeholder: TallyWidgetEntry {
        TallyWidgetEntry(date: .now, todayHours: 3.5, weeklyHours: 14.0, weeklyGoal: 40.0, topClient: "tripsetta", weeklyEarnings: 0)
    }

    static var fromAppGroup: TallyWidgetEntry {
        let d = UserDefaults(suiteName: AppGroupKey.suiteName) ?? .standard
        return TallyWidgetEntry(
            date: .now,
            todayHours: d.double(forKey: AppGroupKey.todayHours),
            weeklyHours: d.double(forKey: AppGroupKey.weeklyHours),
            weeklyGoal: max(d.double(forKey: AppGroupKey.weeklyGoal), 1),
            topClient: d.string(forKey: AppGroupKey.topClientToday) ?? "--",
            weeklyEarnings: d.double(forKey: AppGroupKey.weeklyEarnings)
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
        VStack(spacing: 0) {
            // Circular progress ring with today's hours
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.4), value: progress)

                VStack(spacing: 1) {
                    if entry.todayHours == 0 {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.blue)
                        Text("Start")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(formatHours(entry.todayHours))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("today")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)

            Text("\(Int(progress * 100))% of goal")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "tally://timer"))
    }
}

// MARK: - Medium Widget View

struct TallyMediumWidgetView: View {
    let entry: TallyWidgetEntry

    private var progress: Double { min(entry.weeklyHours / entry.weeklyGoal, 1.0) }

    var body: some View {
        HStack(spacing: 16) {
            // Left: circular ring + today
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    if entry.todayHours == 0 {
                        Image(systemName: "timer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                        Text("Start")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(formatHours(entry.todayHours))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text("today")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 80, height: 80)

            // Right: weekly stats
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatHours(entry.weeklyHours))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if entry.weeklyEarnings > 0 {
                        Text(entry.weeklyEarnings, format: .currency(code: "USD"))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                ProgressView(value: progress)
                    .tint(.blue)

                HStack {
                    Text("of \(formatHours(entry.weeklyGoal)) goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if entry.topClient != "--" {
                        Label(entry.topClient, systemImage: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .widgetURL(URL(string: "tally://timer"))
    }
}

// MARK: - Lock Screen Circular Widget

struct TallyCircularWidgetView: View {
    let entry: TallyWidgetEntry

    private var progress: Double { min(entry.weeklyHours / entry.weeklyGoal, 1.0) }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                if entry.todayHours == 0 {
                    Image(systemName: "timer")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Track")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                } else {
                    Text(formatHours(entry.todayHours))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("today")
                        .font(.system(size: 8, design: .rounded))
                }
            }
        }
        .widgetURL(URL(string: "tally://timer"))
    }
}

// MARK: - Lock Screen Rectangular Widget

struct TallyRectangularWidgetView: View {
    let entry: TallyWidgetEntry

    private var progress: Double { min(entry.weeklyHours / entry.weeklyGoal, 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "timer")
                    .font(.caption2)
                Text("Tally")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.todayHours == 0 ? "No hours yet" : formatHours(entry.todayHours))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if entry.todayHours > 0 {
                    Text("today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: progress)
                .tint(.white)
            Text("\(Int(progress * 100))% of weekly goal")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "tally://timer"))
    }
}

// MARK: - Entry View Router

struct TallyWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TallyWidgetEntry

    var body: some View {
        switch family {
        case .systemMedium: TallyMediumWidgetView(entry: entry)
        #if os(iOS)
        case .accessoryCircular:    TallyCircularWidgetView(entry: entry)
        case .accessoryRectangular: TallyRectangularWidgetView(entry: entry)
        #endif
        default: TallySmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct TallyWidgets: Widget {
    let kind = "TallyWidget"

    private var families: [WidgetFamily] {
        var result: [WidgetFamily] = [.systemSmall, .systemMedium]
        #if os(iOS)
        result += [.accessoryCircular, .accessoryRectangular]
        #endif
        return result
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TallyWidgetProvider()) { entry in
            TallyWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tally")
        .description("See your hours at a glance.")
        .supportedFamilies(families)
    }
}

// MARK: - Previews

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

#if os(iOS)
#Preview(as: .accessoryCircular) {
    TallyWidgets()
} timeline: {
    TallyWidgetEntry.placeholder
}

#Preview(as: .accessoryRectangular) {
    TallyWidgets()
} timeline: {
    TallyWidgetEntry.placeholder
}
#endif
