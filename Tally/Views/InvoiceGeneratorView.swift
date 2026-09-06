//
//  InvoiceGeneratorView.swift
//  Tally
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
    @State private var taxRate: Double = 0
    @State private var stripeConnected = false
    @State private var isSendingStripe = false
    @State private var stripeError: String?
    @State private var savedInvoice: InvoiceModel?
    @State private var showSuccess = false
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

    private var totalHours: Double { filteredSessions.reduce(0) { $0 + $1.hours } }
    private var hourlyRate: Double { tallyStore.hourlyRate(for: client) }
    private var subtotal: Double { totalHours * hourlyRate }
    private var taxAmount: Double { subtotal * (taxRate / 100) }
    private var totalAmount: Double { subtotal + taxAmount }

    private var rangeStartString: String {
        if selectedRange == .lastBillingPeriod, let r = billingRange {
            return dateString(r.start)
        }
        return dateString(CSVExporter.startDate(for: selectedRange) ?? Date())
    }

    private var rangeEndString: String {
        if selectedRange == .lastBillingPeriod, let r = billingRange {
            return dateString(r.end)
        }
        return dateString(Date())
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Invoice Details") {
                    TextField("Invoice #", text: $invoiceNumber)
                    TextField("Your name", text: $yourName)
                    TextField("Your email", text: $yourEmail)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif

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
                        Text(client).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Hourly rate")
                        Spacer()
                        if hourlyRate > 0 {
                            Text(hourlyRate.formatted(.currency(code: CurrencyPreference.current)))
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Set rate") { showRatePicker = true }
                                .foregroundStyle(.blue)
                        }
                    }
                    TextField("Client email", text: $clientEmail)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        #endif
                }

                Section("Summary") {
                    HStack {
                        Text("Sessions")
                        Spacer()
                        Text("\(filteredSessions.count)").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total hours")
                        Spacer()
                        Text(TimeFormatter.shortFormat(totalHours)).foregroundStyle(.secondary)
                    }
                    if taxRate > 0 {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(subtotal.formatted(.currency(code: CurrencyPreference.current)))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Tax (\(taxRate.formatted())%)")
                            Spacer()
                            Text(taxAmount.formatted(.currency(code: CurrencyPreference.current)))
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(totalAmount.formatted(.currency(code: CurrencyPreference.current)))
                            .fontWeight(.semibold)
                            .foregroundStyle(totalAmount > 0 ? .primary : .secondary)
                    }
                }

                Section {
                    HStack {
                        Text("Tax rate")
                        Spacer()
                        TextField("0", value: $taxRate, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Tax (optional)")
                }

                Section("Notes (optional)") {
                    TextField("Payment terms, thank you message…", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section {
                    if let err = stripeError {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                    if showSuccess {
                        Label("Invoice saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Section {
                    if stripeConnected && purchases.canInvoice {
                        stripeButton
                    }
                    generateButton
                }
            }
            .navigationTitle("Create Invoice")
            #if os(macOS)
            .formStyle(.grouped)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await tallyStore.loadClientRates()
                clientEmail = tallyStore.clientEmail(for: client)
                yourName = tallyStore.contactEmail ?? ""
                await checkStripeConnected()
            }
            .sheet(isPresented: $showRatePicker) {
                ClientRateView(client: client)
            }
            #if os(iOS)
            .sheet(isPresented: $showShareSheet) {
                if let url = generatedURL {
                    ShareSheet(url: url)
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 600)
        #endif
    }

    private var generateButton: some View {
        Button {
            Task { await generatePDF() }
        } label: {
            HStack {
                Spacer()
                if isGenerating {
                    ProgressView()
                } else {
                    Label("Download PDF", systemImage: "arrow.down.doc.fill")
                        .fontWeight(.semibold)
                }
                Spacer()
            }
        }
        .disabled(yourName.isEmpty || hourlyRate == 0 || filteredSessions.isEmpty)
    }

    private var stripeButton: some View {
        Button {
            Task { await sendStripeInvoice() }
        } label: {
            HStack {
                Spacer()
                if isSendingStripe {
                    ProgressView()
                } else {
                    Label("Send Invoice via Stripe", systemImage: "creditcard.fill")
                        .fontWeight(.semibold)
                }
                Spacer()
            }
        }
        .tint(.blue)
        .disabled(hourlyRate == 0 || filteredSessions.isEmpty || isSendingStripe)
    }

    // MARK: - Actions

    private func generatePDF() async {
        isGenerating = true
        generatedURL = await InvoicePDFGenerator.generate(
            invoiceNumber: invoiceNumber,
            yourName: yourName,
            yourEmail: yourEmail,
            client: client,
            sessions: filteredSessions,
            hourlyRate: hourlyRate,
            taxRate: taxRate,
            notes: notes
        )
        isGenerating = false
        if let url = generatedURL {
            await saveInvoiceRecord(status: "draft")
            #if os(iOS)
            showShareSheet = true
            #else
            NSWorkspace.shared.open(url)
            #endif
        }
    }

    private func sendStripeInvoice() async {
        guard hourlyRate > 0, !filteredSessions.isEmpty else { return }
        guard !clientEmail.isEmpty else {
            stripeError = "Add a client email before sending via Stripe."
            return
        }
        isSendingStripe = true
        stripeError = nil
        defer { isSendingStripe = false }
        do {
            let token = try await supabase.auth.session.accessToken
            let lineItems = filteredSessions.map { session in (
                description: session.taskNote ?? session.date ?? "Work",
                hours: session.hours,
                rate: hourlyRate
            )}
            let result = try await StripeManager.createInvoice(
                clientEmail: clientEmail,
                clientName: client,
                lineItems: lineItems,
                memo: notes.isEmpty ? nil : notes,
                authToken: token
            )
            await saveInvoiceRecord(status: "sent", stripeInvoiceId: result.invoiceId, stripeInvoiceUrl: result.invoiceUrl.absoluteString)
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSuccess = false }
        } catch {
            stripeError = error.localizedDescription
        }
    }

    private func saveInvoiceRecord(status: String, stripeInvoiceId: String? = nil, stripeInvoiceUrl: String? = nil) async {
        guard let user = try? await supabase.auth.user() else { return }
        let lineItems = filteredSessions.map { s in
            InvoiceLineItem(date: s.date, hours: s.hours, taskNote: s.taskNote, amount: s.hours * hourlyRate)
        }
        let insert = InvoiceInsert(
            userId: user.id.uuidString,
            invoiceNumber: invoiceNumber,
            yourName: yourName.isEmpty ? nil : yourName,
            client: client,
            clientEmail: clientEmail.isEmpty ? nil : clientEmail,
            startDate: rangeStartString,
            endDate: rangeEndString,
            totalHours: totalHours,
            hourlyRate: hourlyRate,
            totalAmount: totalAmount,
            taxRate: taxRate,
            taxAmount: taxAmount,
            memo: notes.isEmpty ? nil : notes,
            status: status,
            lineItems: lineItems
        )
        _ = try? await tallyStore.saveInvoice(insert)
    }

    private func checkStripeConnected() async {
        guard let user = try? await supabase.auth.user() else { return }
        struct ConnectRow: Decodable { let onboarded: Bool }
        let rows: [ConnectRow]? = try? await supabase
            .from("stripe_connect_accounts")
            .select("onboarded")
            .eq("user_id", value: user.id.uuidString)
            .limit(1)
            .execute()
            .value
        stripeConnected = rows?.first?.onboarded ?? false
    }
}
