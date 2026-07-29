//
//  GoalSettingsView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct GoalSettingView: View {
    @Environment(TallyStore.self) var tallyStore
    @Environment(\.dismiss) private var dismiss

    @State private var goalHours: Double = 40.0
    @State private var clientGoalHours: [String: Double] = [:]
    @State private var totalGoalEnabled = false

    private var warningHours: Int { Int(goalHours * 0.8) }

    var body: some View {
        NavigationStack {
            Form {
                let allClients = Array(Set(tallyStore.recentClients + tallyStore.clientGoals.map { $0.client })).sorted()
                if !allClients.isEmpty {
                    Section {
                        ForEach(allClients, id: \.self) { client in
                            clientGoalRow(client: client)
                        }
                        Text("Tap the number to type a value directly. Set to 0 to remove a goal.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Per-Client Goals")
                    }
                }

                Section {
                    Toggle("Enable total weekly goal", isOn: $totalGoalEnabled)

                    if totalGoalEnabled {
                        HStack {
                            Text("Hours per week")
                            Spacer()
                            hourField(value: $goalHours, range: 1...80)
                        }

                        Slider(value: $goalHours, in: 1...80, step: 1)
                            .accessibilityLabel("Weekly goal slider")

                        Text("You'll get a warning at \(warningHours) hours (80%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Total Weekly Goal")
                } footer: {
                    Text(totalGoalEnabled ? "" : "Useful if you have a total hours target across all clients.")
                }

                Section("About Goals") {
                    Text("Goals reset every Monday. Per-client goals show as progress bars on the home screen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await tallyStore.saveGoal(totalGoalEnabled ? goalHours : 0)
                            for (client, hours) in clientGoalHours {
                                await tallyStore.saveClientGoal(client: client, weeklyHours: hours)
                            }
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await tallyStore.loadConfig()
                await tallyStore.loadSessions()
                let saved = tallyStore.weeklyGoal
                totalGoalEnabled = saved > 0
                goalHours = saved > 0 ? saved : 40
                for goal in tallyStore.clientGoals {
                    clientGoalHours[goal.client] = goal.weeklyHours
                }
            }
        }
    }

    // MARK: - Subviews

    private func clientGoalRow(client: String) -> some View {
        HStack {
            Text(client)
            Spacer()
            hourField(
                value: Binding(
                    get: { clientGoalHours[client] ?? 0 },
                    set: { clientGoalHours[client] = $0 }
                ),
                range: 0...80
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(client) weekly goal: \(Int(clientGoalHours[client] ?? 0)) hours")
    }

    private func hourField(value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 2) {
            Button {
                value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(value.wrappedValue > range.lowerBound ? Color.secondary : Color.secondary.opacity(0.3))
                    .font(.title3)
            }
            .buttonStyle(.plain)

            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 46)
                .padding(.vertical, 4)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: value.wrappedValue) { _, newVal in
                    value.wrappedValue = min(range.upperBound, max(range.lowerBound, newVal))
                }

            Text("h")
                .foregroundStyle(.secondary)
                .frame(width: 14)

            Button {
                value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }
}
