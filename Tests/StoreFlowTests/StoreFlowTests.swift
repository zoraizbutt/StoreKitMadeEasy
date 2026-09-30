import XCTest
@testable import StoreFlow

final class StoreFlowTests: XCTestCase {

    func testMockProductCalculations() {
        let yearly = MockStoreFlow.sampleProducts.first(where: { $0.id == "com.storeflow.yearly" })
        XCTAssertNotNil(yearly)
        XCTAssertEqual(yearly?.displayName, "Pro Annual")
        XCTAssertEqual(yearly?.periodUnit, "year")
        XCTAssertEqual(yearly?.displayPrice, "$39.99")
        XCTAssertEqual(yearly?.freeTrialDescription, "7 days free trial")
        XCTAssertTrue(yearly?.isEligibleForIntroOffer == true)
    }

    func testEntitlementActiveStatus() {
        let activeEntitlement = Entitlement(
            id: "com.storeflow.yearly",
            originalTransactionID: 123456,
            isActive: true,
            expirationDate: Date().addingTimeInterval(3600),
            purchaseDate: Date(),
            isFamilyShared: true,
            isTrial: true,
            subscriptionStatus: .inTrial
        )

        XCTAssertTrue(activeEntitlement.isActive)
        XCTAssertTrue(activeEntitlement.isFamilyShared)
        XCTAssertTrue(activeEntitlement.isTrial)
        XCTAssertEqual(activeEntitlement.subscriptionStatus, .inTrial)
    }

    func testEntitlementExpiration() {
        let expiredDate = Date().addingTimeInterval(-3600)
        let expiredEntitlement = Entitlement(
            id: "com.storeflow.monthly",
            originalTransactionID: 789101,
            isActive: false,
            expirationDate: expiredDate,
            purchaseDate: Date().addingTimeInterval(-86400 * 30),
            subscriptionStatus: .expired
        )

        XCTAssertFalse(expiredEntitlement.isActive)
        XCTAssertEqual(expiredEntitlement.subscriptionStatus, .expired)
    }

    @MainActor
    func testMockStoreFlowUnlockAll() {
        let mockStore = MockStoreFlow()
        XCTAssertEqual(mockStore.activeEntitlements.count, 0)
        
        mockStore.unlockAll()
        XCTAssertEqual(mockStore.activeEntitlements.count, MockStoreFlow.sampleProducts.count)
        XCTAssertNotNil(mockStore.activeEntitlements["com.storeflow.lifetime"])
        XCTAssertTrue(mockStore.activeEntitlements["com.storeflow.lifetime"]?.isActive == true)

        mockStore.resetEntitlements()
        XCTAssertEqual(mockStore.activeEntitlements.count, 0)
    }

    func testIAPErrorDescriptions() {
        let notFound = IAPError.productNotFound(id: "invalid_id")
        XCTAssertTrue(notFound.errorDescription?.contains("invalid_id") == true)

        let cancelled = IAPError.userCancelled
        XCTAssertNotNil(cancelled.errorDescription)
    }
}
