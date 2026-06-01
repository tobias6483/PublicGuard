import XCTest
@testable import PublicGuard

final class EventLogTests: XCTestCase {
    func testWriteAppendsEvents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url)

        log.write(.armed)
        log.write(.chargerDisconnected)

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("armed"))
        XCTAssertTrue(contents.contains("charger_disconnected"))
    }

    func testClearRemovesExistingEvents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url)

        log.write(.armed)
        log.clear()

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(contents, "")
    }

    func testAlarmTriggeredMessageContainsReason() {
        let message = GuardEvent.alarmTriggered(reason: "Power adapter disconnected").message

        XCTAssertEqual(message, "alarm_triggered reason=\"Power adapter disconnected\"")
    }

    func testNetworkChangedMessageContainsSSIDValues() {
        let message = GuardEvent.networkChanged(previous: "Cafe WiFi", current: nil).message

        XCTAssertEqual(message, "network_changed previous=\"Cafe WiFi\" current=\"none\"")
    }

    func testSettingsChangedMessageContainsValues() {
        let message = GuardEvent.settingsChanged(gracePeriodSeconds: 10, responseMode: .silent).message

        XCTAssertEqual(message, "settings_changed grace_period_seconds=10 response_mode=\"silent\"")
    }

    func testTriggerIgnoredMessageContainsName() {
        let message = GuardEvent.triggerIgnored(name: "networkChange").message

        XCTAssertEqual(message, "trigger_ignored name=\"networkChange\"")
    }

    func testLogClearedMessage() {
        XCTAssertEqual(GuardEvent.logCleared.message, "log_cleared")
    }
}
