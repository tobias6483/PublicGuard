import XCTest
@testable import PublicGuard

@MainActor
final class SleepWakeMonitorTests: XCTestCase {
    func testSnapshotTracksMatchedSleepWakeGap() {
        let monitor = SleepWakeMonitor()
        let sleepAt = Date(timeIntervalSince1970: 100)
        let wakeAt = Date(timeIntervalSince1970: 145)

        monitor.recordWillSleep(at: sleepAt)
        let sleptSeconds = monitor.recordDidWake(at: wakeAt)
        let snapshot = monitor.snapshot()

        XCTAssertEqual(sleptSeconds, 45)
        XCTAssertEqual(snapshot.lastWillSleepAt, sleepAt)
        XCTAssertEqual(snapshot.lastDidWakeAt, wakeAt)
        XCTAssertEqual(snapshot.lastSleepDurationSeconds, 45)
        XCTAssertEqual(snapshot.observedSleepCount, 1)
        XCTAssertEqual(snapshot.observedWakeCount, 1)
    }

    func testWakeWithoutSleepRecordsUnknownGap() {
        let monitor = SleepWakeMonitor()

        let sleptSeconds = monitor.recordDidWake(at: Date(timeIntervalSince1970: 100))
        let snapshot = monitor.snapshot()

        XCTAssertNil(sleptSeconds)
        XCTAssertNil(snapshot.lastSleepDurationSeconds)
        XCTAssertEqual(snapshot.observedSleepCount, 0)
        XCTAssertEqual(snapshot.observedWakeCount, 1)
    }
}
