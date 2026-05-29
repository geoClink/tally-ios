//
//  ReportsView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Charts
import Supabase

struct ReportsView: View {
    @Environment(TallyStore.self) var tallyStore
    @State private var isLoading = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showAllClients = false
    @State private var showExportClientPicker = false
    
    private var topClientsForChart: [(String, Double)] {
        Array(allTimeByClient.prefix(20))
    }
    
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
            Group {
                if isLoading {
                    ProgressView("Loading sessions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("This Week") {
                            ProgressBarView(value: tallyStore.weeklyHours, goal: tallyStore.weeklyGoal)
                                .padding(.vertical, 4)
                            
                            if weeklyByClient.isEmpty {
                                Text("No sessions this week")
                                    .foregroundStyle(.secondary)
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
                            if !topClientsForChart.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    Chart(topClientsForChart, id: \.0) { client, hours in
                                        BarMark(
                                            x: .value("Client", client),
                                            y: .value("Hours", hours)
                                        )
                                        .foregroundStyle(.blue)
                                        .annotation(position: .top) {
                                            Text(TimeFormatter.shortFormat(hours))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { value in
                                            AxisValueLabel {
                                                if let hours = value.as(Double.self) {
                                                    Text(TimeFormatter.shortFormat(hours))
                                                        .font(.caption2)
                                                }
                                            }
                                        }
                                    }
#if os(iOS)
.frame(width: max(CGFloat(topClientsForChart.count) * 120, UIScreen.main.bounds.width - 32), height: 200)
#else
.frame(width: max(CGFloat(topClientsForChart.count) * 120, 600), height: 200)
#endif
                                    .padding(.vertical, 8)
                                }
                                .accessibilityLabel("Scrollable bar chart showing hours by client")
                            }
                            
                            if allTimeByClient.isEmpty {
                                Text("No sessions logged yet")
                                    .foregroundStyle(.secondary)
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
                                
                                if allTimeByClient.count > 20 {
                                    Button {
                                        showAllClients = true
                                    } label: {
                                        Text("See all \(allTimeByClient.count) clients →")
                                            .font(.subheadline)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        
                        Section("Recent Sessions") {
                            ForEach(tallyStore.sessions.prefix(20)) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.client)
                                            .font(.subheadline)
                                        if let note = session.taskNote, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(TimeFormatter.shortFormat(session.hours))
                                            .font(.subheadline)
                                        Text(session.date ?? "")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                            }
                            .onDelete { indexSet in
                                Task {
                                    await tallyStore.deleteSessions(at: indexSet)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export hours")
                }
            }
            .confirmationDialog("Export Hours", isPresented: $showExportSheet) {
                Button("This Week") { export(range: .thisWeek, client: nil) }
                Button("This Month") { export(range: .thisMonth, client: nil) }
                Button("All Time") { export(range: .allTime, client: nil) }
                Button("By Client...") { showExportClientPicker = true }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Choose Client", isPresented: $showExportClientPicker) {
                ForEach(tallyStore.recentClients, id: \.self) { client in
                    Button(client) { export(range: .allTime, client: client) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
            .sheet(isPresented: $showAllClients) {
                AllClientsView(clients: allTimeByClient)
            }
            .task {
                isLoading = true
                await tallyStore.loadSessions()
                isLoading = false
            }
        }
    }
    
    private func export(range: ExportRange, client: String?) {
        let clientName = client?.replacingOccurrences(of: " ", with: "-") ?? "all"
        let filename = "tally-\(clientName)-\(range.rawValue.lowercased().replacingOccurrences(of: " ", with: "-")).csv"
        let csv = CSVExporter.generate(sessions: tallyStore.sessions, range: range, client: client)
        exportURL = CSVExporter.save(csv: csv, filename: filename)
        showShareSheet = true
    }
}
