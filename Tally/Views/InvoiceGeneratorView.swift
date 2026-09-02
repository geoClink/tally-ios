//
//  InvoiceGeneratorView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import Supabase
import Auth

struct InvoiceGeneratorView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.dismiss) private var dismiss
    
    let client: String
    @State private var selectedRange: ExportRange = .thisMonth
    @State private var invoiceNumber: String = "001"
    @State private var yourName: String = ""
    @State private var yourEmail: String = ""
    @State private var notes: String = ""
    @State private var showRatePicker = false
    @State private var generatedURL: URL?
    @State private var showShareSheet = false
    @State private var isGenerating = false
    @State private var clientEmail = ""
    @State private var paymentLinkURL = ""
    @State private var stripeURL: URL?
    @State private var isSendingStripe = false
    @State private var stripeError: String?
    private let purchases = PurchaseManager.shared
    
    private var billingRange: (start: Date, end: Date)? {
        guard selectedRange == .lastBillingPeriod,
              let startDay = tallyStore.billingStartDay(for: client) else { return nil }
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month], from: now)
        comps.day = startDay
        let currentStart = cal.date(from: comps) ?? now
        let adjustedCurrentStart = currentStart > now
            ? cal.date(byAdding: .month, value: -1, to: currentStart) ?? currentStart
            : currentStart
        let lastStart = cal.date(byAdding: .month, value: -1, to: adjustedCurrentStart) ?? adjustedCurrentStart
        let lastEnd = cal.date(byAdding: .day, value: -1, to: adjustedCurrentStart) ?? adjustedCurrentStart
        return (lastStart, lastEnd)
    }

    private var filteredSessions: [SessionModel] {
        let base = tallyStore.sessions.filter { $0.client == client }
        if selectedRange == .lastBillingPeriod {
            guard let range = billingRange else { return [] }
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: range.end)) ?? range.end
            return base.filter { $0.startTime >= range.start && $0.startTime < endOfDay }
        }
        return CSVExporter.filter(sessions: base, range: selectedRange)
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
        NavigationStack {
            Form {
                Section("Invoice Details") {
                    TextField("Invoice #", text: $invoiceNumber)
                        .accessibilityLabel("Invoice number")
                    
                    TextField("Your name", text: $yourName)
                        .accessibilityLabel("Your name")
                    
                    TextField("Your email", text: $yourEmail)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                        .accessibilityLabel("Your email")
                    
                    Picker("Period", selection: $selectedRange) {
                        ForEach(ExportRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
                
                Section("Client") {
                    HStack {
                        Text("Billing to")
                        Spacer()
                        Text(client)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Hourly rate")
                        Spacer()
                        if hourlyRate > 0 {
                            Text(hourlyRate.formatted(.currency(code: CurrencyPreference.current)))
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Set rate") {
                                showRatePicker = true
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }
                
                Section("Summary") {
                    HStack {
                        Text("Sessions")
                        Spacer()
                        Text("\(filteredSessions.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total hours")
                        Spacer()
                        Text(TimeFormatter.shortFormat(totalHours))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total amount")
                        Spacer()
                        Text(totalAmount.formatted(.currency(code: CurrencyPreference.current)))
                            .fontWeight(.semibold)
                            .foregroundStyle(totalAmount > 0 ? .primary : .secondary)
                    }
                }
                
                Section {
                    TextField("client@example.com", text: $clientEmail)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                        .accessibilityLabel("Client email")
                    TextField("https://buy.stripe.com/...", text: $paymentLinkURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                        .accessibilityLabel("Stripe payment link URL")
                } header: {
                    Text("Payment Link (optional)")
                } footer: {
                    Text("Paste a Stripe Payment Link and it will appear as a 'Pay Now' button in your PDF. Create one at dashboard.stripe.com → Payment Links.")
                        .font(.caption)
                }

                Section("Notes (optional)") {
                    TextField("Payment terms, thank you message...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    Button {
                        Task {
                            isGenerating = true
                            generatedURL = await InvoicePDFGenerator.generate(
                                invoiceNumber: invoiceNumber,
                                yourName: yourName,
                                yourEmail: yourEmail,
                                client: client,
                                sessions: filteredSessions,
                                hourlyRate: hourlyRate,
                                notes: notes,
                                paymentLink: paymentLinkURL
                            )
                            isGenerating = false
                            if generatedURL != nil {
                                showShareSheet = true
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                            } else {
                                Label("Generate Invoice PDF", systemImage: "doc.fill")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(yourName.isEmpty || hourlyRate == 0 || filteredSessions.isEmpty)

                    if purchases.canInvoice && !clientEmail.isEmpty {
                        Button {
                            Task { await sendStripeInvoice() }
                        } label: {
                            HStack {
                                Spacer()
                                if isSendingStripe {
                                    ProgressView()
                                } else {
                                    Label("Send Payment Link via Stripe", systemImage: "creditcard.fill")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.purple)
                                }
                                Spacer()
                            }
                        }
                        .disabled(hourlyRate == 0 || filteredSessions.isEmpty || isSendingStripe)
                    }

                    if let url = stripeURL {
                        Link(destination: url) {
                            Label("Open Stripe Invoice", systemImage: "arrow.up.right.square")
                                .foregroundStyle(.blue)
                        }
                    }
                    if let err = stripeError {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await tallyStore.loadClientRates() }
            .sheet(isPresented: $showRatePicker) {
                ClientRateView(client: client)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = generatedURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    private func sendStripeInvoice() async {
        guard hourlyRate > 0, !filteredSessions.isEmpty else { return }
        isSendingStripe = true
        stripeError = nil
        defer { isSendingStripe = false }
        do {
            let token = try await supabase.auth.session.accessToken
            let lineItems = [(
                description: "Time tracked for \(client) (\(TimeFormatter.shortFormat(totalHours)))",
                hours: totalHours,
                rate: hourlyRate
            )]
            let result = try await StripeManager.createInvoice(
                clientEmail: clientEmail,
                clientName: client,
                lineItems: lineItems,
                authToken: token
            )
            stripeURL = result.invoiceUrl
        } catch {
            stripeError = error.localizedDescription
        }
    }
}

