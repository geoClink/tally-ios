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
    
    var body: some View {
        List {
            // Summary card
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TimeFormatter.shortFormat(totalHours))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Total hours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if hourlyRate > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(totalAmount.formatted(.currency(code: "USD")))
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Total earnings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
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
                        Text(hourlyRate > 0 ? hourlyRate.formatted(.currency(code: "USD")) : "Not set")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                
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
                        }
                    }
                }
                .disabled(filteredSessions.isEmpty && purchases.canInvoice)
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
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.date ?? "")
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
                                if hourlyRate > 0 {
                                    Text((session.hours * hourlyRate).formatted(.currency(code: "USD")))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
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
