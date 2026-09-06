//
//  TaskNoteSheet.swift
//  Tally
//

import SwiftUI

struct TaskNoteSheet: View {
    let client: String
    @Binding var hours: Double
    @Binding var noteText: String
    @Binding var isBillable: Bool
    let onSkip: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }

    private var roundingRule: RoundingRule { .current }

    private var roundedHours: Double {
        roundingRule.apply(to: hours)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .accessibilityHidden(true)

            // Session summary pill
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text(client)
                        .fontWeight(.medium)
                    Text("·")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(TimeFormatter.shortFormat(hours))
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.secondaryBackground))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Session complete: \(client), \(TimeFormatter.accessibleFormat(hours))")

                if roundingRule != .none, abs(roundedHours - hours) > 0.001 {
                    Button("Round to \(TimeFormatter.shortFormat(roundedHours))") {
                        hours = roundedHours
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .accessibilityHint("Rounds session duration to the nearest \(roundingRule.label)")
                }
            }
            .padding(.bottom, 20)

            // Title
            VStack(spacing: 4) {
                Text("What did you work on?")
                    .font(.title3.bold())
                Text("Optional — helps you remember later")
                    .font(.caption)
                    .foregroundStyle(captionColor)
            }
            .padding(.bottom, 20)
            .accessibilityElement(children: .combine)

            // Text area
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.secondaryBackground)

                if noteText.isEmpty {
                    Text("e.g. Built login screen, fixed API bug...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .accessibilityHidden(true)
                }

                TextEditor(text: $noteText)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 90)
                    .accessibilityLabel("Task note")
            }
            .frame(minHeight: 90)
            .padding(.horizontal)

            // Billable toggle
            HStack {
                Label(isBillable ? "Billable" : "Non-billable",
                      systemImage: isBillable ? "dollarsign.circle.fill" : "dollarsign.circle")
                    .font(.subheadline)
                    .foregroundStyle(isBillable ? .green : .secondary)
                Spacer()
                Toggle("", isOn: $isBillable)
                    .labelsHidden()
                    .tint(.green)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            // Actions
            #if os(macOS)
            HStack {
                Spacer()
                Button("Skip", action: onSkip)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityHint("Saves session without adding a note")
                Button("Save Note", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(noteText.isEmpty)
                    .accessibilityHint(noteText.isEmpty ? "Saves session without a note" : "Saves your note with this session")
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            #else
            HStack(spacing: 12) {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        #if !os(visionOS)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.secondaryBackground))
                        #endif
                }
                #if os(visionOS)
                .buttonStyle(.bordered)
                .controlSize(.large)
                #endif
                .accessibilityHint("Saves session without adding a note")

                Button(action: onSave) {
                    Text("Save Note")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        #if !os(visionOS)
                        .foregroundStyle(.white)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(noteText.isEmpty ? Color.blue.opacity(0.5) : Color.blue))
                        #endif
                }
                #if os(visionOS)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(noteText.isEmpty)
                #endif
                .accessibilityHint(noteText.isEmpty ? "Saves session without a note" : "Saves your note with this session")
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            #endif
        }
        .onAppear { }
        .interactiveDismissDisabled(true)
    }
}
