import SwiftUI
import StoreKit

#if os(iOS) || targetEnvironment(macCatalyst)
public struct ManageSubscriptionsModifier: ViewModifier {
    @Binding var isPresented: Bool

    public func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { shouldShow in
                if shouldShow {
                    Task { @MainActor in
                        try? await StoreFlow.shared.showManageSubscriptions()
                        isPresented = false
                    }
                }
            }
    }
}

public struct OfferCodeRedemptionModifier: ViewModifier {
    @Binding var isPresented: Bool

    public func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { shouldShow in
                if shouldShow {
                    StoreFlow.shared.presentOfferCodeRedemptionSheet()
                    isPresented = false
                }
            }
    }
}

public extension View {
    /// Triggers Apple's native Manage Subscriptions sheet when binding evaluates to true.
    func manageSubscriptionsSheet(isPresented: Binding<Bool>) -> some View {
        modifier(ManageSubscriptionsModifier(isPresented: isPresented))
    }

    /// Triggers Apple's native Offer Code redemption sheet when binding evaluates to true.
    func offerCodeRedemptionSheet(isPresented: Binding<Bool>) -> some View {
        modifier(OfferCodeRedemptionModifier(isPresented: isPresented))
    }
}
#endif
