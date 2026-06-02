import XCTest
@testable import PublicGuard

@MainActor
final class GuardStateTests: XCTestCase {
    func testArmEnablesGuardWithoutClearingActiveAlarm() {
        let state = GuardState()

        state.markAlarmActive()
        state.arm()

        XCTAssertTrue(state.isArmed)
        XCTAssertTrue(state.isAlarmActive)
    }

    func testDisarmClearsGuardAndAlarm() {
        let state = GuardState()

        state.arm()
        state.markAlarmActive()
        state.disarm()

        XCTAssertFalse(state.isArmed)
        XCTAssertFalse(state.isAlarmActive)
    }

    func testMarkAlarmInactiveLeavesGuardArmed() {
        let state = GuardState()

        state.arm()
        state.markAlarmActive()
        state.markAlarmInactive()

        XCTAssertTrue(state.isArmed)
        XCTAssertFalse(state.isAlarmActive)
    }
}
