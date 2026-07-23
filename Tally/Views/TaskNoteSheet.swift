//
//  TaskNoteSheet.swift
//  Tally
//

import SwiftUI

struct TaskNoteSheet: View {
    let client: String
    @Binding var hours: Double
    @Binding var noteText: String
    let onSkip: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }

    private var roundedTo15: Double {
        (hours * 4).rounded() / 4
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
                .background(Capsule().fill(Color(.secondarySystemBackground)))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Session complete: \(client), \(TimeFormatter.accessibleFormat(hours))")

                if abs(roundedTo15 - hours) > 0.001 {
                    Button("Round to \(TimeFormatter.shortFormat(roundedTo15))") {
                        hours = roundedTo15
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .accessibilityHint("Rounds session duration to the nearest 15 minutes")
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
                    .fill(Color(.secondarySystemBackground))

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

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                }
                .accessibilityHint("Saves session without adding a note")

                Button(action: onSave) {
                    Text("Save Note")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(noteText.isEmpty ? Color.blue.opacity(0.5) : Color.blue))
                }
                .accessibilityHint(noteText.isEmpty ? "Saves session without a note" : "Saves your note with this session")
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onAppear { isFocused = true }
    }
}
