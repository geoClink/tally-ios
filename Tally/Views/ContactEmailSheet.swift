//
//  ContactEmailSheet.swift
//  Tally
//

import SwiftUI

struct ContactEmailSheet: View {
    let current: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var error: String = ""

    init(current: String, onSave: @escaping (String) -> Void) {
        self.current = current
        self.onSave = onSave
        _email = State(initialValue: current)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("your@email.com", text: $email)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        #endif
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } header: {
                    Text("Contact Email")
                } footer: {
                    Text("Used to send you updates and tips about Tally. Separate from your login email.")
                }

                if !error.isEmpty {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Contact Email")
            #if os(macOS)
            .formStyle(.grouped)
            #endif
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            error = "Please enter an email address."
            return
        }
        guard isValidEmail(trimmed) else {
            error = "Please enter a valid email address."
            return
        }
        onSave(trimmed)
        dismiss()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        return predicate.evaluate(with: email)
    }
}
