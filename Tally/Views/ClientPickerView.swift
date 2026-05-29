//
//  ClientPickerView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI

struct ClientPickerView: View {
    @Binding var selectedClient: String
    var recentClients: [String]
    var onStart: () -> Void
    
    @State private var customClient: String = ""
    @FocusState private var isCustomFocused: Bool
    
    private var canStart: Bool {
        !selectedClient.isEmpty || !customClient.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Who are you working on?")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                
                if !recentClients.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(recentClients, id: \.self) { client in
                            Button {
                                selectedClient = client
                                customClient = ""
                            } label: {
                                HStack {
                                    Text(client)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedClient == client {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedClient == client ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                                )
                            }
                            .accessibilityLabel(client)
                            .accessibilityHint(selectedClient == client ? "Selected" : "Tap to select \(client)")
                            .accessibilityAddTraits(selectedClient == client ? .isSelected : [])
                        }
                    }
                }
                
                TextField("Or type a new client...", text: $customClient)
                    .textFieldStyle(.roundedBorder)
                    .focused($isCustomFocused)
                    .accessibilityLabel("New client name")
                    .accessibilityHint("Type a client name to start tracking")
                    .onSubmit {
                        if !customClient.isEmpty {
                            selectedClient = customClient
                        }
                    }
                    .onChange(of: customClient) {
                        if !customClient.isEmpty {
                            selectedClient = customClient
                        }
                    }
                
                Button {
                    onStart()
                } label: {
                    Text("Start Tally")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canStart ? Color.blue : Color.gray)
                        )
                }
                .disabled(!canStart)
                .accessibilityLabel("Start Tally")
                .accessibilityHint(canStart ? "Starts timer for \(selectedClient)" : "Select or type a client name first")
            }
            .padding()
        }
    }
}
