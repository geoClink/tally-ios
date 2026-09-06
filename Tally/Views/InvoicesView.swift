//
//  InvoicesView.swift
//  Tally
//

import SwiftUI

struct InvoicesView: View {
    @Environment(TallyStore.self) var tallyStore
    @State private var showClientPicker = false
    @State private var selectedClient = ""
    @State private var showGenerator = false
    @State private var statusFilter = "all"
    @State private var isLoading = false
    private let purchases = PurchaseManager.shared

    private var filteredInvoices: [InvoiceModel] {
        switch statusFilter {
        case "outstanding": return tallyStore.invoices.filter { $0.status != "paid" }
        case "paid":        return tallyStore.invoices.filter { $0.status == "paid" }
        default:            return tallyStore.invoices
        }
    }

    private var outstandingTotal: Double {
        tallyStore.invoices.filter { $0.status != "paid" }.reduce(0) { $0 + $1.totalAmount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !purchases.canInvoice {
                    PaywallView()
                } else {
                    invoiceContent
                }
            }
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showClientPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showClientPicker) {
                clientPickerSheet
            }
            .sheet(isPresented: $showGenerator) {
                if !selectedClient.isEmpty {
                    InvoiceGeneratorView(client: selectedClient)
                }
            }
            .task {
                await tallyStore.loadInvoices()
                await tallyStore.loadClientRates()
            }
        }
    }

    private var invoiceContent: some View {
        List {
            if outstandingTotal > 0 {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Outstanding")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(outstandingTotal, format: .currency(code: CurrencyPreference.current))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("\(tallyStore.invoices.filter { $0.status != "paid" }.count) unpaid")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Picker("Filter", selection: $statusFilter) {
                    Text("All").tag("all")
                    Text("Outstanding").tag("outstanding")
                    Text("Paid").tag("paid")
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
            }

            if filteredInvoices.isEmpty {
                Section {
                    Text(tallyStore.invoices.isEmpty ? "No invoices yet. Tap + to create one." : "No invoices match this filter.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } else {
                Section {
                    ForEach(filteredInvoices) { inv in
                        InvoiceRowView(invoice: inv)
                    }
                }
            }
        }
    }

    private var clientPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(tallyStore.recentClients, id: \.self) { client in
                    Button(client) {
                        selectedClient = client
                        showClientPicker = false
                        showGenerator = true
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Select Client")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showClientPicker = false }
                }
            }
        }
    }
}

struct InvoiceRowView: View {
    @Environment(TallyStore.self) var tallyStore
    let invoice: InvoiceModel
    @State private var showDeleteConfirm = false

    private var statusColor: Color {
        switch invoice.status {
        case "paid":  return .green
        case "sent":  return .orange
        default:      return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(invoice.client)
                        .font(.headline)
                    Text(invoice.invoiceNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(invoice.totalAmount, format: .currency(code: CurrencyPreference.current))
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text(invoice.status.capitalized)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                }
            }

            Text("\(invoice.startDate) — \(invoice.endDate)  ·  \(TimeFormatter.shortFormat(invoice.totalHours))")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if invoice.status != "paid" {
                    Button("Mark Paid") {
                        Task { await tallyStore.updateInvoiceStatus(id: invoice.id, status: "paid") }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.green)
                } else {
                    Button("Mark Unpaid") {
                        Task { await tallyStore.updateInvoiceStatus(id: invoice.id, status: "sent") }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                if let urlString = invoice.stripeInvoiceUrl, let url = URL(string: urlString) {
                    Link("Pay Link", destination: url)
                        .font(.caption)
                        .buttonStyle(.bordered)
                }

                Spacer()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("Delete this invoice?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await tallyStore.deleteInvoice(id: invoice.id) }
            }
        }
    }
}
