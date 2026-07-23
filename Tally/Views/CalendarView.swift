//
//  CalendarView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct CalendarView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date? = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var weekdays: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthInterval.end)
        var dates: [Date?] = []
        var current = dateInterval.start

        while current < dateInterval.end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        while dates.count % 7 != 0 {
            dates.append(nil)
        }

        return dates
    }

    private var hoursByDate: [String: Double] {
        var dict: [String: Double] = [:]
        for session in tallyStore.sessions {
            let key = session.date ?? ""
            dict[key, default: 0] += session.hours
        }
        return dict
    }

    private func hours(for date: Date) -> Double {
        let key = dateKey(date)
        return hoursByDate[key] ?? 0
    }

    private func sessions(for date: Date) -> [SessionModel] {
        let key = dateKey(date)
        return tallyStore.sessions.filter { $0.date == key }
    }

    private func dateKey(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date).prefix(10).description
    }

    private func intensity(for hours: Double) -> Double {
        if hours <= 0 { return 0 }
        if hours < 1 { return 0.2 }
        if hours < 2 { return 0.4 }
        if hours < 4 { return 0.6 }
        if hours < 6 { return 0.8 }
        return 1.0
    }

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: 0) {
                        calendarPanel
                            .frame(width: 380)
                        Divider()
                        dayDetailPanel
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    ScrollView {
                        calendarPanel
                    }
                }
            }
            .navigationTitle("Activity")
            .task {
                if tallyStore.sessions.isEmpty {
                    await tallyStore.loadSessions()
                }
            }
        }
    }

    private var calendarPanel: some View {
        VStack(spacing: 16) {
            // Month navigator
            HStack {
                Button {
                    if let prev = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
                        selectedMonth = prev
                    }
                } label: {
                    Image(systemName: "chevron.left").font(.title3)
                }
                .accessibilityLabel("Previous month")

                Spacer()

                Text(monthTitle).font(.headline)

                Spacer()

                Button {
                    if let next = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
                        selectedMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right").font(.title3)
                }
                .accessibilityLabel("Next month")
            }
            .padding(.horizontal)

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        let h = hours(for: date)
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                        let isCurrentMonth = calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)

                        VStack(spacing: 2) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.caption)
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundStyle(isSelected ? .white : (isCurrentMonth ? .primary : .secondary))

                            Circle()
                                .fill(h > 0
                                      ? (isSelected ? Color.white.opacity(0.8) : Color.blue.opacity(intensity(for: h)))
                                      : Color.clear)
                                .frame(width: 6, height: 6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { selectedDate = date }
                        .accessibilityLabel(h > 0 ? "\(calendar.component(.day, from: date)), \(TimeFormatter.shortFormat(h)) logged" : "\(calendar.component(.day, from: date))")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
            .padding(.horizontal)

            // Legend
            HStack(spacing: 16) {
                Text("Less").font(.caption2).foregroundStyle(.secondary)
                ForEach([0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { intensity in
                    Circle()
                        .fill(Color.blue.opacity(intensity))
                        .frame(width: 10, height: 10)
                }
                Text("More").font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.top)
    }

    private var dayDetailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let date = selectedDate {
                let daySessions: [SessionModel] = sessions(for: date)
                let totalHours = daySessions.reduce(0) { $0 + $1.hours }

                VStack(alignment: .leading, spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.headline)
                    if totalHours > 0 {
                        Text(TimeFormatter.shortFormat(totalHours) + " total")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Divider()

                if daySessions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("No sessions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(daySessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.client)
                                    .font(.body)
                                if session.isManual {
                                    Text("Manual entry")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(TimeFormatter.shortFormat(session.hours))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Select a day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
