//
//  ReportsView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Charts
import Supabase
import TipKit

struct ReportsView: View {
    @Environment(TallyStore.self) var tallyStore
    @State private var isLoading = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showAllClients = false
    @State private var sessionToDelete: SessionModel?
    @State private var showDeleteConfirmation = false
    @State private var showExportOptions = false
    @State private var showPaywall = false
    @State private var logAgainSession: SessionModel?
    @State private var showLogAgain = false
    @State private var sessionToEdit: SessionModel?
    @State private var showEditSession = false
    private let purchases = PurchaseManager.shared
    private let exportTip = ExportLockedTip()
    
    private var topClientsForChart: [(String, Double)] {
        Array(allTimeByClient.prefix(20))
    }

    private var chartAccessibilityDescription: String {
        topClientsForChart
            .map { "\($0.0): \(TimeFormatter.accessibleFormat($0.1))" }
            .joined(separator: "; ")
    }
    
    private var weeklyByClient: [(String, Double)] {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
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
                } else if tallyStore.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text("No sessions yet")
                            .font(.headline)
                        Text("Start a timer on the Home tab, or tap ⋯ to log hours manually.")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
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
                                    let rate = tallyStore.hourlyRate(for: client)
                                    HStack {
                                        Text(client)
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(TimeFormatter.shortFormat(hours))
                                            if rate > 0 {
                                                Text((hours * rate).formatted(.currency(code: "USD")))
                                                    .font(.caption)
                                            }
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(rate > 0
                                        ? "\(client): \(TimeFormatter.accessibleFormat(hours)) this week, \((hours * rate).formatted(.currency(code: "USD")))"
                                        : "\(client): \(TimeFormatter.accessibleFormat(hours)) this week"
                                    )
                                }
                            }
                        }
                        
                        Section("All Time") {
                            if !topClientsForChart.isEmpty {
                                GeometryReader { geo in
                                    let minBarWidth: CGFloat = 120
                                    let totalMinWidth = CGFloat(topClientsForChart.count) * minBarWidth
                                    let needsScroll = totalMinWidth > geo.size.width
                                    let chartWidth = needsScroll ? totalMinWidth : geo.size.width
                                    
                                    let chartContent = Chart(topClientsForChart, id: \.0) { client, hours in
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
                                    .frame(width: chartWidth, height: 200)
                                    .padding(.vertical, 8)
                                    
                                    if needsScroll {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            chartContent
                                        }
                                    } else {
                                        chartContent
                                    }
                                }
                                .frame(height: 216)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("All-time hours by client. \(chartAccessibilityDescription)")
                            }
                            
                            if allTimeByClient.isEmpty {
                                Text("No sessions logged yet")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(allTimeByClient, id: \.0) { client, hours in
                                    let rate = tallyStore.hourlyRate(for: client)
                                    NavigationLink {
                                        ClientDetailView(client: client)
                                    } label: {
                                        HStack {
                                            Text(client)
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(TimeFormatter.shortFormat(hours))
                                                if rate > 0 {
                                                    Text((hours * rate).formatted(.currency(code: "USD")))
                                                        .font(.caption)
                                                }
                                            }
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(rate > 0
                                        ? "\(client): \(TimeFormatter.accessibleFormat(hours)) total, \((hours * rate).formatted(.currency(code: "USD"))). Double tap for details."
                                        : "\(client): \(TimeFormatter.accessibleFormat(hours)) total. Double tap for details."
                                    )
                                }
                                
                                if allTimeByClient.count > 20 {
                                    Button {
                                        showAllClients = true
                                    } label: {
                                        Text("See all \(allTimeByClient.count) clients →")
                                            .font(.subheadline)
                                            .foregroundStyle(.blue)
                                    }
                                    .accessibilityLabel("See all \(allTimeByClient.count) clients")
                                }
                            }
                        }
                        
                        Section(purchases.hasFullHistory ? "Sessions" : "Sessions (last 7 days)") {
                            ForEach(tallyStore.visibleSessions) { session in
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.client)
                                            .font(.subheadline)
                                        if let note = session.taskNote, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .accessibilityElement(children: .combine)
                                    Spacer()
                                    Button {
                                        logAgainSession = session
                                        showLogAgain = true
                                    } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Log again for \(session.client)")
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(TimeFormatter.shortFormat(session.hours))
                                            .font(.subheadline)
                                        Text(session.date ?? "")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        sessionToEdit = session
                                        showEditSession = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                            }
                            .onDelete { indexSet in
                                if let index = indexSet.first {
                                    let visible = tallyStore.visibleSessions
                                    sessionToDelete = visible[visible.index(visible.startIndex, offsetBy: index)]
                                    showDeleteConfirmation = true
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
                        if purchases.canExportCSV {
                            showExportOptions = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: purchases.canExportCSV ? "square.and.arrow.up" : "lock.fill")
                    }
                    .accessibilityLabel(purchases.canExportCSV ? "Export hours" : "Upgrade to export")
                    .popoverTip(exportTip)
                    .onChange(of: purchases.canExportCSV) { _, canExport in
                        if canExport { exportTip.invalidate(reason: .actionPerformed) }
                    }
                }
            }
            .sheet(isPresented: $showExportOptions) {
                ExportOptionsView(
                    clients: tallyStore.recentClients,
                    onExport: { range, client in
                        export(range: range, client: client)
                        showExportOptions = false
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showLogAgain) {
                if let session = logAgainSession {
                    ManualEntryView(
                        prefillClient: session.client,
                        prefillNote: session.taskNote ?? ""
                    )
                }
            }
            .sheet(isPresented: $showEditSession) {
                if let session = sessionToEdit {
                    ManualEntryView(existingSession: session)
                }
            }
            .sheet(isPresented: $showAllClients) {
                AllClientsView(clients: allTimeByClient)
            }
            .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        if let session = sessionToDelete,
                           let index = tallyStore.sessions.firstIndex(where: { $0.id == session.id }) {
                            await tallyStore.deleteSessions(at: IndexSet([index]))
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let session = sessionToDelete {
                    Text("Delete \(TimeFormatter.shortFormat(session.hours)) session for \(session.client) on \(session.date ?? "")? This cannot be undone.")
                }
            }
            .task {
                isLoading = true
                await tallyStore.loadSessions()
                isLoading = false
                if purchases.canExportCSV {
                    exportTip.invalidate(reason: .actionPerformed)
                }
            }
        }
    }
    
    private func export(range: ExportRange, client: String?) {
        let clientName = client?.replacingOccurrences(of: " ", with: "-") ?? "all"
        let filename = "tally-\(clientName)-\(range.rawValue.lowercased().replacingOccurrences(of: " ", with: "-")).csv"
        let csv = CSVExporter.generate(sessions: tallyStore.sessions, range: range, client: client)
        let url = CSVExporter.save(csv: csv, filename: filename)
        exportURL = url
        #if canImport(AppKit)
        showExportOptions = false
        if let url {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
        #else
        showShareSheet = true
        #endif
    }
}
