import Foundation
import StoreKit

/// Represents a verified active or historical user entitlement.
public struct Entitlement: Identifiable, Sendable, Equatable {
    /// The unique product identifier.
    public let id: String
    
    /// The original transaction ID associated with this entitlement.
    public let originalTransactionID: UInt64
    
    /// Whether the entitlement is currently active.
    public let isActive: Bool
    
    /// Expiration date for auto-renewable or non-renewing subscriptions, nil for lifetime/non-consumable.
    public let expirationDate: Date?
    
    /// Date when the product was originally purchased.
    public let purchaseDate: Date
    
    /// Whether this entitlement was unlocked via Apple Family Sharing.
    public let isFamilyShared: Bool
    
    /// Whether this entitlement is currently enjoying a free trial or introductory offer.
    public let isTrial: Bool
    
    /// Detailed status of the subscription.
    public let subscriptionStatus: SubscriptionStatus

    public init(
        id: String,
        originalTransactionID: UInt64,
        isActive: Bool,
        expirationDate: Date? = nil,
        purchaseDate: Date = Date(),
        isFamilyShared: Bool = false,
        isTrial: Bool = false,
        subscriptionStatus: SubscriptionStatus = .none
    ) {
        self.id = id
        self.originalTransactionID = originalTransactionID
        self.isActive = isActive
        self.expirationDate = expirationDate
        self.purchaseDate = purchaseDate
        self.isFamilyShared = isFamilyShared
        self.isTrial = isTrial
        self.subscriptionStatus = subscriptionStatus
    }

    /// Creates an Entitlement directly from a verified StoreKit 2 Transaction.
    public init(transaction: Transaction, subscriptionStatus: SubscriptionStatus = .active) {
        self.id = transaction.productID
        self.originalTransactionID = transaction.originalID
        
        let now = Date()
        let isExpired = transaction.expirationDate.map { $0 < now } ?? false
        let isRevoked = transaction.revocationDate != nil
        
        self.isActive = !isExpired && !isRevoked && !transaction.isUpgraded
        self.expirationDate = transaction.expirationDate
        self.purchaseDate = transaction.originalPurchaseDate
        self.isFamilyShared = (transaction.ownershipType == .familyShared)
        self.isTrial = (transaction.offerType == .introductory)
        
        if isRevoked {
            self.subscriptionStatus = .revoked
        } else if isExpired {
            self.subscriptionStatus = .expired
        } else if transaction.offerType == .introductory {
            self.subscriptionStatus = .inTrial
        } else {
            self.subscriptionStatus = subscriptionStatus
        }
    }
}
