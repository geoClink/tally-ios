//
//  ClientDetailReview.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import TipKit

struct ClientDetailView: View {
    @Environment(TallyStore.self) var tallyStore
    
    let client: String
    @State private var showInvoice = false
    @State private var showRatePicker = false
    @State private var showPaywall = false
    private let purchases = PurchaseManager.shared
    private let invoiceTip = InvoiceLockedTip()
    @Environment(\.colorScheme) private var colorScheme

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }
    @State private var selectedRange: ExportRange = .allTime
    
    private var filteredSessions: [SessionModel] {
        CSVExporter.filter(sessions: tallyStore.sessions, range: selectedRange)
            .filter { $0.client == client }
    }
    
    private var totalHours: Double {
        filteredSessions.reduce(0) { $0 + $1.hours }
    }
    
    private var hourlyRate: Double {
        tallyStore.hourlyRate(for: client)
    }
    
    private var totalAmount: Double {
        totalHours * hourlyRate
    }

    private var allTimeHours: Double {
        tallyStore.sessions.filter { $0.client == client }.reduce(0) { $0 + $1.hours }
    }

    private var budget: Double? {
        tallyStore.budgetHours(for: client)
    }
    
    var body: some View {
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

        List {
            // Summary card
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TimeFormatter.shortFormat(totalHours))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("Total hours")
                            .font(.caption.weight(.medium))
                            .tracking(0.3)
                            .foregroundStyle(captionColor)
                    }
                    Spacer()
                    if hourlyRate > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(totalAmount.formatted(.currency(code: CurrencyPreference.current)))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("Total earnings")
                                .font(.caption.weight(.medium))
                                .tracking(0.3)
                                .foregroundStyle(captionColor)
                        }
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(hourlyRate > 0
                    ? "\(TimeFormatter.accessibleFormat(totalHours)) total, \(totalAmount.formatted(.currency(code: CurrencyPreference.current))) earned"
                    : "\(TimeFormatter.accessibleFormat(totalHours)) total"
                )

                if let budget, budget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressBarView(value: allTimeHours, goal: budget)
                        HStack {
                            let remaining = budget - allTimeHours
                            if remaining >= 0 {
                                Text("\(TimeFormatter.shortFormat(remaining)) remaining of \(TimeFormatter.shortFormat(budget)) budget")
                            } else {
                                Text("\(TimeFormatter.shortFormat(-remaining)) over budget")
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                        }
                        .font(.caption)
                        .foregroundStyle(captionColor)
                    }
                }
            }

            // Range picker
            Section {
                Picker("Period", selection: $selectedRange) {
                    ForEach(ExportRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Rate and invoice actions
            Section {
                Button {
                    showRatePicker = true
                } label: {
                    HStack {
                        Label("Hourly Rate", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(hourlyRate > 0 ? hourlyRate.formatted(.currency(code: CurrencyPreference.current)) : "Not set")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                .foregroundStyle(.primary)
                .accessibilityLabel("Hourly rate: \(hourlyRate > 0 ? hourlyRate.formatted(.currency(code: CurrencyPreference.current)) : "not set")")
                .accessibilityHint("Opens rate settings for \(client)")
                
                Button {
                    if purchases.canInvoice {
                        showInvoice = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack {
                        Label("Generate Invoice", systemImage: "doc.text")
                            .foregroundStyle(purchases.canInvoice ? .blue : .secondary)
                        if !purchases.canInvoice {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .disabled(filteredSessions.isEmpty && purchases.canInvoice)
                .accessibilityHint(purchases.canInvoice ? "Generates a PDF invoice for \(client)" : "Requires Business plan")
                .popoverTip(invoiceTip)
                .onChange(of: purchases.canInvoice) { _, can in
                    if can { invoiceTip.invalidate(reason: .actionPerformed) }
                }
            }
            
            // Sessions list
            Section("Sessions") {
                if filteredSessions.isEmpty {
                    Text("No sessions for this period")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredSessions) { session in
                        let sessionLabel: String = {
                            var parts: [String] = []
                            if let date = session.date { parts.append(date) }
                            if let note = session.taskNote, !note.isEmpty { parts.append(note) }
                            parts.append(TimeFormatter.accessibleFormat(session.hours))
                            if hourlyRate > 0 {
                                parts.append((session.hours * hourlyRate).formatted(.currency(code: CurrencyPreference.current)))
                            }
                            return parts.joined(separator: ", ")
                        }()
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.date ?? "")
                                    .font(.subheadline)
                                if let note = session.taskNote, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(captionColor)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(TimeFormatter.shortFormat(session.hours))
                                    .font(.subheadline)
                                if hourlyRate > 0 {
                                    Text((session.hours * hourlyRate).formatted(.currency(code: CurrencyPreference.current)))
                                        .font(.caption)
                                        .foregroundStyle(captionColor)
                                }
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(sessionLabel)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        } // ZStack
        .navigationTitle(client)
        .sheet(isPresented: $showRatePicker) {
            ClientRateView(client: client)
        }
        .sheet(isPresented: $showInvoice) {
            InvoiceGeneratorView(client: client)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .task {
            await tallyStore.loadClientRates()
        }
    }
}
