import Foundation
import StoreKit

/// Result returned from a purchase operation.
public enum PurchaseResult: Sendable {
    /// Purchase completed successfully and the transaction was verified.
    case success(transaction: Transaction, entitlement: Entitlement)
    
    /// User explicitly cancelled the purchase sheet.
    case userCancelled
    
    /// Purchase is pending external authorization (e.g. Ask to Buy or Strong Customer Authentication).
    case pending
}
