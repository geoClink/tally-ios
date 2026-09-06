//
//  ClientRateView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import TipKit

struct ClientRateView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.dismiss) private var dismiss
    
    let client: String
    @State private var rateText: String = ""
    @State private var budgetText: String = ""
    @State private var billingStartDayText: String = ""
    private let billingTip = BillingPeriodTip()

    var body: some View {
        NavigationStack {
            Form {
                Section("Hourly Rate for \(client)") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $rateText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .accessibilityLabel("Hourly rate")
                            .accessibilityHint("Enter your hourly rate for \(client)")
                    }

                    if let rate = Double(rateText), rate > 0 {
                        Text("At \(rate.formatted(.currency(code: CurrencyPreference.current))) per hour")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Project Budget") {
                    HStack {
                        TextField("No limit", text: $budgetText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .accessibilityLabel("Budget hours")
                            .accessibilityHint("Optional total hour budget for \(client)")
                        Text("hours")
                            .foregroundStyle(.secondary)
                    }

                    Text("Set a total hour budget to track how much of the project is used.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TipView(billingTip)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                Section {
                    HStack {
                        Text("Billing start day")
                        Spacer()
                        TextField("None", text: $billingStartDayText)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                            .frame(width: 60)
                            .accessibilityLabel("Billing start day")
                            .accessibilityHint("Day of the month your billing cycle begins, 1 to 28")
                        if !billingStartDayText.isEmpty {
                            Text("of each month")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Billing Cycle")
                } footer: {
                    Text("Which day of the month your billing cycle starts. Once set, Reports shows hours grouped by billing period.")
                }
            }
            .navigationTitle("Client Settings")
            #if os(macOS)
            .formStyle(.grouped)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let rate = Double(rateText) {
                                let budget = Double(budgetText)
                                let billingDay = Int(billingStartDayText).flatMap { $0 >= 1 && $0 <= 28 ? $0 : nil }
                                await tallyStore.saveClientRate(client: client, hourlyRate: rate, budgetHours: budget, billingStartDay: billingDay)
                            }
                            dismiss()
                        }
                    }
                    .disabled(Double(rateText) == nil || rateText.isEmpty)
                }
            }
            .onAppear {
                let existing = tallyStore.hourlyRate(for: client)
                if existing > 0 {
                    rateText = existing.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(existing))
                        : String(format: "%.2f", existing)
                }
                if let budget = tallyStore.budgetHours(for: client) {
                    budgetText = budget.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(budget))
                        : String(format: "%.1f", budget)
                }
                if let day = tallyStore.billingStartDay(for: client) {
                    billingStartDayText = String(day)
                }
            }
        }
    }
}
