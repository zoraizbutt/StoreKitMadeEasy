# StoreFlow 🛒

[![Swift](https://img.shields.io/badge/Swift-5.9%20%7C%206.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015+%20%7C%20macOS%2012+%20%7C%20watchOS%208+%20%7C%20tvOS%2015+-blue.svg)](https://developer.apple.com/storekit/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-red.svg)](https://cocoapods.org)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

**StoreFlow** is an elegant, lightweight, production-ready In-App Purchase framework for iOS, macOS, watchOS, and tvOS built entirely on Apple's modern **StoreKit 2**.

StoreFlow eliminates the boilerplate of StoreKit 2 while giving you full control: automatic background transaction loops, cryptographic JWS receipt verification, free trial & intro offer eligibility checking, native refund & subscription management sheets, and offline SwiftUI preview mocking.

---

## ✨ Features

- **StoreKit 2 Native:** Pure Swift, built from the ground up for modern Apple platforms (iOS 15.0+).
- **Swift 6 & Concurrency Ready:** Built with strict concurrency safety (`actor`, `@MainActor`, `Sendable`).
- **Complete Purchase Lifecycle:**
  - Auto-Renewable Subscriptions (with upgrade/downgrade handling)
  - Non-Consumable (Lifetime access)
  - Consumable (Coins, credits)
  - Non-Renewing Subscriptions
- **Automatic Transaction Listener:** Background stream (`Transaction.updates`) ensures renewals, family shares, and outside-the-app purchases are never missed.
- **Trial & Intro Offer Intelligence:** Check free trial eligibility (`product.isEligibleForIntroOffer`) and display localized trial terms ("3 days free trial").
- **Subscription Lifecycle States:** Track `.active`, `.inTrial`, `.inGracePeriod`, `.inBillingRetry`, and `.expired`.
- **Native Apple System Sheets:**
  - In-app Refund Request (`Transaction.beginRefundRequest`)
  - In-app Manage Subscriptions (`AppStore.showManageSubscriptions`)
  - Offer Code redemption sheet (`SKPaymentQueue.presentCodeRedemptionSheet`)
- **SwiftUI Ready:** Includes `PaywallViewModel`, view modifiers, and `MockStoreFlow` for interactive Xcode Previews without internet.
- **Xcode `.storekit` Configuration Bundled:** Instant offline sandbox testing with 1-second renewals and simulated failures.

---

## 📦 Installation

### Swift Package Manager (Recommended)

#### Via Xcode:
1. In Xcode, select **File > Add Package Dependencies...**
2. Enter your repository URL: `https://github.com/YOUR_USERNAME/StoreFlow.git`
3. Select **Up to Next Major Version** with `1.0.0`.

#### Via `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/StoreFlow.git", from: "1.0.0")
]
```

### CocoaPods

Add to your `Podfile`:
```ruby
pod 'StoreFlow', '~> 1.0.0'
```
Then run:
```bash
pod install
```

---

## 🚀 Quickstart

### 1. Initialize on App Launch
In your SwiftUI App or `AppDelegate`:

```swift
import SwiftUI
import StoreFlow

@main
struct MyApp: App {
    init() {
        StoreFlow.shared.start(productIDs: [
            "com.app.monthly",
            "com.app.yearly",
            "com.app.lifetime"
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Check Entitlements Anywhere

```swift
// Check specific product entitlement
if StoreFlow.shared.hasActiveEntitlement("com.app.yearly") {
    // Premium unlocked!
}

// Or check if user has ANY active subscription
if StoreFlow.shared.hasAnyActiveSubscription {
    // Show premium features
}
```

### 3. Purchasing a Product

```swift
do {
    let result = try await StoreFlow.shared.purchase(id: "com.app.yearly")
    switch result {
    case .success(let transaction, let entitlement):
        print("Purchased successfully: \(transaction.productID)")
    case .userCancelled:
        print("User cancelled the prompt.")
    case .pending:
        print("Waiting for parental / banking approval.")
    }
} catch {
    print("Purchase failed: \(error.localizedDescription)")
}
```

### 4. Restoring Purchases

```swift
do {
    try await StoreFlow.shared.restorePurchases()
    print("Restored successfully!")
} catch {
    print("Restore failed: \(error.localizedDescription)")
}
```

---

## 🎨 SwiftUI Drop-in Paywall Example

StoreFlow provides `PaywallViewModel` to power your paywalls in minutes:

```swift
import SwiftUI
import StoreFlow

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Unlock Pro Access")
                .font(.largeTitle.bold())

            // Product selection list
            ForEach(viewModel.products) { product in
                Button {
                    viewModel.select(product)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.displayName)
                                .font(.headline)
                            if let trial = product.freeTrialDescription, product.isEligibleForIntroOffer {
                                Text(trial)
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                        Spacer()
                        Text(product.displayPrice)
                            .font(.headline)
                    }
                    .padding()
                    .background(viewModel.selectedProduct?.id == product.id ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            // Purchase Button
            Button {
                Task {
                    await viewModel.purchaseSelected()
                    if viewModel.purchaseSuccess {
                        dismiss()
                    }
                }
            } label: {
                Text(viewModel.isPurchasing ? "Processing..." : "Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(viewModel.isPurchasing)

            // Restore Purchases
            Button("Restore Purchases") {
                Task { await viewModel.restore() }
            }
            .font(.footnote)
        }
        .padding()
    }
}
```

---

## 🧪 Testing Free Trials, Sandbox & StoreKit

StoreFlow includes a pre-configured `Products.storekit` file located in `Configuration/Products.storekit`.

### A. Testing Locally in Xcode (No Internet / App Store Account Needed)
1. In Xcode, select **Product > Scheme > Edit Scheme...**
2. Select **Run** on the left menu, then choose the **Options** tab.
3. Set **StoreKit Configuration** to `Products.storekit`.
4. In Xcode's debug area, use **Debug > StoreKit > Manage Transactions** to:
   - Speed up subscription renewals (e.g. 1 month = 1 minute).
   - Test free trial expiration and renewal.
   - Simulate card declines, billing retries, and refunds.

### B. Testing Sandbox on a Real Device
1. In App Store Connect, create a **Sandbox Tester** account (**Users and Access > Sandbox > Testers**).
2. On your iPhone, go to **Settings > App Store > Sandbox Account** and sign in.
3. Build and run your app with real Product IDs configured.

### C. SwiftUI Previews with `MockStoreFlow`
```swift
#Preview {
    PaywallView()
        // Use MockStoreFlow.sampleProducts for offline canvas rendering
}
```

---

## 🛠️ Native Apple Sheets

```swift
// Present Apple's native Manage Subscriptions sheet
try await StoreFlow.shared.showManageSubscriptions()

// Present Apple's native Refund Request sheet
try await StoreFlow.shared.beginRefundRequest(for: transactionID)

// Present Offer Code redemption sheet
StoreFlow.shared.presentOfferCodeRedemptionSheet()
```

---

## 🚢 Publishing to GitHub

To publish this library to your public GitHub account:

```bash
# 1. Initialize git and commit
cd StoreFlow
git init
git add .
git commit -m "feat: initial release of StoreFlow 1.0.0"

# 2. Add your GitHub remote repository
git remote add origin https://github.com/YOUR_USERNAME/StoreFlow.git
git branch -M main
git push -u origin main

# 3. Create a Release tag for SPM and CocoaPods
git tag 1.0.0
git push origin 1.0.0
```

### To publish on CocoaPods Trunk:
```bash
pod trunk push StoreFlow.podspec
```

---

## 📄 License
StoreFlow is released under the **MIT License**. See [LICENSE](LICENSE) for details.
