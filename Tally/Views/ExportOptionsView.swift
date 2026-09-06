//
//  ExportOptionsView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct ExportOptionsView: View {
    let clients: [String]
    let onExport: (ExportRange, String?) -> Void
    let onExportDates: (Date, Date, String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var customStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()
    @State private var customClient: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Export by time range") {
                    ForEach(ExportRange.allCases, id: \.self) { range in
                        Button {
                            onExport(range, nil)
                        } label: {
                            HStack {
                                Text(range.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.down.doc")
                                    .foregroundStyle(.blue)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Export \(range.rawValue)")
                        .accessibilityHint("Downloads a CSV file")
                    }
                }

                Section("Custom date range") {
                    DatePicker("From", selection: $customStart, in: ...customEnd, displayedComponents: .date)
                    DatePicker("To", selection: $customEnd, in: customStart..., displayedComponents: .date)
                    if !clients.isEmpty {
                        Picker("Client (optional)", selection: $customClient) {
                            Text("All clients").tag("")
                            ForEach(clients, id: \.self) { client in
                                Text(client).tag(client)
                            }
                        }
                    }
                    Button {
                        onExportDates(customStart, customEnd, customClient.isEmpty ? nil : customClient)
                    } label: {
                        HStack {
                            Text("Export Custom Range")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.down.doc")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("Export custom date range")
                    .accessibilityHint("Downloads a CSV file for the selected date range")
                }

                Section("Export by client") {
                    if clients.isEmpty {
                        Text("No clients yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(clients, id: \.self) { client in
                            Button {
                                onExport(.allTime, client)
                            } label: {
                                HStack {
                                    Text(client)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.down.doc")
                                        .foregroundStyle(.blue)
                                        .accessibilityHidden(true)
                                }
                            }
                            .accessibilityLabel("Export all time for \(client)")
                            .accessibilityHint("Downloads a CSV file")
                        }
                    }
                }
            }
            .navigationTitle("Export Hours")
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
            }
        }
        #if os(iOS)
        .presentationBackground(Color(uiColor: .systemGroupedBackground))
        #endif
    }
}
