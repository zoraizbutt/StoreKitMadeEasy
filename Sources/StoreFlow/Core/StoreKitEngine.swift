import Foundation
import StoreKit

/// Actor responsible for all low-level StoreKit 2 operations, transaction updates, and cryptographic verification.
public actor StoreKitEngine {
    
    // MARK: - Properties
    private var transactionListenerTask: Task<Void, Never>?
    private var cachedNativeProducts: [String: Product] = [:]
    private(set) var currentEntitlements: [String: Entitlement] = [:]
    
    /// Callback triggered whenever entitlements change (e.g., from background renewals or purchases).
    private var onEntitlementsChanged: (@Sendable ([String: Entitlement]) -> Void)?

    // MARK: - Lifecycle
    public init() {}

    deinit {
        transactionListenerTask?.cancel()
    }

    /// Configures the callback invoked on entitlement updates.
    public func setEntitlementChangeHandler(_ handler: @escaping @Sendable ([String: Entitlement]) -> Void) {
        self.onEntitlementsChanged = handler
    }

    /// Starts listening to `Transaction.updates` stream to handle out-of-band purchases, background renewals, and revocations.
    public func startTransactionListener() {
        guard transactionListenerTask == nil else { return }

        transactionListenerTask = Task.detached(priority: .background) { [weak self] in
            for await verificationResult in Transaction.updates {
                guard let self = self else { break }
                do {
                    let transaction = try await self.verify(verificationResult)
                    await self.handleVerifiedTransaction(transaction)
                    await transaction.finish()
                } catch {
                    // Log or handle verification failure
                    print("[StoreFlow] Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Product Fetching
    /// Fetches products from App Store catalog for specified identifiers.
    public func fetchProducts(for ids: Set<String>) async throws -> [IAPProduct] {
        do {
            let products = try await Product.products(for: ids)
            var mapped: [IAPProduct] = []

            for product in products {
                cachedNativeProducts[product.id] = product
                
                var isEligible = false
                if let subscription = product.subscription {
                    isEligible = await subscription.isEligibleForIntroOffer
                }
                
                mapped.append(IAPProduct(product: product, isEligibleForIntroOffer: isEligible))
            }

            return mapped
        } catch {
            throw IAPError.networkError
        }
    }

    // MARK: - Purchasing
    /// Purchases a product using StoreKit 2.
    public func purchase(
        _ product: Product,
        options: Set<Product.PurchaseOption> = []
    ) async throws -> PurchaseResult {
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase(options: options)
        } catch {
            throw IAPError.purchaseFailed(underlyingMessage: error.localizedDescription)
        }

        switch result {
        case .success(let verificationResult):
            let transaction = try verify(verificationResult)
            let entitlement = await handleVerifiedTransaction(transaction)
            await transaction.finish()
            return .success(transaction: transaction, entitlement: entitlement)

        case .userCancelled:
            return .userCancelled

        case .pending:
            return .pending

        @unknown default:
            throw IAPError.unknown(message: "Unknown purchase result state.")
        }
    }

    // MARK: - Entitlements & Subscription Status
    /// Updates and returns the current verified entitlements from StoreKit 2.
    @discardableResult
    public func refreshEntitlements() async -> [String: Entitlement] {
        var newEntitlements: [String: Entitlement] = [:]

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            var status: SubscriptionStatus = .active
            if let nativeProduct = cachedNativeProducts[transaction.productID],
               let subInfo = nativeProduct.subscription {
                if let statuses = try? await subInfo.status, let primary = statuses.first {
                    status = mapSubscriptionStatus(primary.state)
                }
            }

            let entitlement = Entitlement(transaction: transaction, subscriptionStatus: status)
            if entitlement.isActive {
                newEntitlements[entitlement.id] = entitlement
            }
        }

        self.currentEntitlements = newEntitlements
        onEntitlementsChanged?(newEntitlements)
        return newEntitlements
    }

    /// Restores purchases by synchronizing with App Store servers.
    public func restorePurchases() async throws -> [String: Entitlement] {
        do {
            try await AppStore.sync()
            return await refreshEntitlements()
        } catch {
            throw IAPError.restoreFailed(underlyingMessage: error.localizedDescription)
        }
    }

    // MARK: - Helper Methods
    @discardableResult
    private func handleVerifiedTransaction(_ transaction: Transaction) async -> Entitlement {
        let entitlement = Entitlement(transaction: transaction, subscriptionStatus: .active)
        if entitlement.isActive {
            currentEntitlements[entitlement.id] = entitlement
        } else {
            currentEntitlements.removeValue(forKey: entitlement.id)
        }
        onEntitlementsChanged?(currentEntitlements)
        return entitlement
    }

    public func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let verificationError):
            throw IAPError.verificationFailed(reason: verificationError.localizedDescription)
        case .verified(let safe):
            return safe
        }
    }

    private func mapSubscriptionStatus(_ state: Product.SubscriptionInfo.RenewalState) -> SubscriptionStatus {
        switch state {
        case .subscribed:
            return .active
        case .inGracePeriod:
            return .inGracePeriod
        case .inBillingRetryPeriod:
            return .inBillingRetry
        case .expired:
            return .expired
        case .revoked:
            return .revoked
        default:
            return .active
        }
    }
}
