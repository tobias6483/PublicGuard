import XCTest
import CryptoKit
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

    func testEncryptedWriteDoesNotStorePlaintext() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url, keyProvider: StaticEventLogKeyProvider())

        log.write(.networkChanged(previous: "Cafe WiFi", current: "Library WiFi", kind: .ssidChanged), storage: .encrypted)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))

        let encryptedData = try Data(contentsOf: log.encryptedURL)
        let encryptedText = String(data: encryptedData, encoding: .utf8) ?? ""
        XCTAssertFalse(encryptedText.contains("Cafe WiFi"))
        XCTAssertFalse(encryptedText.contains("network_changed"))
    }

    func testEncryptedRecentEntriesDecryptNewestEventsWithinLimit() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url, keyProvider: StaticEventLogKeyProvider())

        log.write(.appStarted, storage: .encrypted)
        log.write(.armed, storage: .encrypted)
        log.write(.chargerDisconnected, storage: .encrypted)

        let entries = log.recentEntries(limit: 2, storage: .encrypted)

        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries[0].contains("armed"))
        XCTAssertTrue(entries[1].contains("charger_disconnected"))
    }

    func testEncryptedClearRemovesExistingEvents() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url, keyProvider: StaticEventLogKeyProvider())

        log.write(.armed, storage: .encrypted)
        log.clear(storage: .encrypted)

        XCTAssertEqual(log.recentEntries(storage: .encrypted), [])
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
        let message = GuardEvent.networkChanged(previous: "Cafe WiFi", current: nil, kind: .disconnected).message

        XCTAssertEqual(message, "network_changed kind=\"disconnected\" previous=\"Cafe WiFi\" current=\"none\"")
    }

    func testBluetoothDeviceLearnedMessageContainsValues() {
        let message = GuardEvent.bluetoothDeviceLearned(name: "Tobias iPhone").message

        XCTAssertEqual(message, "bluetooth_device_learned name=\"Tobias iPhone\"")
    }

    func testBluetoothDeviceOutOfRangeMessageContainsName() {
        let message = GuardEvent.bluetoothDeviceOutOfRange(name: "Tobias iPhone").message

        XCTAssertEqual(message, "bluetooth_device_out_of_range name=\"Tobias iPhone\"")
    }

    func testIdleTimeoutMessageContainsSeconds() {
        let message = GuardEvent.idleTimeout(seconds: 300).message

        XCTAssertEqual(message, "idle_timeout seconds=300")
    }

    func testSettingsChangedMessageContainsValues() {
        let message = GuardEvent.settingsChanged(
            gracePeriodSeconds: 10,
            idleTimeoutSeconds: 300,
            responseMode: .silent,
            alarmSound: .ping,
            alarmVolume: .maximum,
            lockScreenEnabled: false,
            launchAtLoginEnabled: true,
            eventLogDetail: .standard,
            eventLogStorage: .encrypted,
            bluetoothProximityTimeoutSeconds: 60,
            ignoreWiFiDisconnects: true,
            triggerCooldownSeconds: 120
        ).message

        XCTAssertEqual(message, "settings_changed grace_period_seconds=10 idle_timeout_seconds=300 response_mode=\"silent\" alarm_sound=\"ping\" alarm_volume=\"maximum\" lock_screen_enabled=false launch_at_login_enabled=true event_log_detail=\"standard\" event_log_storage=\"encrypted\" bluetooth_proximity_timeout_seconds=60 ignore_wifi_disconnects=true trigger_cooldown_seconds=120")
    }

    func testLaunchAtLoginChangeFailedMessageContainsError() {
        let message = GuardEvent.launchAtLoginChangeFailed(error: "requiresAppBundle").message

        XCTAssertEqual(message, "launch_at_login_change_failed error=\"requiresAppBundle\"")
    }

    func testMinimalDetailOmitsNetworkValues() {
        let message = GuardEvent.networkChanged(previous: "Cafe WiFi", current: "Library WiFi", kind: .ssidChanged).message(detail: .minimal)

        XCTAssertEqual(message, "network_changed")
    }

    func testMinimalDetailOmitsBluetoothNames() {
        let learned = GuardEvent.bluetoothDeviceLearned(name: "Tobias iPhone").message(detail: .minimal)
        let outOfRange = GuardEvent.bluetoothDeviceOutOfRange(name: "Tobias iPhone").message(detail: .minimal)

        XCTAssertEqual(learned, "bluetooth_device_learned")
        XCTAssertEqual(outOfRange, "bluetooth_device_out_of_range")
    }

    func testMinimalDetailOmitsResponseReasons() {
        let grace = GuardEvent.gracePeriodStarted(reason: "Bluetooth device out of range: Tobias iPhone", seconds: .seconds(5)).message(detail: .minimal)
        let alarm = GuardEvent.alarmTriggered(reason: "Bluetooth device out of range: Tobias iPhone").message(detail: .minimal)
        let silent = GuardEvent.silentResponseTriggered(reason: "Bluetooth device out of range: Tobias iPhone").message(detail: .minimal)

        XCTAssertEqual(grace, "grace_period_started seconds=5")
        XCTAssertEqual(alarm, "alarm_triggered")
        XCTAssertEqual(silent, "silent_response_triggered")
    }

    func testWriteUsesSelectedDetail() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("events.log")
        let log = EventLog(url: url)

        log.write(.networkChanged(previous: "Cafe WiFi", current: "Library WiFi", kind: .ssidChanged), detail: .minimal)

        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("network_changed"))
        XCTAssertFalse(contents.contains("Cafe WiFi"))
        XCTAssertFalse(contents.contains("Library WiFi"))
    }

    func testTriggerIgnoredMessageContainsName() {
        let message = GuardEvent.triggerIgnored(name: "networkChange").message

        XCTAssertEqual(message, "trigger_ignored name=\"networkChange\"")
    }

    func testLogClearedMessage() {
        XCTAssertEqual(GuardEvent.logCleared.message, "log_cleared")
    }
}

private struct StaticEventLogKeyProvider: EventLogKeyProviding {
    func key() throws -> SymmetricKey {
        SymmetricKey(data: Data(repeating: 7, count: 32))
    }
}
