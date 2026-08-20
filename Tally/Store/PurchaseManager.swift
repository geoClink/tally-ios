//
//  PurchaseManager.swift
//  Tally
//

import StoreKit
import Foundation
import Supabase

enum Tier: Int, Comparable {
    case free = 0
    case pro = 1
    case business = 2
    static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum StoreError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Purchase verification failed." }
}

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    static let proID      = "name.GeorgeClinkscales.Tally.pro"
    static let businessID = "name.GeorgeClinkscales.Tally.businessmonthly"

    private(set) var currentTier: Tier = .free
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    private(set) var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await refresh() }
    }

    // MARK: - Public API

    func refresh() async {
        await loadProducts()
        await checkEntitlements()
    }

    var proProduct: Product?      { products.first { $0.id == Self.proID } }
    var businessProduct: Product? { products.first { $0.id == Self.businessID } }

    var businessIntroOffer: Product.SubscriptionOffer? {
        businessProduct?.subscription?.introductoryOffer
    }

    func isEligibleForBusinessTrial() async -> Bool {
        await businessProduct?.subscription?.isEligibleForIntroOffer ?? false
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                // Update tier immediately so the UI dismisses without waiting on Supabase sync
                switch transaction.productID {
                case Self.businessID: currentTier = max(currentTier, .business)
                case Self.proID:      currentTier = max(currentTier, .pro)
                default: break
                }
                await checkEntitlements()
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    // MARK: - Feature Gates

    func canAddClient(existingCount: Int) -> Bool {
        currentTier >= .pro || existingCount < 5
    }

    var canExportCSV: Bool        { currentTier >= .pro }
    var hasFullHistory: Bool      { currentTier >= .pro }
    var hasWatchAndWidgets: Bool  { currentTier >= .pro }
    var canInvoice: Bool          { currentTier >= .business }
    var hasTeamWorkspaces: Bool   { currentTier >= .business }

    func applyHistoryLimit(to sessions: [SessionModel]) -> [SessionModel] {
        guard currentTier == .free else { return sessions }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime >= cutoff }
    }

    // MARK: - Private

    private func loadProducts() async {
        // Retry up to 3 times — sandbox StoreKit can be flaky
        for attempt in 1...3 {
            do {
                products = try await Product.products(for: [Self.proID, Self.businessID])
                products.sort { $0.price < $1.price }
                return
            } catch {
                if attempt == 3 {
                    products = []
                } else {
                    try? await Task.sleep(for: .seconds(1))
                }
            }
        }
    }

    private var businessExpirationDate: Date?

    private func checkEntitlements() async {
        var storeKitTier: Tier = .free
        var expirationDate: Date?
        for await result in Transaction.currentEntitlements {
            if let tx = try? verified(result) {
                if tx.revocationDate != nil { continue }
                switch tx.productID {
                case Self.businessID:
                    storeKitTier = .business
                    expirationDate = tx.expirationDate
                case Self.proID:
                    if storeKitTier < .pro { storeKitTier = .pro }
                default: break
                }
            }
        }
        businessExpirationDate = expirationDate

        let stripeTier = await fetchStripeTier()
        currentTier = max(storeKitTier, stripeTier)
        await syncSubscriptionToSupabase()
    }

    private func fetchStripeTier() async -> Tier {
        guard let user = try? await supabase.auth.user() else {
            return .free
        }
        do {
            let rows: [SubscriptionRow] = try await supabase
                .from("subscriptions")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .eq("source", value: "stripe")
                .execute()
                .value

            var best: Tier = .free
            for row in rows {
                if let expires = row.expiresAt, expires < Date() { continue }
                let tier: Tier = switch row.tier {
                    case "business" : .business
                    case "pro"      : .pro
                    default         : .free
                }
                if tier > best { best = tier }
            }
            return best
        } catch {
            return .free
        }
    }

    private func syncSubscriptionToSupabase() async {
        guard let user = try? await supabase.auth.user() else { return }

        let tierString: String
        switch currentTier {
        case .free: tierString = "free"
        case .pro: tierString = "pro"
        case .business: tierString = "business"
        }

        do {
            let existing: [SubscriptionRow] = try await supabase
                .from("subscriptions")
                .select()
                .eq("user_id", value: user.id.uuidString)
                .eq("source", value: "ios")
                .execute()
                .value

            if let row = existing.first {
                let update = SubscriptionUpdate(
                    tier: tierString,
                    expiresAt: businessExpirationDate
                )
                try await supabase
                    .from("subscriptions")
                    .update(update)
                    .eq("id", value: row.id.uuidString)
                    .execute()
            } else if currentTier != .free {
                let insert = SubscriptionInsert(
                    userId: user.id.uuidString,
                    tier: tierString,
                    source: "ios",
                    expiresAt: businessExpirationDate
                )
                try await supabase
                    .from("subscriptions")
                    .insert(insert)
                    .execute()
            }
        } catch {
            // Sync failure shouldn't block the purchase flow
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let tx = try? await self.verified(result) {
                    await self.checkEntitlements()
                    await tx.finish()
                }
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let val): return val
        }
    }
}

// MARK: - Subscription Sync Models

struct SubscriptionRow: Codable, Identifiable {
    let id: UUID
    let userId: String
    let tier: String
    let source: String
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tier
        case source
        case expiresAt = "expires_at"
    }
}

struct SubscriptionInsert: Codable {
    let userId: String
    let tier: String
    let source: String
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier
        case source
        case expiresAt = "expires_at"
    }
}

struct SubscriptionUpdate: Codable {
    let tier: String
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case tier
        case expiresAt = "expires_at"
    }
}

