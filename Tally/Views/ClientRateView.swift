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
    @State private var billingCycle: String = "monthly"
    @State private var billingStartDayText: String = ""
    @State private var billingWeekday: Int = 1 // Monday default
    private let billingTip = BillingPeriodTip()

    private let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

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
                    Picker("Cycle", selection: $billingCycle) {
                        Text("Monthly").tag("monthly")
                        Text("Weekly").tag("weekly")
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    if billingCycle == "monthly" {
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
                    } else {
                        Picker("Starts every", selection: $billingWeekday) {
                            ForEach(0..<7, id: \.self) { day in
                                Text(weekdayNames[day]).tag(day)
                            }
                        }
                    }
                } header: {
                    Text("Billing Cycle")
                } footer: {
                    if billingCycle == "monthly" {
                        Text("Which day of the month your billing cycle starts. Once set, Reports shows hours grouped by billing period.")
                    } else {
                        Text("Your billing cycle restarts every \(weekdayNames[billingWeekday]). Reports will group hours by week.")
                    }
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
                                let billingDay = billingCycle == "monthly"
                                    ? Int(billingStartDayText).flatMap { $0 >= 1 && $0 <= 28 ? $0 : nil }
                                    : nil
                                let weekday = billingCycle == "weekly" ? billingWeekday : nil
                                await tallyStore.saveClientRate(
                                    client: client,
                                    hourlyRate: rate,
                                    budgetHours: budget,
                                    billingCycle: billingCycle,
                                    billingStartDay: billingDay,
                                    billingWeekday: weekday
                                )
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
                billingCycle = tallyStore.billingCycle(for: client)
                if let day = tallyStore.billingStartDay(for: client) {
                    billingStartDayText = String(day)
                }
                if let weekday = tallyStore.billingWeekday(for: client) {
                    billingWeekday = weekday
                }
            }
        }
    }
}
