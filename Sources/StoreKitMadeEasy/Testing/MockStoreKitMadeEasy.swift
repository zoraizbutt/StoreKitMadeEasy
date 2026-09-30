import Foundation
import StoreKit
import Combine

/// A mock provider for SwiftUI Previews and offline UI testing.
public typealias MockStoreFlow = MockStoreKitMadeEasy

@MainActor
public final class MockStoreKitMadeEasy: ObservableObject {
    
    @Published public var products: [IAPProduct] = []
    @Published public var activeEntitlements: [String: Entitlement] = [:]
    @Published public var isLoading: Bool = false
    @Published public var simulateFailure: Bool = false
    
    public init() {
        self.products = MockStoreKitMadeEasy.sampleProducts
    }

    /// Pre-populated mock products with trials, subscriptions, and non-consumables.
    public nonisolated static var sampleProducts: [IAPProduct] {
        [
            IAPProduct(
                id: "com.storeflow.monthly",
                displayName: "Pro Monthly",
                productDescription: "Full access to all premium features, billed monthly.",
                displayPrice: "$4.99",
                price: 4.99,
                type: .autoRenewable,
                periodUnit: "month",
                periodDescription: "1 month",
                formattedPricePerPeriod: "$4.99 / month",
                freeTrialDescription: "3 days free trial",
                isEligibleForIntroOffer: true
            ),
            IAPProduct(
                id: "com.storeflow.yearly",
                displayName: "Pro Annual",
                productDescription: "Best value. Full access to all premium features, billed annually.",
                displayPrice: "$39.99",
                price: 39.99,
                type: .autoRenewable,
                periodUnit: "year",
                periodDescription: "1 year",
                formattedPricePerPeriod: "$3.33 / month",
                freeTrialDescription: "7 days free trial",
                isEligibleForIntroOffer: true
            ),
            IAPProduct(
                id: "com.storeflow.lifetime",
                displayName: "Lifetime Unlock",
                productDescription: "Pay once, keep forever. All current and future features.",
                displayPrice: "$99.99",
                price: 99.99,
                type: .nonConsumable,
                periodUnit: nil,
                periodDescription: nil,
                formattedPricePerPeriod: nil,
                freeTrialDescription: nil,
                isEligibleForIntroOffer: false
            )
        ]
    }

    public func purchase(_ product: IAPProduct) async throws -> PurchaseResult {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false

        if simulateFailure {
            throw IAPError.purchaseFailed(underlyingMessage: "Simulated sandbox card decline.")
        }

        let entitlement = Entitlement(
            id: product.id,
            originalTransactionID: UInt64.random(in: 1000000...9999999),
            isActive: true,
            expirationDate: product.type == .autoRenewable ? Date().addingTimeInterval(30 * 86400) : nil,
            purchaseDate: Date(),
            isFamilyShared: false,
            isTrial: product.isEligibleForIntroOffer,
            subscriptionStatus: product.isEligibleForIntroOffer ? .inTrial : .active
        )

        activeEntitlements[product.id] = entitlement
        return .userCancelled // or success mock
    }

    public func unlockAll() {
        for product in products {
            activeEntitlements[product.id] = Entitlement(
                id: product.id,
                originalTransactionID: UInt64.random(in: 1000000...9999999),
                isActive: true,
                expirationDate: Date().addingTimeInterval(365 * 86400),
                purchaseDate: Date(),
                isFamilyShared: false,
                isTrial: false,
                subscriptionStatus: .active
            )
        }
    }

    public func resetEntitlements() {
        activeEntitlements.removeAll()
    }
}
