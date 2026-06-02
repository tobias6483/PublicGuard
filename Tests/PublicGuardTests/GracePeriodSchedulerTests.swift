import XCTest
@testable import PublicGuard

@MainActor
final class GracePeriodSchedulerTests: XCTestCase {
    func testScheduleRejectsReplacementWhileGracePeriodIsPending() {
        let scheduler = GracePeriodScheduler()
        var fired: [String] = []

        XCTAssertTrue(scheduler.schedule(after: .seconds(60)) {
            fired.append("first")
        })
        XCTAssertFalse(scheduler.schedule(after: .seconds(0)) {
            fired.append("second")
        })

        XCTAssertTrue(scheduler.hasPendingGracePeriod)
        XCTAssertEqual(fired, [])
        scheduler.cancel()
    }

    func testCancelAllowsNewGracePeriod() async throws {
        let scheduler = GracePeriodScheduler()
        var didFire = false

        XCTAssertTrue(scheduler.schedule(after: .seconds(60)) {})
        scheduler.cancel()

        XCTAssertTrue(scheduler.schedule(after: .milliseconds(1)) {
            didFire = true
        })

        try await Task.sleep(for: .milliseconds(20))

        XCTAssertTrue(didFire)
        XCTAssertFalse(scheduler.hasPendingGracePeriod)
    }
}
