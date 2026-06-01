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

    func testRecentEntriesReturnsNewestEventsWithinLimit() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url)

        log.write(.appStarted)
        log.write(.armed)
        log.write(.chargerDisconnected)

        let entries = log.recentEntries(limit: 2)

        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries[0].contains("armed"))
        XCTAssertTrue(entries[1].contains("charger_disconnected"))
    }

    func testRecentEntriesReturnsEmptyListWhenLogDoesNotExist() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url)

        XCTAssertEqual(log.recentEntries(), [])
    }

    func testRecentEntriesReturnsEmptyListForNonPositiveLimit() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url)

        log.write(.armed)

        XCTAssertEqual(log.recentEntries(limit: 0), [])
    }

    func testAlarmTriggeredMessageContainsReason() {
        let message = GuardEvent.alarmTriggered(reason: "Power adapter disconnected").message

        XCTAssertEqual(message, "alarm_triggered reason=\"Power adapter disconnected\"")
    }

    func testAlarmStoppedMessage() {
        XCTAssertEqual(GuardEvent.alarmStopped.message, "alarm_stopped")
    }

    func testNetworkChangedMessageContainsSSIDValues() {
        let message = GuardEvent.networkChanged(previous: "Cafe WiFi", current: nil).message

        XCTAssertEqual(message, "network_changed previous=\"Cafe WiFi\" current=\"none\"")
    }

    func testBluetoothDeviceLearnedMessageContainsValues() {
        let message = GuardEvent.bluetoothDeviceLearned(name: "Tobias iPhone").message

        XCTAssertEqual(message, "bluetooth_device_learned name=\"Tobias iPhone\"")
    }

    func testBluetoothDeviceOutOfRangeMessageContainsName() {
        let message = GuardEvent.bluetoothDeviceOutOfRange(name: "Tobias iPhone").message

        XCTAssertEqual(message, "bluetooth_device_out_of_range name=\"Tobias iPhone\"")
    }

    func testSettingsChangedMessageContainsValues() {
        let message = GuardEvent.settingsChanged(
            gracePeriodSeconds: 10,
            responseMode: .silent,
            alarmSound: .ping,
            alarmVolume: .maximum,
            lockScreenEnabled: false
        ).message

        XCTAssertEqual(message, "settings_changed grace_period_seconds=10 response_mode=\"silent\" alarm_sound=\"ping\" alarm_volume=\"maximum\" lock_screen_enabled=false")
    }

    func testTriggerIgnoredMessageContainsName() {
        let message = GuardEvent.triggerIgnored(name: "networkChange").message

        XCTAssertEqual(message, "trigger_ignored name=\"networkChange\"")
    }

    func testLogClearedMessage() {
        XCTAssertEqual(GuardEvent.logCleared.message, "log_cleared")
    }
}
