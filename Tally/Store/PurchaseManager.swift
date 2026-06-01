//
//  PurchaseManager.swift
//  Tally
//

import StoreKit
import Foundation

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
    static let businessID = "name.GeorgeClinkscales.Tally.business.monthly"

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

    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
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

    // MARK: - Feature Gates

    func canAddClient(existingCount: Int) -> Bool {
        currentTier >= .pro || existingCount < 1
    }

    var canExportCSV: Bool      { currentTier >= .pro }
    var hasFullHistory: Bool    { currentTier >= .pro }
    var canInvoice: Bool        { currentTier >= .business }
    var hasTeamWorkspaces: Bool { currentTier >= .business }

    func applyHistoryLimit(to sessions: [SessionModel]) -> [SessionModel] {
        guard currentTier == .free else { return sessions }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.startTime >= cutoff }
    }

    // MARK: - Private

    private func loadProducts() async {
        products = (try? await Product.products(for: [Self.proID, Self.businessID])) ?? []
        products.sort { $0.price < $1.price }
    }

    private func checkEntitlements() async {
        var hasBusiness = false
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if let tx = try? verified(result) {
                if tx.revocationDate != nil { continue }
                switch tx.productID {
                case Self.businessID: hasBusiness = true
                case Self.proID:      hasPro = true
                default: break
                }
            }
        }
        currentTier = hasBusiness ? .business : hasPro ? .pro : .free
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

