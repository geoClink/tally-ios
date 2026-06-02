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

    @State private var goalHours: Double = 5.0
    @State private var clientGoalHours: [String: Double] = [:]

    private var warningHours: Int {
        Int(goalHours * 0.8)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Hour Goal") {
                    Stepper(
                        "\(Int(goalHours)) hours per week",
                        value: $goalHours,
                        in: 1...80,
                        step: 1
                    )
                    .accessibilityLabel("Weekly hour goal: \(Int(goalHours)) hours")
                    .accessibilityHint("Double tap and swipe up or down to adjust your weekly hour goal")

                    Slider(value: $goalHours, in: 1...80, step: 1)
                        .accessibilityLabel("Weekly goal slider")
                        .accessibilityValue("\(Int(goalHours)) hours per week")
                        .accessibilityHint("Slide to adjust your weekly hour goal between 1 and 80 hours")

                    Text("You'll get a warning at \(warningHours) hours (80%)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Warning threshold: \(warningHours) hours at 80 percent of goal")
                }

                if !tallyStore.recentClients.isEmpty {
                    Section("Per-Client Goals") {
                        ForEach(tallyStore.recentClients, id: \.self) { client in
                            HStack {
                                Text(client)
                                Spacer()
                                Stepper(
                                    "\(Int(clientGoalHours[client] ?? 0))h",
                                    value: Binding(
                                        get: { clientGoalHours[client] ?? 0 },
                                        set: { clientGoalHours[client] = $0 }
                                    ),
                                    in: 0...80,
                                    step: 1
                                )
                                .fixedSize()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(client) weekly goal: \(Int(clientGoalHours[client] ?? 0)) hours")
                        }

                        Text("Set to 0 to remove a client goal.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About Goals") {
                    Text("Tally tracks your total hours across all clients each week. Your goal resets every Monday.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Your weekly goal resets every Monday and tracks total hours across all clients")
                }
            }
            .navigationTitle("Weekly Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                        .accessibilityHint("Dismisses without saving changes")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await tallyStore.saveGoal(goalHours)
                            for (client, hours) in clientGoalHours {
                                await tallyStore.saveClientGoal(client: client, weeklyHours: hours)
                            }
                            dismiss()
                        }
                    }
                    .accessibilityLabel("Save goal")
                    .accessibilityHint("Saves \(Int(goalHours)) hours as your weekly goal")
                }
            }
            .onAppear {
                goalHours = tallyStore.weeklyGoal
                for goal in tallyStore.clientGoals {
                    clientGoalHours[goal.client] = goal.weeklyHours
                }
            }
        }
    }
}
