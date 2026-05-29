//
//  ManualEntryView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct ManualEntryView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var client: String = ""
    @State private var hours: String = ""
    @State private var selectedDate: Date = .now
    @State private var taskNote: String = ""
    
    private var canSave: Bool {
        !client.isEmpty && !hours.isEmpty && Double(hours) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client name", text: $client)
                        .accessibilityLabel("Client name")
                        .accessibilityHint("Enter the name of the client you worked for")
                    
                    if !tallyStore.recentClients.isEmpty {
                        Picker("Recent clients", selection: $client) {
                            Text("Select a client").tag("")
                            ForEach(tallyStore.recentClients, id: \.self) { c in
                                Text(c).tag(c)
                            }
                        }
                        .accessibilityLabel("Select a recent client")
                    }
                }
                
                Section("Hours") {
                    TextField("e.g. 2.5", text: $hours)
                        .accessibilityLabel("Hours worked")
                        .accessibilityHint("Enter the number of hours")
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    
                    if let hoursDouble = Double(hours), !hours.isEmpty {
                        Text(TimeFormatter.accessibleFormat(hoursDouble))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                
                Section("Task Note (optional)") {
                    TextField("What did you work on?", text: $taskNote)
                        .accessibilityLabel("Task note")
                        .accessibilityHint("Describe what you worked on during this session")
                }
                
                Section("Date") {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .accessibilityLabel("Date worked")
                    .accessibilityHint("Select the date you performed this work")
                }
            }
            .navigationTitle("Log Hours")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Dismisses without saving")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityLabel("Save hours")
                        .accessibilityHint(canSave ? "Saves \(hours) hours for \(client)" : "Fill in client name and hours first")
                }
            }
        }
    }
    
    private func save() {
        guard let hoursDouble = Double(hours), !client.isEmpty else { return }
        Task {
            await tallyStore.addSession(
                client: client,
                hours: hoursDouble,
                taskNote: taskNote.isEmpty ? nil : taskNote
            )
            dismiss()
        }
    }
}
