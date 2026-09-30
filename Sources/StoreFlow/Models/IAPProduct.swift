import Foundation
import StoreKit

/// A flexible, testable wrapper around Apple's StoreKit `Product`.
/// Can be initialized from a native `StoreKit.Product` or instantiated manually for SwiftUI previews and unit testing.
public struct IAPProduct: Identifiable, Sendable, Hashable {
    /// Unique App Store product identifier.
    public let id: String
    
    /// Localized display name (e.g., "Pro Yearly").
    public let displayName: String
    
    /// Localized description from App Store Connect.
    public let productDescription: String
    
    /// Localized formatted price string (e.g., "$29.99").
    public let displayPrice: String
    
    /// Raw decimal price.
    public let price: Decimal
    
    /// Product type (e.g., autoRenewable, nonConsumable, consumable).
    public let type: Product.ProductType
    
    /// Formatted period string (e.g., "year", "month", "week") if this is a subscription.
    public let periodUnit: String?
    
    /// Formatted period duration (e.g., "1 year", "3 months").
    public let periodDescription: String?
    
    /// Formatted price per period (e.g., "$2.49 / month" for yearly breakdown).
    public let formattedPricePerPeriod: String?
    
    /// Free trial duration string (e.g., "7 days free trial") if applicable.
    public let freeTrialDescription: String?
    
    /// Whether user is currently eligible for an introductory free trial or discount.
    public var isEligibleForIntroOffer: Bool
    
    /// Reference to the underlying native StoreKit 2 Product (nil in mock/preview mode).
    public let underlyingProduct: Product?

    // MARK: - Initializer from Native StoreKit.Product
    public init(product: Product, isEligibleForIntroOffer: Bool = false) {
        self.id = product.id
        self.displayName = product.displayName
        self.productDescription = product.description
        self.displayPrice = product.displayPrice
        self.price = product.price
        self.type = product.type
        self.underlyingProduct = product
        self.isEligibleForIntroOffer = isEligibleForIntroOffer

        if let subscription = product.subscription {
            let period = subscription.subscriptionPeriod
            let unitName: String
            switch period.unit {
            case .day: unitName = period.value == 1 ? "day" : "\(period.value) days"
            case .week: unitName = period.value == 1 ? "week" : "\(period.value) weeks"
            case .month: unitName = period.value == 1 ? "month" : "\(period.value) months"
            case .year: unitName = period.value == 1 ? "year" : "\(period.value) years"
            @unknown default: unitName = "period"
            }
            self.periodUnit = unitName
            self.periodDescription = period.value == 1 ? unitName : "\(period.value) \(unitName)"
            self.formattedPricePerPeriod = "\(product.displayPrice) / \(unitName)"

            if let intro = subscription.introductoryOffer, intro.paymentMode == .freeTrial {
                let introPeriod = intro.period
                let introUnit: String
                switch introPeriod.unit {
                case .day: introUnit = introPeriod.value == 1 ? "day" : "\(introPeriod.value) days"
                case .week: introUnit = introPeriod.value == 1 ? "week" : "\(introPeriod.value) weeks"
                case .month: introUnit = introPeriod.value == 1 ? "month" : "\(introPeriod.value) months"
                case .year: introUnit = introPeriod.value == 1 ? "year" : "\(introPeriod.value) years"
                @unknown default: introUnit = "period"
                }
                self.freeTrialDescription = "\(introUnit) free trial"
            } else {
                self.freeTrialDescription = nil
            }
        } else {
            self.periodUnit = nil
            self.periodDescription = nil
            self.formattedPricePerPeriod = nil
            self.freeTrialDescription = nil
        }
    }

    // MARK: - Mock Initializer (for Previews & Tests)
    public init(
        id: String,
        displayName: String,
        productDescription: String,
        displayPrice: String,
        price: Decimal,
        type: Product.ProductType = .autoRenewable,
        periodUnit: String? = nil,
        periodDescription: String? = nil,
        formattedPricePerPeriod: String? = nil,
        freeTrialDescription: String? = nil,
        isEligibleForIntroOffer: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.productDescription = productDescription
        self.displayPrice = displayPrice
        self.price = price
        self.type = type
        self.periodUnit = periodUnit
        self.periodDescription = periodDescription
        self.formattedPricePerPeriod = formattedPricePerPeriod
        self.freeTrialDescription = freeTrialDescription
        self.isEligibleForIntroOffer = isEligibleForIntroOffer
        self.underlyingProduct = nil
    }

    public static func == (lhs: IAPProduct, rhs: IAPProduct) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
