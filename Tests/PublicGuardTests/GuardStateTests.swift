import XCTest
@testable import PublicGuard

@MainActor
final class GuardStateTests: XCTestCase {
    func testArmEnablesGuardAndClearsAlarm() {
        let state = GuardState()

        state.markAlarmActive()
        state.arm()

        XCTAssertTrue(state.isArmed)
        XCTAssertFalse(state.isAlarmActive)
    }

    func testDisarmClearsGuardAndAlarm() {
        let state = GuardState()

        state.arm()
        state.markAlarmActive()
        state.disarm()

        XCTAssertFalse(state.isArmed)
        XCTAssertFalse(state.isAlarmActive)
    }
}
