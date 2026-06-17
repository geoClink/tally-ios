//
//  TaskNoteSheet.swift
//  Tally
//

import SwiftUI

struct TaskNoteSheet: View {
    let client: String
    let hours: Double
    @Binding var noteText: String
    let onSkip: () -> Void
    let onSave: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)

            // Session summary pill
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(client)
                    .fontWeight(.medium)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(TimeFormatter.shortFormat(hours))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
            .padding(.bottom, 20)

            // Title
            VStack(spacing: 4) {
                Text("What did you work on?")
                    .font(.title3.bold())
                Text("Optional — helps you remember later")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)

            // Text area
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))

                if noteText.isEmpty {
                    Text("e.g. Built login screen, fixed API bug...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
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

                Button(action: onSave) {
                    Text("Save Note")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(noteText.isEmpty ? Color.blue.opacity(0.5) : Color.blue))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onAppear { isFocused = true }
    }
}
