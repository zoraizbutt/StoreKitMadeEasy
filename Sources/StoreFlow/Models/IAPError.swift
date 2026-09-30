import Foundation
import StoreKit

/// Errors that can occur during In-App Purchase operations in StoreFlow.
public enum IAPError: LocalizedError, Sendable, Equatable {
    case productNotFound(id: String)
    case purchaseFailed(underlyingMessage: String)
    case verificationFailed(reason: String)
    case userCancelled
    case pendingApproval
    case networkError
    case restoreFailed(underlyingMessage: String)
    case refundRequestFailed(underlyingMessage: String)
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .productNotFound(let id):
            return "The product with ID '\(id)' could not be found in the App Store catalog."
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .verificationFailed(let reason):
            return "StoreKit transaction verification failed: \(reason)"
        case .userCancelled:
            return "The purchase was cancelled by the user."
        case .pendingApproval:
            return "The transaction is pending approval (e.g., Ask to Buy or banking verification)."
        case .networkError:
            return "A network error occurred while connecting to the App Store."
        case .restoreFailed(let message):
            return "Failed to restore previous purchases: \(message)"
        case .refundRequestFailed(let message):
            return "Failed to initiate refund request: \(message)"
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}
