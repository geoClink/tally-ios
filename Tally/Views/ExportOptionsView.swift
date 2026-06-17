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
    @Environment(\.dismiss) private var dismiss

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
                            }
                        }
                    }
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
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
