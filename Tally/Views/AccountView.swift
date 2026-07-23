//
//  AccountView.swift
//  Tally
//

import SwiftUI
import Supabase

struct AccountView: View {
    @Environment(TallyStore.self) var tallyStore
    @State private var userEmail: String = ""
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    private let purchases = PurchaseManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userEmail.isEmpty ? "Loading..." : userEmail)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(userEmail.isEmpty ? .secondary : .primary)
                            tierBadge
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(userEmail.isEmpty ? "Account loading" : "\(userEmail), \(tierLabel) plan")
                }

                Section("Subscription") {
                    HStack {
                        Label("Current Plan", systemImage: "crown.fill")
                        Spacer()
                        Text(tierLabel)
                            .foregroundStyle(.secondary)
                    }

                    if purchases.currentTier < .business {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade Plan", systemImage: "arrow.up.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            try? await supabase.auth.signOut()
                            NotificationCenter.default.post(name: .supabaseAuthStateChanged, object: nil)
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Account")
            .task { await loadEmail() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await tallyStore.deleteAccount()
                            NotificationCenter.default.post(name: .supabaseAuthStateChanged, object: nil)
                        } catch {
                            ErrorHandler.shared.handle(error, context: "Deleting account")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
        }
    }

    private var tierLabel: String {
        switch purchases.currentTier {
        case .free:     return "Free"
        case .pro:      return "Pro"
        case .business: return "Business"
        }
    }

    private var tierBadge: some View {
        Text(tierLabel)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(tierColor.opacity(0.15))
            .foregroundStyle(tierColor)
            .clipShape(Capsule())
    }

    private var tierColor: Color {
        switch purchases.currentTier {
        case .free:     return .secondary
        case .pro:      return .blue
        case .business: return .purple
        }
    }

    private func loadEmail() async {
        userEmail = (try? await supabase.auth.user())?.email ?? ""
    }
}
