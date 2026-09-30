# StoreKitMadeEasy 🛒

[![Swift](https://img.shields.io/badge/Swift-5.9%20%7C%206.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2015+%20%7C%20macOS%2012+%20%7C%20watchOS%208+%20%7C%20tvOS%2015+-blue.svg)](https://developer.apple.com/storekit/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-compatible-red.svg)](https://cocoapods.org)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

**StoreKitMadeEasy** is a modern, lightweight, production-grade In-App Purchase and Subscription framework for Apple platforms (iOS, macOS, watchOS, tvOS) built from the ground up on Apple's **StoreKit 2**.

It eliminates the tedious boilerplate of StoreKit 2 while giving you complete reliability: automatic background transaction loops, cryptographic JWS receipt verification, real-time free trial & introductory offer eligibility checking, native refund & subscription management sheets, and offline SwiftUI preview mocking.

---

## 🌟 Why StoreKitMadeEasy?

Implementing StoreKit 2 correctly requires handling several complex workflows:
1. **Background Transaction Streams:** Listening continuously to `Transaction.updates` so renewals, family shares, and parental approvals ("Ask to Buy") are never dropped.
2. **Cryptographic JWS Verification:** Verifying that transactions are signed by Apple without relying on third-party servers.
3. **Introductory Offers & Free Trials:** Accurately detecting if a user has already consumed their free trial or introductory discount.
4. **Subscription Lifecycle States:** Differentiating between active subscribers, users in billing retry, users in Apple's grace period, and revoked purchases.
5. **System Sheet Integrations:** Invoking Apple's native refund request sheets and manage subscriptions windows.

**StoreKitMadeEasy bundles all of this into a clean, modern Swift API.**

---

## 📦 Installation

### Swift Package Manager (Recommended)

#### Option 1: Via Xcode UI
1. In Xcode, navigate to **File > Add Package Dependencies...**
2. In the search bar, paste:
   ```text
   https://github.com/zoraizbutt/StoreKitMadeEasy.git
   ```
3. Set the Dependency Rule to **Up to Next Major Version** starting at `1.0.0`.
4. Click **Add Package**.

#### Option 2: Via `Package.swift`
Add `StoreKitMadeEasy` to your `Package.swift` dependencies:
```swift
dependencies: [
    .package(url: "https://github.com/zoraizbutt/StoreKitMadeEasy.git", from: "1.0.0")
]
```

### CocoaPods

Add the pod to your `Podfile`:
```ruby
pod 'StoreKitMadeEasy', '~> 1.0.0'
```

Then install:
```bash
pod install
```

---

## 🚀 Quickstart Guide

### 1. Initialize at App Launch

Start `StoreKitMadeEasy` as early as possible in your app lifecycle (e.g. in your SwiftUI `@main App` or UIKit `AppDelegate`). This immediately spins up the background transaction listener:

```swift
import SwiftUI
import StoreKitMadeEasy

@main
struct MyApp: App {
    init() {
        // Configure your product IDs and start background listeners
        StoreKitMadeEasy.shared.start(productIDs: [
            "com.app.monthly",
            "com.app.yearly",
            "com.app.lifetime",
            "com.app.coins100"
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

### 2. Check Entitlements Anywhere

No async calls needed to check access—entitlements are tracked in real-time in an observable `@Published` dictionary:

```swift
import StoreKitMadeEasy

// Check if a specific feature or product is unlocked
if StoreKitMadeEasy.shared.hasActiveEntitlement("com.app.yearly") {
    // Grant Pro feature access
}

// Or check if user has ANY active subscription
if StoreKitMadeEasy.shared.hasAnyActiveSubscription {
    // Grant subscription benefits
}
```

---

### 3. Purchasing a Product

Purchasing handles transaction execution, cryptographic JWS verification, entitlement unlocking, and calling `transaction.finish()` automatically:

```swift
do {
    let result = try await StoreKitMadeEasy.shared.purchase(id: "com.app.yearly")
    
    switch result {
    case .success(let transaction, let entitlement):
        print("Purchased successfully: \(transaction.productID)")
        print("Active until: \(String(describing: entitlement.expirationDate))")
        
    case .userCancelled:
        print("User dismissed purchase sheet.")
        
    case .pending:
        print("Transaction is pending (e.g., Ask to Buy parental approval or 3D Secure bank authorization).")
    }
} catch {
    print("Purchase failed with error: \(error.localizedDescription)")
}
```

---

### 4. Restoring Purchases

StoreKit 2 automatically restores purchases on app launch. However, Apple App Store Review Guidelines require a visible **"Restore Purchases"** button for users:

```swift
do {
    try await StoreKitMadeEasy.shared.restorePurchases()
    print("Purchases restored successfully!")
} catch {
    print("Failed to restore purchases: \(error.localizedDescription)")
}
```

---

### 5. Native Apple System Sheets

StoreKitMadeEasy includes native sheet presentation helpers:

```swift
// 1. Present Apple's native Manage Subscriptions sheet
try await StoreKitMadeEasy.shared.showManageSubscriptions()

// 2. Present Apple's native Refund Request sheet
try await StoreKitMadeEasy.shared.beginRefundRequest(for: transactionID)

// 3. Present Offer Code redemption sheet (iOS)
StoreKitMadeEasy.shared.presentOfferCodeRedemptionSheet()
```

Or use the provided SwiftUI view modifiers:
```swift
struct SettingsView: View {
    @State private var showManageSubscriptions = false
    @State private var showOfferCodeSheet = false

    var body: some View {
        List {
            Button("Manage Subscriptions") { showManageSubscriptions = true }
            Button("Redeem Code") { showOfferCodeSheet = true }
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .offerCodeRedemptionSheet(isPresented: $showOfferCodeSheet)
    }
}
```

---

## 🎨 Complete SwiftUI Drop-in Paywall

StoreKitMadeEasy includes a pre-built `PaywallViewModel` that binds directly to the store and handles loading, product selection, trial badges, and purchase states:

```swift
import SwiftUI
import StoreKitMadeEasy

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Unlock Premium")
                    .font(.largeTitle.bold())
                Text("Get unlimited access to all features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)

            // Product Cards
            VStack(spacing: 12) {
                ForEach(viewModel.products) { product in
                    Button {
                        viewModel.select(product)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName)
                                    .font(.headline)
                                
                                // Free trial badge (only displayed if user is eligible!)
                                if let trial = product.freeTrialDescription, product.isEligibleForIntroOffer {
                                    Text(trial)
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(product.displayPrice)
                                    .font(.headline)
                                if let period = product.periodDescription {
                                    Text("per \(period)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedProduct?.id == product.id ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Error display
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
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
                HStack {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isPurchasing)
            .padding(.horizontal)

            // Restore & Terms
            HStack(spacing: 16) {
                Button("Restore Purchases") {
                    Task { await viewModel.restore() }
                }
                Text("•")
                Button("Terms of Service") {}
                Text("•")
                Button("Privacy Policy") {}
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom)
        }
    }
}
```

---

## 🧪 Testing with StoreKit 2 & Sandbox

StoreKitMadeEasy comes with a bundled Xcode StoreKit configuration file located in:
[`Configuration/Products.storekit`](Configuration/Products.storekit)

### 1. Local Testing in Xcode (No Internet / App Store Connect Required)
1. In Xcode, go to **Product > Scheme > Edit Scheme...**
2. In the left panel, select **Run**, then open the **Options** tab.
3. Under **StoreKit Configuration**, select `Products.storekit`.
4. Run your app in the simulator.
5. In Xcode's debug area, use **Debug > StoreKit > Manage Transactions** to:
   - Speed up subscription renewals (e.g. 1 month renewing every 30 seconds).
   - Test free trial expiration and conversion to paid.
   - Simulate card declines, billing retries, and refunds.
   - Simulate **Ask to Buy** parental approval workflows.

### 2. Testing on Real Devices with App Store Sandbox
1. Go to [App Store Connect](https://appstoreconnect.apple.com) > **Users and Access** > **Sandbox Testers**.
2. Create a new sandbox tester account.
3. On your physical iPhone / iPad, go to **Settings > App Store > Sandbox Account** and sign in.
4. Run your app in Debug mode with your real App Store product IDs.

### 3. SwiftUI Previews with `MockStoreKitMadeEasy`
Preview your paywalls without making any network calls:

```swift
#Preview {
    PaywallView()
    // Powered by MockStoreKitMadeEasy with simulated trial periods
}
```

---

## 🏗️ Architecture & Subscription Statuses

StoreKitMadeEasy categorizes subscription states accurately:

| State | Description | Access Granted? |
|---|---|---|
| `.active` | Normal active subscription | ✅ Yes |
| `.inTrial` | User is within free trial period | ✅ Yes |
| `.inGracePeriod` | Billing failed, but within Apple's Grace Period | ✅ Yes |
| `.inBillingRetry` | Billing failed, Apple is retrying payment | ❌ No |
| `.expired` | Subscription ended and was not renewed | ❌ No |
| `.revoked` | Apple refunded or revoked access | ❌ No |

---

## 🤝 Contributing & Feedback

Contributions, issues, and feature requests are welcome!
Feel free to open an issue or submit a pull request on [GitHub](https://github.com/zoraizbutt/StoreKitMadeEasy).

---

## 📄 License

StoreKitMadeEasy is available under the **MIT License**. See the [LICENSE](LICENSE) file for more info.
