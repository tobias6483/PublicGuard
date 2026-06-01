import XCTest
@testable import PublicGuard

final class SettingsStoreTests: XCTestCase {
    func testLoadUsesDefaultsWhenNothingStored() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        let settings = store.load()

        XCTAssertEqual(settings.gracePeriodSeconds, 5)
        XCTAssertEqual(settings.responseMode, .loudAlarm)
        XCTAssertEqual(settings.enabledTriggers, Set(GuardSettings.TriggerKind.allCases))
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.alarmSound, .appleAlarm)
    }

    func testSaveAndLoadRoundTripsSettings() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        let expected = GuardSettings(
            gracePeriodSeconds: 15,
            responseMode: .silent,
            enabledTriggers: [.chargerDisconnect, .networkChange],
            notificationsEnabled: false,
            alarmSound: .sosumi
        )

        store.save(expected)

        XCTAssertEqual(store.load().gracePeriodSeconds, 15)
        XCTAssertEqual(store.load().responseMode, .silent)
        XCTAssertEqual(store.load().enabledTriggers, [.chargerDisconnect, .networkChange])
        XCTAssertFalse(store.load().notificationsEnabled)
        XCTAssertEqual(store.load().alarmSound, .sosumi)
    }

    func testInvalidGracePeriodFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set(999, forKey: "gracePeriodSeconds")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().gracePeriodSeconds, 5)
    }

    func testZeroGracePeriodIsValid() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 0,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm
        ))

        XCTAssertEqual(store.load().gracePeriodSeconds, 0)
    }

    func testEmptyStoredTriggerListFallsBackToAllTriggers() {
        let defaults = makeDefaults()
        defaults.set([String](), forKey: "enabledTriggers")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().enabledTriggers, Set(GuardSettings.TriggerKind.allCases))
    }

    func testNotificationsCanBeDisabled() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: false,
            alarmSound: .appleAlarm
        ))

        XCTAssertFalse(store.load().notificationsEnabled)
    }

    func testInvalidAlarmSoundFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("not-a-real-sound", forKey: "alarmSound")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().alarmSound, .appleAlarm)
    }

    func testBundledAlarmSoundsDeclareResources() {
        XCTAssertEqual(GuardSettings.AlarmSound.appleAlarm.bundledResource?.name, "AppleAlarm")
        XCTAssertEqual(GuardSettings.AlarmSound.appleAlarm.bundledResource?.extension, "mp3")
        XCTAssertEqual(GuardSettings.AlarmSound.beaconPulse.bundledResource?.name, "BeaconPulse")
        XCTAssertEqual(GuardSettings.AlarmSound.beaconPulse.bundledResource?.extension, "wav")
        XCTAssertEqual(GuardSettings.AlarmSound.highAlert.bundledResource?.name, "HighAlert")
        XCTAssertEqual(GuardSettings.AlarmSound.highAlert.bundledResource?.extension, "wav")
    }

    func testSystemAlarmSoundsDoNotDeclareBundledResources() {
        XCTAssertNil(GuardSettings.AlarmSound.classic.bundledResource)
        XCTAssertNil(GuardSettings.AlarmSound.basso.bundledResource)
        XCTAssertNil(GuardSettings.AlarmSound.sosumi.bundledResource)
        XCTAssertNil(GuardSettings.AlarmSound.ping.bundledResource)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "PublicGuardTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
