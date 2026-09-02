//
//  PaywallView.swift
//  Tally
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var purchases = PurchaseManager.shared
    @State private var showError = false
    @State private var isEligibleForTrial = false

    private var captionColor: Color {
        colorScheme == .dark ? .secondary : Color(white: 0.40)
    }

    private var businessPriceLabel: String {
        guard let product = purchases.businessProduct else { return "$4.99/month" }
        if purchases.businessIntroOffer?.paymentMode == .freeTrial {
            return "7 days free, then \(product.displayPrice)/month"
        }
        return product.displayPrice + "/month"
    }

    private var businessPurchaseLabel: String {
        isEligibleForTrial && purchases.businessIntroOffer?.paymentMode == .freeTrial
            ? "Start Free Trial"
            : "Get Tally Business"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.20))
                            .frame(width: geo.size.width * 0.85)
                            .blur(radius: 90)
                            .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.05)

                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: geo.size.width * 0.7)
                            .blur(radius: 75)
                            .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.55)
                    }
                }
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 90, height: 90)
                            Circle()
                                .stroke(Color.blue.opacity(0.25), lineWidth: 1.5)
                                .frame(width: 90, height: 90)
                            Image(systemName: "timer")
                                .font(.system(size: 38, weight: .light))
                                .foregroundStyle(.blue)
                        }
                        .accessibilityHidden(true)
                        Text("Upgrade Tally")
                            .font(.title.bold())
                        Text("Unlock your full potential")
                            .font(.subheadline)
                            .fontWeight(.semibold)
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
                                "5 clients",
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
                            Task {
                                if purchases.proProduct == nil {
                                    await purchases.refresh()
                                }
                                if let product = purchases.proProduct {
                                    await purchases.purchase(product)
                                } else {
                                    purchases.setError("Unable to load this product. Please check your connection and try again.")
                                }
                            }
                        }

                        TierCard(
                            name: "Tally Business",
                            price: businessPriceLabel,
                            color: .purple,
                            features: [
                                "Everything in Pro",
                                "Client invoicing via email",
                                "Team workspaces",
                                "Shared client tracking"
                            ],
                            isCurrent: purchases.currentTier == .business,
                            purchaseLabel: businessPurchaseLabel,
                            subscriptionFooter: AnyView(
                                VStack(spacing: 6) {
                                    Group {
                                        if purchases.businessIntroOffer?.paymentMode == .freeTrial {
                                            Text("Includes a 7-day free trial. After the trial, Tally Business is \(purchases.businessProduct?.displayPrice ?? "$4.99")/month, auto-renewing. Cancel anytime in App Store settings.")
                                        } else {
                                            Text("Tally Business is a 1-month auto-renewing subscription at \(purchases.businessProduct?.displayPrice ?? "$4.99")/month. Cancel anytime in App Store settings.")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(captionColor)
                                    .multilineTextAlignment(.center)
                                    HStack(spacing: 16) {
                                        Link("Privacy Policy", destination: URL(string: "https://tallytimetracker.com/privacy")!)
                                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    }
                                    .font(.caption)
                                }
                            )
                        ) {
                            Task {
                                if purchases.businessProduct == nil {
                                    await purchases.refresh()
                                }
                                if let product = purchases.businessProduct {
                                    await purchases.purchase(product)
                                } else {
                                    purchases.setError("Unable to load this product. Please check your connection and try again.")
                                }
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
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Link("Privacy Policy", destination: URL(string: "https://tallytimetracker.com/privacy")!)
                        Text("·").foregroundStyle(captionColor)
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .font(.caption2)
                    .foregroundStyle(captionColor)
                    .padding(.bottom)
                }
            }
            } // ZStack
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
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK") { purchases.clearError() }
            } message: {
                Text(purchases.errorMessage ?? "")
            }
            .onChange(of: purchases.errorMessage) { _, newValue in
                showError = newValue != nil
            }
            .task {
                if purchases.products.isEmpty {
                    await purchases.refresh()
                }
                isEligibleForTrial = await purchases.isEligibleForBusinessTrial()
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
    var purchaseLabel: String? = nil
    var subscriptionFooter: AnyView? = nil
    var onPurchase: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.headline)
                    Text(price).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                }
                Spacer()
                if isCurrent {
                    Text("Current")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.15), in: Capsule())
                        .foregroundStyle(color)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isCurrent ? "\(name), \(price). Current plan." : "\(name), \(price)")

            Divider()

            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .accessibilityLabel(feature)
            }

            if let onPurchase, !isCurrent {
                Button {
                    onPurchase()
                } label: {
                    Text(purchaseLabel ?? "Get \(name)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(color, in: RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityHint("Purchases \(name) plan")
                .padding(.top, 4)
            }

            if let footer = subscriptionFooter {
                footer
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

