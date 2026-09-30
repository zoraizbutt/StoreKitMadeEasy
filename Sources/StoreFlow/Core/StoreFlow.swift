import Foundation
import StoreKit
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// Main entry point for In-App Purchase operations with StoreFlow.
/// Designed for SwiftUI and UIKit apps using Swift Concurrency.
@MainActor
public final class StoreFlow: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = StoreFlow()
    
    // MARK: - Published Properties
    /// Fetched products with localized pricing and trial availability.
    @Published public private(set) var products: [IAPProduct] = []
    
    /// Map of active entitlements keyed by product identifier.
    @Published public private(set) var activeEntitlements: [String: Entitlement] = [:]
    
    /// Indicates whether a network or purchase operation is actively in progress.
    @Published public private(set) var isLoading: Bool = false
    
    /// Holds the most recent error, if any.
    @Published public private(set) var lastError: IAPError? = nil
    
    // MARK: - Private Properties
    private let engine: StoreKitEngine
    private var configuredProductIDs: Set<String> = []

    // MARK: - Initialization
    public init(engine: StoreKitEngine = StoreKitEngine()) {
        self.engine = engine
        setupEngineListener()
    }

    private func setupEngineListener() {
        Task { [weak self] in
            await self?.engine.setEntitlementChangeHandler { [weak self] entitlements in
                Task { @MainActor [weak self] in
                    self?.activeEntitlements = entitlements
                }
            }
        }
    }

    // MARK: - Configuration
    /// Initializes StoreFlow, starts background transaction observation, and refreshes current entitlements.
    /// Call this in `App.init()`, `didFinishLaunchingWithOptions`, or early in the app lifecycle.
    public func start(productIDs: Set<String> = []) {
        self.configuredProductIDs = productIDs
        
        Task {
            await engine.startTransactionListener()
            await refreshEntitlements()
            if !productIDs.isEmpty {
                _ = try? await fetchProducts(for: productIDs)
            }
        }
    }

    // MARK: - Catalog
    /// Fetches products from App Store catalog. If `ids` is nil, fetches previously configured IDs.
    @discardableResult
    public func fetchProducts(for ids: Set<String>? = nil) async throws -> [IAPProduct] {
        let targetIDs = ids ?? configuredProductIDs
        guard !targetIDs.isEmpty else { return [] }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await engine.fetchProducts(for: targetIDs)
            self.products = fetched
            return fetched
        } catch let error as IAPError {
            self.lastError = error
            throw error
        } catch {
            let wrapped = IAPError.unknown(message: error.localizedDescription)
            self.lastError = wrapped
            throw wrapped
        }
    }

    // MARK: - Purchase
    /// Purchases the given `IAPProduct`.
    @discardableResult
    public func purchase(_ product: IAPProduct) async throws -> PurchaseResult {
        guard let native = product.underlyingProduct else {
            throw IAPError.productNotFound(id: product.id)
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await engine.purchase(native)
            if case .success(_, let entitlement) = result {
                activeEntitlements[entitlement.id] = entitlement
            }
            return result
        } catch let error as IAPError {
            self.lastError = error
            throw error
        } catch {
            let wrapped = IAPError.unknown(message: error.localizedDescription)
            self.lastError = wrapped
            throw wrapped
        }
    }

    /// Convenience purchase by product identifier.
    @discardableResult
    public func purchase(id: String) async throws -> PurchaseResult {
        guard let found = products.first(where: { $0.id == id }) else {
            throw IAPError.productNotFound(id: id)
        }
        return try await purchase(found)
    }

    // MARK: - Entitlements & Status
    /// Check whether a specific product identifier is currently unlocked and active.
    public func hasActiveEntitlement(_ productID: String) -> Bool {
        guard let entitlement = activeEntitlements[productID] else { return false }
        return entitlement.isActive
    }

    /// Check if user has any active auto-renewable or non-renewing subscription.
    public var hasAnyActiveSubscription: Bool {
        activeEntitlements.values.contains { $0.isActive && $0.expirationDate != nil }
    }

    /// Refresh active entitlements directly from StoreKit 2.
    @discardableResult
    public func refreshEntitlements() async -> [String: Entitlement] {
        let refreshed = await engine.refreshEntitlements()
        self.activeEntitlements = refreshed
        return refreshed
    }

    /// Restores purchases by prompting user to authenticate and syncing StoreKit transactions.
    public func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let refreshed = try await engine.restorePurchases()
            self.activeEntitlements = refreshed
        } catch let error as IAPError {
            self.lastError = error
            throw error
        } catch {
            let wrapped = IAPError.restoreFailed(underlyingMessage: error.localizedDescription)
            self.lastError = wrapped
            throw wrapped
        }
    }

    // MARK: - System Sheets & Prompts
    #if os(iOS) || targetEnvironment(macCatalyst)
    /// Presents Apple's native Manage Subscriptions sheet.
    @MainActor
    public func showManageSubscriptions(in scene: UIWindowScene? = nil) async throws {
        let targetScene: UIWindowScene
        if let scene = scene {
            targetScene = scene
        } else if let keyWindow = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            targetScene = keyWindow
        } else {
            throw IAPError.unknown(message: "No active UIWindowScene found.")
        }
        try await AppStore.showManageSubscriptions(in: targetScene)
    }

    /// Begins a native Apple refund request sheet for a transaction.
    @MainActor
    public func beginRefundRequest(for transactionID: UInt64, in scene: UIWindowScene? = nil) async throws {
        let targetScene: UIWindowScene
        if let scene = scene {
            targetScene = scene
        } else if let keyWindow = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            targetScene = keyWindow
        } else {
            throw IAPError.unknown(message: "No active UIWindowScene found.")
        }

        let status = try await Transaction.beginRefundRequest(for: transactionID, in: targetScene)
        switch status {
        case .userCancelled:
            throw IAPError.userCancelled
        case .success:
            // Sync after refund submission
            _ = try? await restorePurchases()
        @unknown default:
            break
        }
    }

    /// Presents Apple's native Offer Code redemption sheet.
    @MainActor
    public func presentOfferCodeRedemptionSheet() {
        SKPaymentQueue.default().presentCodeRedemptionSheet()
    }
    #endif
}
