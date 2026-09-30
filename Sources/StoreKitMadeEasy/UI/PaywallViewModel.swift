import Foundation
import SwiftUI
import Combine

/// A ready-to-use ViewModel for SwiftUI Paywall screens.
@MainActor
public final class PaywallViewModel: ObservableObject {
    
    @Published public var selectedProduct: IAPProduct?
    @Published public var isPurchasing: Bool = false
    @Published public var errorMessage: String?
    @Published public var purchaseSuccess: Bool = false

    private let store: StoreKitMadeEasy
    private var cancellables = Set<AnyCancellable>()

    public convenience init() {
        self.init(store: .shared)
    }

    public init(store: StoreKitMadeEasy) {
        self.store = store
        
        // Auto-select the first product or annual product when available
        store.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                guard let self = self, self.selectedProduct == nil else { return }
                // Default to yearly if available, otherwise first
                self.selectedProduct = products.first(where: { $0.periodUnit == "year" }) ?? products.first
            }
            .store(in: &cancellables)
    }

    /// Available products from StoreFlow.
    public var products: [IAPProduct] {
        store.products
    }

    /// Selects a specific product.
    public func select(_ product: IAPProduct) {
        self.selectedProduct = product
    }

    /// Purchases currently selected product.
    public func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await store.purchase(product)
            isPurchasing = false
            switch result {
            case .success:
                purchaseSuccess = true
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Your purchase is pending authorization."
            }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
        }
    }

    /// Restores previous purchases.
    public func restore() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await store.restorePurchases()
            isPurchasing = false
            if store.hasAnyActiveSubscription {
                purchaseSuccess = true
            } else {
                errorMessage = "No active subscription found to restore."
            }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
        }
    }
}
