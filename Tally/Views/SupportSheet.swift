//
//  SupportSheet.swift
//  Tally
//

import SwiftUI
import Supabase

struct SupportSheet: View {
    let userEmail: String
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var isSending = false
    @State private var didSend = false
    @State private var errorMessage = ""

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private var iosVersion: String {
        #if os(iOS)
        return UIDevice.current.systemName + " " + UIDevice.current.systemVersion
        #else
        return "macOS"
        #endif
    }

    var body: some View {
        NavigationStack {
            Form {
                if didSend {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.green)
                            Text("Message Sent")
                                .font(.headline)
                            Text("Thanks for reaching out. I'll get back to you as soon as I can.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    Section(header: Text("Describe the problem you're experiencing and I'll look into it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                        .padding(.bottom, 4)
                    ) {
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                    }

                    if !errorMessage.isEmpty {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

                    Section {
                        Button {
                            Task { await sendReport() }
                        } label: {
                            if isSending {
                                HStack {
                                    ProgressView()
                                    Text("Sending…")
                                }
                            } else {
                                Text("Send Report")
                            }
                        }
                        .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                    }

                    Section("Sent automatically with your report") {
                        Label("App version: \(appVersion)", systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Label("iOS: \(iosVersion)", systemImage: "iphone")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Report a Problem")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func sendReport() async {
        isSending = true
        errorMessage = ""

        let userId = try? await supabase.auth.session.user.id.uuidString

        struct Payload: Encodable {
            let message: String
            let userEmail: String?
            let appVersion: String
            let iosVersion: String
            let userId: String?
        }

        let payload = Payload(
            message: message,
            userEmail: userEmail.isEmpty ? nil : userEmail,
            appVersion: appVersion,
            iosVersion: iosVersion,
            userId: userId
        )

        do {
            try await supabase.functions.invoke(
                "send-support-email",
                options: FunctionInvokeOptions(body: payload)
            )
            didSend = true
        } catch {
            errorMessage = "Failed to send. Please try again."
        }

        isSending = false
    }
}
