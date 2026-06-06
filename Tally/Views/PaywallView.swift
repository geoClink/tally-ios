//
//  PaywallView.swift
//  Tally
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchases = PurchaseManager.shared
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text("Upgrade Tally")
                            .font(.title.bold())
                        Text("Unlock your full potential")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Tier cards
                    VStack(spacing: 16) {
                        TierCard(
                            name: "Free",
                            price: "Current plan",
                            color: .gray,
                            features: [
                                "1 client",
                                "Basic timer",
                                "7-day history"
                            ],
                            isCurrent: purchases.currentTier == .free
                        )

                        TierCard(
                            name: "Tally Pro",
                            price: purchases.proProduct.map { $0.displayPrice + " one-time" } ?? "$9.99 one-time",
                            color: .blue,
                            features: [
                                "Unlimited clients",
                                "Full session history",
                                "CSV export",
                                "Apple Watch sync",
                                "Home screen widgets",
                                "Siri shortcuts"
                            ],
                            isCurrent: purchases.currentTier == .pro
                        ) {
                            if let product = purchases.proProduct {
                                Task { await purchases.purchase(product) }
                            } else {
                                purchases.setError("Unable to load this product. Please try again later.")
                            }
                        }

                        TierCard(
                            name: "Tally Business",
                            price: purchases.businessProduct.map { $0.displayPrice + "/month" } ?? "$4.99/month",
                            color: .purple,
                            features: [
                                "Everything in Pro",
                                "Stripe invoice payments",
                                "Team workspaces",
                                "Shared client tracking"
                            ],
                            isCurrent: purchases.currentTier == .business
                        ) {
                            if let product = purchases.businessProduct {
                                Task { await purchases.purchase(product) }
                            } else {
                                purchases.setError("Unable to load this product. Please try again later.")
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Restore
                    Button {
                        Task { await purchases.restore() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Subscription details
                    VStack(spacing: 4) {
                        if let business = purchases.businessProduct {
                            Text("Tally Business auto-renews at \(business.displayPrice)/month until cancelled.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        HStack(spacing: 12) {
                            Link("Privacy Policy", destination: URL(string: "https://geoclink.github.io/portfolio/tally/privacy.html")!)
                            Text("·").foregroundStyle(.secondary)
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdfma.html")!)
                        }
                        .font(.caption2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if purchases.isPurchasing {
                    ProgressView("Processing...")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("Purchase Error", isPresented: .constant(purchases.errorMessage != nil)) {
                Button("OK") { purchases.clearError() }
            } message: {
                Text(purchases.errorMessage ?? "")
            }
            .onChange(of: purchases.currentTier) { _, tier in
                if tier > .free { dismiss() }
            }
        }
    }
}

private struct TierCard: View {
    let name: String
    let price: String
    let color: Color
    let features: [String]
    var isCurrent: Bool = false
    var onPurchase: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.headline)
                    Text(price).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if isCurrent {
                    Text("Current")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.15), in: Capsule())
                        .foregroundStyle(color)
                }
            }

            Divider()

            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            if let onPurchase, !isCurrent {
                Button {
                    onPurchase()
                } label: {
                    Text("Get \(name)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(color, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? color.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

