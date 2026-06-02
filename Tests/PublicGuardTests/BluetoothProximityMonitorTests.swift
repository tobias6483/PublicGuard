import XCTest
@testable import PublicGuard

final class BluetoothProximityMonitorTests: XCTestCase {
    func testTargetStartsWithArmedBaselineUnseen() {
        let monitor = BluetoothProximityMonitor(lostAfterSeconds: 15)

        monitor.configureTarget(identifier: targetID.uuidString, name: "Phone")

        let snapshot = monitor.snapshot()
        XCTAssertEqual(snapshot.learnedDevice?.identifier, targetID)
        XCTAssertFalse(snapshot.hasSeenTarget)
        XCTAssertFalse(snapshot.hasReportedCurrentLoss)
        XCTAssertNil(snapshot.lastSeenTargetAt)
    }

    func testOutOfRangeRequiresTargetSeenAfterBaseline() {
        let monitor = BluetoothProximityMonitor(lostAfterSeconds: 15)
        let now = Date()

        monitor.configureTarget(identifier: targetID.uuidString, name: "Phone")

        XCTAssertNil(monitor.reportOutOfRangeTargetIfNeeded(at: now.addingTimeInterval(20)))
    }

    func testOutOfRangeReportsOnceUntilTargetIsSeenAgain() {
        let monitor = BluetoothProximityMonitor(lostAfterSeconds: 15)
        let now = Date()

        monitor.configureTarget(identifier: targetID.uuidString, name: "Phone")
        monitor.recordTargetAdvertisement(at: now)

        XCTAssertNil(monitor.reportOutOfRangeTargetIfNeeded(at: now.addingTimeInterval(14)))
        XCTAssertEqual(monitor.reportOutOfRangeTargetIfNeeded(at: now.addingTimeInterval(15))?.identifier, targetID)
        XCTAssertNil(monitor.reportOutOfRangeTargetIfNeeded(at: now.addingTimeInterval(30)))

        monitor.recordTargetAdvertisement(at: now.addingTimeInterval(31))
        XCTAssertEqual(monitor.reportOutOfRangeTargetIfNeeded(at: now.addingTimeInterval(46))?.identifier, targetID)
    }

    func testLearningReturnsStrongestCandidateAfterWindow() {
        let monitor = BluetoothProximityMonitor(lostAfterSeconds: 15, learnDurationSeconds: 3)
        let now = Date()
        let weakDevice = LearnedBluetoothDevice(identifier: UUID(), name: "Weak")
        let strongDevice = LearnedBluetoothDevice(identifier: UUID(), name: "Strong")

        monitor.beginLearning(at: now)
        monitor.recordLearningCandidate(weakDevice, rssi: -80)
        monitor.recordLearningCandidate(strongDevice, rssi: -40)

        XCTAssertNil(monitor.finishLearningIfNeeded(at: now.addingTimeInterval(2)))
        XCTAssertEqual(monitor.finishLearningIfNeeded(at: now.addingTimeInterval(3)), strongDevice)
        XCTAssertNil(monitor.finishLearningIfNeeded(at: now.addingTimeInterval(4)))
    }

    private var targetID: UUID {
        UUID(uuidString: "C07F4E70-7A07-4032-8C77-8EB75490D620")!
    }
}
