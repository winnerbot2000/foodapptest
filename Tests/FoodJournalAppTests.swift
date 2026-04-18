import XCTest
@testable import FoodJournalApp

final class FoodJournalAppTests: XCTestCase {
    func testSampleDataProvidesSeedContent() {
        XCTAssertFalse(SampleData.restaurants().isEmpty)
        XCTAssertFalse(SampleData.dishes().isEmpty)
    }
}
