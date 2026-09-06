//
//  ReportsView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Charts
import TipKit

enum ReportPeriod: String, CaseIterable {
    case thisWeek    = "This Week"
    case lastWeek    = "Last Week"
    case thisMonth   = "This Month"
    case billing     = "Billing Period"
    case custom      = "Custom Range"
    case allTime     = "All Time"
}

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
    @State private var sessionToEdit: SessionModel?
    @State private var chartAnimated = false
    @State private var billingClient: String = ""
    @State private var customStart: Date = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()
    @State private var selectedPeriod: ReportPeriod = .thisWeek

    private let purchases = PurchaseManager.shared
    private let exportTip = ExportLockedTip()
    @Environment(\.colorScheme) private var colorScheme

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }

    // MARK: - Computed data

    private var weeklyByClient: [(String, Double)] {
        let calendar = tallyStore.weekStartDay.calendar
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        var dict: [String: Double] = [:]
        for session in tallyStore.sessions.filter({ $0.startTime >= weekStart }) {
            dict[session.client, default: 0] += session.hours
        }
        return dict.sorted { $0.value > $1.value }
    }

    private var lastWeekByClient: [(String, Double)] {
        let calendar = tallyStore.weekStartDay.calendar
        let now = Date()
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? thisWeekStart
        let lastWeekEnd = calendar.date(byAdding: .day, value: -1, to: thisWeekStart) ?? thisWeekStart
        var dict: [String: Double] = [:]
        for session in tallyStore.sessions.filter({ $0.startTime >= lastWeekStart && $0.startTime <= lastWeekEnd }) {
            dict[session.client, default: 0] += session.hours
        }
        return dict.sorted { $0.value > $1.value }
    }

    private var lastWeekLabel: String {
        let calendar = tallyStore.weekStartDay.calendar
        let now = Date()
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? thisWeekStart
        let lastWeekEnd = calendar.date(byAdding: .day, value: -1, to: thisWeekStart) ?? thisWeekStart
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: lastWeekStart)) – \(fmt.string(from: lastWeekEnd))"
    }

    private var thisMonthByClient: [(String, Double)] {
        let now = Date()
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        var dict: [String: Double] = [:]
        for session in tallyStore.sessions.filter({ $0.startTime >= monthStart }) {
            dict[session.client, default: 0] += session.hours
        }
        return dict.sorted { $0.value > $1.value }
    }

    private var billingClients: [(client: String, startDay: Int)] {
        tallyStore.clientRates
            .compactMap { r in r.billingStartDay.map { (client: r.client, startDay: $0) } }
            .sorted { $0.client < $1.client }
    }

    private var customRangeByClient: [(String, Double)] {
        let start = Calendar.current.startOfDay(for: customStart)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: customEnd)) ?? customEnd
        var dict: [String: Double] = [:]
        for session in tallyStore.sessions.filter({ $0.startTime >= start && $0.startTime < end }) {
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

    private var topClientsForChart: [(String, Double)] {
        Array(allTimeByClient.prefix(20))
    }

    private var chartAccessibilityDescription: String {
        topClientsForChart
            .map { "\($0.0): \(TimeFormatter.accessibleFormat($0.1))" }
            .joined(separator: "; ")
    }

    // Sessions filtered to the selected period
    private var filteredSessions: [SessionModel] {
        switch selectedPeriod {
        case .thisWeek:
            let calendar = tallyStore.weekStartDay.calendar
            let now = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            return tallyStore.visibleSessions.filter { $0.startTime >= weekStart }
        case .lastWeek:
            let calendar = tallyStore.weekStartDay.calendar
            let now = Date()
            let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? thisWeekStart
            return tallyStore.visibleSessions.filter { $0.startTime >= lastWeekStart && $0.startTime < thisWeekStart }
        case .thisMonth:
            let now = Date()
            let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
            return tallyStore.visibleSessions.filter { $0.startTime >= monthStart }
        case .billing:
            guard !billingClient.isEmpty,
                  let startDay = tallyStore.billingStartDay(for: billingClient) else { return [] }
            let periodStart = tallyStore.billingPeriodStart(startDay: startDay)
            return tallyStore.visibleSessions.filter { $0.startTime >= periodStart && $0.client == billingClient }
        case .custom:
            let start = Calendar.current.startOfDay(for: customStart)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: customEnd)) ?? customEnd
            return tallyStore.visibleSessions.filter { $0.startTime >= start && $0.startTime < end }
        case .allTime:
            return tallyStore.visibleSessions
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: geo.size.width * 0.85)
                            .blur(radius: 90)
                            .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.08)
                        Circle()
                            .fill(Color.indigo.opacity(0.12))
                            .frame(width: geo.size.width * 0.7)
                            .blur(radius: 75)
                            .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.55)
                    }
                }
                .ignoresSafeArea()

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
                        VStack(spacing: 0) {
                            filterPillBar
                            mainList
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
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
                            .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(purchases.canExportCSV ? "Export hours" : "Upgrade to export")
                    .popoverTip(exportTip)
                    .onChange(of: purchases.canExportCSV) { _, canExport in
                        ExportLockedTip.isLocked = !canExport
                    }
                }
            }
            .sheet(isPresented: $showExportOptions) {
                ExportOptionsView(
                    clients: tallyStore.recentClients,
                    onExport: { range, client in
                        export(range: range, client: client)
                        showExportOptions = false
                    },
                    onExportDates: { startDate, endDate, client in
                        exportCustom(from: startDate, to: endDate, client: client)
                        showExportOptions = false
                    }
                )
                #if os(iOS)
                .presentationDetents([.large])
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL { ShareSheet(url: url) }
            }
            #endif
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: $logAgainSession) { session in
                ManualEntryView(prefillClient: session.client, prefillNote: session.taskNote ?? "")
            }
            .sheet(item: $sessionToEdit) { session in
                ManualEntryView(existingSession: session)
            }
            .sheet(isPresented: $showAllClients) {
                AllClientsView(clients: allTimeByClient)
            }
            .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        if let session = sessionToDelete {
                            await tallyStore.deleteSession(session)
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
                ExportLockedTip.isLocked = !purchases.canExportCSV
                await tallyStore.loadConfig()
                await tallyStore.loadSessions()
                isLoading = false
            }
        }
    }

    // MARK: - Filter pill bar

    private var filterPillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedPeriod == period
                                    ? Color.blue
                                    : Color.primary.opacity(0.08),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedPeriod == period ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedPeriod == period ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Main list

    private var mainList: some View {
        List {
            // Weekly goal bar (only This Week)
            if selectedPeriod == .thisWeek && tallyStore.weeklyGoal > 0 {
                Section {
                    ProgressBarView(value: tallyStore.weeklyHours, goal: tallyStore.weeklyGoal)
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Weekly goal: \(TimeFormatter.accessibleFormat(tallyStore.weeklyHours)) of \(TimeFormatter.accessibleFormat(tallyStore.weeklyGoal))")
                }
            }

            // Billing period client picker
            if selectedPeriod == .billing {
                Section {
                    if billingClients.isEmpty {
                        Text("No billing periods set. Add one in Client Rates.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        Picker("Client", selection: $billingClient) {
                            Text("Select a client…").tag("")
                            ForEach(billingClients, id: \.client) { item in
                                Text(item.client).tag(item.client)
                            }
                        }
                        .accessibilityLabel("Select client for billing period")

                        if !billingClient.isEmpty,
                           let startDay = tallyStore.billingStartDay(for: billingClient) {
                            let periodStart = tallyStore.billingPeriodStart(startDay: startDay)
                            let periodEnd = Calendar.current.date(
                                byAdding: .day, value: -1,
                                to: Calendar.current.date(byAdding: .month, value: 1, to: periodStart) ?? periodStart
                            ) ?? periodStart
                            Text("\(periodStart.formatted(.dateTime.month(.abbreviated).day())) – \(periodEnd.formatted(.dateTime.month(.abbreviated).day()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Custom range date pickers
            if selectedPeriod == .custom {
                Section {
                    DatePicker("From", selection: $customStart, displayedComponents: .date)
                    DatePicker("To", selection: $customEnd, in: customStart..., displayedComponents: .date)
                }
            }

            // Client breakdown
            Section {
                let breakdown = currentBreakdown
                if breakdown.isEmpty {
                    Text(selectedPeriod == .billing && billingClient.isEmpty
                         ? "Select a client above"
                         : "No sessions for this period")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(breakdown, id: \.0) { client, hours in
                        let rate = tallyStore.hourlyRate(for: client)
                        let goal = tallyStore.clientGoals.first { $0.client == client }
                        let progress: Double? = selectedPeriod == .thisWeek
                            ? goal.map { min(1.0, hours / $0.weeklyHours) }
                            : nil
                        HStack(alignment: .center, spacing: 10) {
                            if let progress {
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 3)
                                    Circle()
                                        .trim(from: 0, to: progress)
                                        .stroke(
                                            progress >= 1.0 ? Color.green : Color.blue,
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeOut(duration: 0.4), value: progress)
                                }
                                .frame(width: 22, height: 22)
                            }
                            NavigationLink {
                                ClientDetailView(client: client)
                            } label: {
                                HStack {
                                    Text(client)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(TimeFormatter.shortFormat(hours))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                            .monospacedDigit()
                                        if rate > 0 {
                                            Text((hours * rate).formatted(.currency(code: CurrencyPreference.current)))
                                                .font(.caption)
                                                .foregroundStyle(.blue)
                                                .monospacedDigit()
                                        }
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(rate > 0
                            ? "\(client): \(TimeFormatter.accessibleFormat(hours)), \((hours * rate).formatted(.currency(code: CurrencyPreference.current))). Double tap for details."
                            : "\(client): \(TimeFormatter.accessibleFormat(hours)). Double tap for details."
                        )
                    }

                    if selectedPeriod == .allTime && allTimeByClient.count > 20 {
                        Button { showAllClients = true } label: {
                            Text("See all \(allTimeByClient.count) clients →")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            } header: {
                Text(periodLabel)
                    .font(.caption.weight(.semibold))
                    .tracking(0.5)
                    .textCase(.uppercase)
            }

            // All Time chart (only shown when All Time is selected)
            if selectedPeriod == .allTime && !topClientsForChart.isEmpty {
                Section {
                    GeometryReader { geo in
                        let minBarWidth: CGFloat = 120
                        let totalMinWidth = CGFloat(topClientsForChart.count) * minBarWidth
                        let needsScroll = totalMinWidth > geo.size.width
                        let chartWidth = needsScroll ? totalMinWidth : geo.size.width
                        let chartContent = Chart(topClientsForChart, id: \.0) { client, hours in
                            BarMark(
                                x: .value("Client", client),
                                y: .value("Hours", chartAnimated ? hours : 0)
                            )
                            .foregroundStyle(by: .value("Client", client))
                            .cornerRadius(6)
                            .annotation(position: .top) {
                                Text(TimeFormatter.shortFormat(hours))
                                    .font(.caption2.bold())
                                    .foregroundStyle(captionColor)
                                    .opacity(chartAnimated ? 1 : 0)
                            }
                        }
                        .chartYAxis(.hidden)
                        .chartLegend(.hidden)
                        .animation(.easeOut(duration: 0.7), value: chartAnimated)
                        .frame(width: chartWidth, height: 220)
                        .padding(.vertical, 8)

                        if needsScroll {
                            ScrollView(.horizontal, showsIndicators: false) { chartContent }
                        } else {
                            chartContent
                        }
                    }
                    .frame(height: 236)
                    .task {
                        chartAnimated = false
                        try? await Task.sleep(for: .seconds(0.15))
                        withAnimation(.easeOut(duration: 0.7)) { chartAnimated = true }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("All-time hours by client. \(chartAccessibilityDescription)")
                }
            }

            // Billable summary
            Section {
                let billableHours = filteredSessions.filter { $0.isBillable }.reduce(0) { $0 + $1.hours }
                let nonBillableHours = filteredSessions.filter { !$0.isBillable }.reduce(0) { $0 + $1.hours }
                if billableHours > 0 || nonBillableHours > 0 {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill").foregroundStyle(.green)
                            Text("\(TimeFormatter.shortFormat(billableHours)) billable")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        if nonBillableHours > 0 {
                            Text("·").foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle")
                                Text("\(TimeFormatter.shortFormat(nonBillableHours)) non-billable")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(TimeFormatter.accessibleFormat(billableHours)) billable, \(TimeFormatter.accessibleFormat(nonBillableHours)) non-billable")
                }

                ForEach(filteredSessions) { session in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(session.client).font(.subheadline)
                                if !session.isBillable {
                                    Text("non-billable")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.12), in: Capsule())
                                }
                            }
                            if let note = session.taskNote, !note.isEmpty {
                                Text(note).font(.caption).foregroundStyle(captionColor)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        Spacer()
                        Button {
                            logAgainSession = session
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Log again for \(session.client)")
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(TimeFormatter.shortFormat(session.hours)).font(.subheadline)
                            Text(session.date ?? "").font(.caption).foregroundStyle(captionColor)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .swipeActions(edge: .leading) {
                        Button { sessionToEdit = session } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            sessionToDelete = session
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text(purchases.hasFullHistory ? "Sessions" : "Sessions (Last 7 Days)")
                    .font(.caption.weight(.semibold))
                    .tracking(0.5)
                    .textCase(.uppercase)
            }
            #if os(iOS)
            .listSectionSpacing(.compact)
            #endif
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Helpers

    private var currentBreakdown: [(String, Double)] {
        switch selectedPeriod {
        case .thisWeek:    return weeklyByClient
        case .lastWeek:    return lastWeekByClient
        case .thisMonth:   return thisMonthByClient
        case .billing:     return billingClient.isEmpty ? [] : customRangeByClientForBilling
        case .custom:      return customRangeByClient
        case .allTime:     return allTimeByClient
        }
    }

    private var customRangeByClientForBilling: [(String, Double)] {
        guard tallyStore.billingStartDay(for: billingClient) != nil else { return [] }
        let hours = tallyStore.billingPeriodHours(client: billingClient)
        return [(billingClient, hours)]
    }

    private var periodLabel: String {
        switch selectedPeriod {
        case .thisWeek:  return "This Week"
        case .lastWeek:  return "Last Week · \(lastWeekLabel)"
        case .thisMonth: return "This Month"
        case .billing:   return "Billing Period"
        case .custom:    return "Custom Range"
        case .allTime:   return "All Time"
        }
    }

    // MARK: - Export

    private func export(range: ExportRange, client: String?) {
        let clientName = client?.replacingOccurrences(of: " ", with: "-") ?? "all"
        let filename = "tally-\(clientName)-\(range.rawValue.lowercased().replacingOccurrences(of: " ", with: "-")).csv"
        let csv = CSVExporter.generate(sessions: tallyStore.sessions, range: range, client: client)
        let url = CSVExporter.save(csv: csv, filename: filename)
        exportURL = url
        #if canImport(AppKit)
        showExportOptions = false
        if let url { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        #else
        showShareSheet = true
        #endif
    }

    private func exportCustom(from startDate: Date, to endDate: Date, client: String?) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let clientName = client?.replacingOccurrences(of: " ", with: "-") ?? "all"
        let filename = "tally-\(clientName)-\(fmt.string(from: startDate))-to-\(fmt.string(from: endDate)).csv"
        let csv = CSVExporter.generate(sessions: tallyStore.sessions, from: startDate, to: endDate, client: client)
        let url = CSVExporter.save(csv: csv, filename: filename)
        exportURL = url
        #if canImport(AppKit)
        showExportOptions = false
        if let url { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        #else
        showShareSheet = true
        #endif
    }
}
