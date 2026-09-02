//
//  ClientPickerView.swift
//  Tally
//
//  Created by George Clinkscales on 5/28/26.
//

import SwiftUI
import TipKit

struct ClientPickerView: View {
    @Binding var selectedClient: String
    var recentClients: [String]
    var onStart: () -> Void

    @State private var customClient: String = ""
    @FocusState private var isCustomFocused: Bool
    @State private var showPaywall = false
    private let purchases = PurchaseManager.shared
    private let clientLimitTip = ClientLimitTip()

    private var isNewClient: Bool {
        let name = customClient.isEmpty ? selectedClient : customClient
        return !recentClients.contains(name)
    }

    private var blockedByFreeLimit: Bool {
        isNewClient && !purchases.canAddClient(existingCount: recentClients.count)
    }

    private var canStart: Bool {
        (!selectedClient.isEmpty || !customClient.isEmpty) && !blockedByFreeLimit
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Who are you working for?")
                .padding(.top, 8)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                if !recentClients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        ForEach(recentClients, id: \.self) { client in
                            Button {
                                selectedClient = client
                                customClient = ""
                                isCustomFocused = false
                            } label: {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(selectedClient == client ? .blue : .secondary)
                                        .frame(width: 20)
                                    Text(client)
                                        .foregroundStyle(.primary)
                                        .fontWeight(selectedClient == client ? .medium : .regular)
                                    Spacer()
                                    if selectedClient == client {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedClient == client ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedClient == client ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(client)
                            .accessibilityHint(selectedClient == client ? "Selected" : "Tap to select \(client)")
                            .accessibilityAddTraits(selectedClient == client ? .isSelected : [])
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("New client")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    if recentClients.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(["Personal", "General"], id: \.self) { suggestion in
                                Button {
                                    customClient = suggestion
                                    selectedClient = suggestion
                                    isCustomFocused = false
                                } label: {
                                    Text(suggestion)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    TextField("Type a client name...", text: $customClient)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .focused($isCustomFocused)
                        .accessibilityLabel("New client name")
                        .onSubmit {
                            if !customClient.isEmpty { selectedClient = customClient }
                        }
                        .onChange(of: customClient) {
                            if !customClient.isEmpty { selectedClient = customClient }
                        }
                }
            }

            Spacer()

            if blockedByFreeLimit {
                Button { showPaywall = true } label: {
                    Label("Upgrade for More Clients", systemImage: "lock.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple))
                }
                .popoverTip(clientLimitTip)
            } else {
                Button {
                    onStart()
                } label: {
                    Label("Start Tally", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(canStart ? Color.green : Color.gray.opacity(0.4))
                        )
                }
                .disabled(!canStart)
                .accessibilityLabel("Start Tally")
                .accessibilityHint(canStart ? "Starts timer for \(selectedClient)" : "Select or type a client name first")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}
