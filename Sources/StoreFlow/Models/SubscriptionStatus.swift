import Foundation
import StoreKit

/// Represents the status of an auto-renewable subscription.
public enum SubscriptionStatus: String, Sendable, Codable, Equatable {
    /// Active regular subscription.
    case active
    /// Active under introductory offer or free trial.
    case inTrial
    /// Subscription failed renewal, but is within Apple's billing grace period (access is still granted).
    case inGracePeriod
    /// Subscription renewal failed, and Apple is actively attempting to collect payment.
    case inBillingRetry
    /// Subscription expired and has not renewed.
    case expired
    /// Subscription was revoked by Apple (e.g. refunded or cancelled by customer support).
    case revoked
    /// Non-subscription or no purchase recorded.
    case none
}
