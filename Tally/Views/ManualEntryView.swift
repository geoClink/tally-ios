//
//  ManualEntryView.swift
//  Tally
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ManualEntryView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.dismiss) private var dismiss

    var existingSession: SessionModel? = nil

    @State private var client: String
    @State private var selectedHours: Int
    @State private var selectedMinutes: Int
    @State private var selectedDate: Date
    @State private var taskNote: String
    @State private var isBillable: Bool
    @State private var hoursText: String = ""

    private static let minuteOptions = Array(stride(from: 0, through: 55, by: 5))

    private func parseHoursText(_ text: String) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return 0 }
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            let h = Double(parts.first ?? "0") ?? 0
            let m = Double(parts.dropFirst().first ?? "0") ?? 0
            return h + m / 60
        }
        return Double(trimmed) ?? 0
    }

    init(prefillClient: String = "", prefillNote: String = "", prefillHours: Double = 0, existingSession: SessionModel? = nil) {
        self.existingSession = existingSession
        _client = State(initialValue: existingSession?.client ?? prefillClient)
        _taskNote = State(initialValue: existingSession?.taskNote ?? prefillNote)
        _selectedDate = State(initialValue: existingSession?.startTime ?? .now)
        _isBillable = State(initialValue: existingSession?.isBillable ?? true)
        if let session = existingSession {
            let totalMins = Int((session.hours * 60).rounded())
            _selectedHours = State(initialValue: totalMins / 60)
            _selectedMinutes = State(initialValue: (totalMins % 60) / 5 * 5)
        } else {
            let totalMins = Int((prefillHours * 60).rounded())
            _selectedHours = State(initialValue: totalMins / 60)
            _selectedMinutes = State(initialValue: (totalMins % 60) / 5 * 5)
        }
    }

    private var computedHours: Double {
        let parsed = parseHoursText(hoursText)
        if parsed > 0 { return parsed }
        return Double(selectedHours) + Double(selectedMinutes) / 60.0
    }

    private var canSave: Bool {
        !client.isEmpty && computedHours > 0
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

                Section("Duration") {
                    TextField("Quick entry: 1:30 or 1.5", text: $hoursText)
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                        .accessibilityLabel("Hours quick entry")
                        .accessibilityHint("Type hours as decimal like 1.5, or hours:minutes like 1:30")

                    #if os(iOS)
                    HStack(spacing: 0) {
                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0..<24, id: \.self) { h in
                                Text("\(h) hr").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(Self.minuteOptions, id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                    #else
                    HStack {
                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0..<24, id: \.self) { h in Text("\(h)h").tag(h) }
                        }
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(Self.minuteOptions, id: \.self) { m in Text("\(m)m").tag(m) }
                        }
                    }
                    #endif

                    if computedHours > 0 {
                        Text(TimeFormatter.accessibleFormat(computedHours))
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

                Section("Billing") {
                    Toggle(isOn: $isBillable) {
                        Label("Billable", systemImage: isBillable ? "dollarsign.circle.fill" : "dollarsign.circle")
                    }
                    .tint(.green)
                    .accessibilityLabel(isBillable ? "Billable — toggle to mark as non-billable" : "Non-billable — toggle to mark as billable")
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
            .navigationTitle(existingSession != nil ? "Edit Session" : "Log Hours")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityLabel(existingSession != nil ? "Save changes" : "Save hours")
                }
            }
        }
    }

    private func save() {
        guard !client.isEmpty, computedHours > 0 else { return }
        Task {
            if let session = existingSession {
                await tallyStore.updateSession(
                    session,
                    client: client,
                    hours: computedHours,
                    date: selectedDate,
                    taskNote: taskNote.isEmpty ? nil : taskNote,
                    isBillable: isBillable
                )
            } else {
                await tallyStore.addSession(
                    client: client,
                    hours: computedHours,
                    taskNote: taskNote.isEmpty ? nil : taskNote,
                    date: selectedDate,
                    isManual: true,
                    isBillable: isBillable
                )
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            dismiss()
        }
    }
}
