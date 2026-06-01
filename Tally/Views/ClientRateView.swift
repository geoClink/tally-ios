//
//  ClientRateView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct ClientRateView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.dismiss) private var dismiss
    
    let client: String
    @State private var rateText: String = ""
    
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
                        Text("At \(rate.formatted(.currency(code: "USD"))) per hour")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("About Rates") {
                    Text("Your hourly rate is used to calculate invoice totals. It's stored privately and never shared.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Set Rate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let rate = Double(rateText) {
                                await tallyStore.saveClientRate(client: client, hourlyRate: rate)
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
                    rateText = String(existing)
                }
            }
        }
    }
}
