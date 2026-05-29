//
//  ReportsView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Charts

struct ReportsView: View {
    @Environment(TallyStore.self) var tallyStore
    
    private var weeklyByClient: [(String, Double)] {
        let calendar = Calendar.current
        let now = Date()
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        var dict: [String: Double] = [:]
        for session in tallyStore.sessions.filter({ $0.startTime >= monday }) {
            dict[session.client, default: 0] += session.hours
        }
        return dict.sorted { $0.value > $1.value }
    }
    
    private var allTimeByClient: [(String, Double)] {
        var dict: [String: Double] = [:]
        for session in tallyStore.sessions {
            dict[session.client, default: 0] += session.hours
        }
        return dict.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("This Week") {
                    ProgressBarView(value: tallyStore.weeklyHours, goal: tallyStore.weeklyGoal)
                        .padding(.vertical, 4)
                    
                    if weeklyByClient.isEmpty {
                        Text("No sessions this week")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("No sessions logged this week")
                    } else {
                        ForEach(weeklyByClient, id: \.0) { client, hours in
                            HStack {
                                Text(client)
                                Spacer()
                                Text(TimeFormatter.shortFormat(hours))
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(client): \(TimeFormatter.accessibleFormat(hours)) this week")
                        }
                    }
                }
                
                Section("All Time") {
                    if !allTimeByClient.isEmpty {
                        Chart(allTimeByClient, id: \.0) { client, hours in
                            BarMark(
                                x: .value("Client", client),
                                y: .value("Hours", hours)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                        .padding(.vertical, 8)
                        .accessibilityLabel("Bar chart showing all time hours by client")
                    }
                    
                    if allTimeByClient.isEmpty {
                        Text("No sessions logged yet")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("No sessions logged yet")
                    } else {
                        ForEach(allTimeByClient, id: \.0) { client, hours in
                            HStack {
                                Text(client)
                                Spacer()
                                Text(TimeFormatter.shortFormat(hours))
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(client): \(TimeFormatter.accessibleFormat(hours)) total")
                        }
                    }
                }
            }
            .navigationTitle("Reports")
            .task {
                await tallyStore.loadSessions()
            }
        }
    }
}
