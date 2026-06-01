import XCTest
@testable import PublicGuard

final class SettingsStoreTests: XCTestCase {
    func testLoadUsesDefaultsWhenNothingStored() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        let settings = store.load()

        XCTAssertEqual(settings.gracePeriodSeconds, 5)
        XCTAssertEqual(settings.idleTimeoutSeconds, 300)
        XCTAssertEqual(settings.responseMode, .loudAlarm)
        XCTAssertEqual(settings.enabledTriggers, Set(GuardSettings.TriggerKind.allCases))
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.alarmSound, .appleAlarm)
        XCTAssertEqual(settings.alarmVolume, .normal)
        XCTAssertTrue(settings.lockScreenEnabled)
        XCTAssertFalse(settings.launchAtLoginEnabled)
        XCTAssertEqual(settings.eventLogDetail, .standard)
        XCTAssertNil(settings.bluetoothTargetIdentifier)
        XCTAssertNil(settings.bluetoothTargetName)
    }

    func testSaveAndLoadRoundTripsSettings() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        let expected = GuardSettings(
            gracePeriodSeconds: 15,
            idleTimeoutSeconds: 600,
            responseMode: .silent,
            enabledTriggers: [.chargerDisconnect, .networkChange],
            notificationsEnabled: false,
            alarmSound: .sosumi,
            alarmVolume: .maximum,
            lockScreenEnabled: false,
            launchAtLoginEnabled: true,
            eventLogDetail: .minimal,
            bluetoothTargetIdentifier: "C07F4E70-7A07-4032-8C77-8EB75490D620",
            bluetoothTargetName: "Tobias iPhone"
        )

        store.save(expected)

        XCTAssertEqual(store.load().gracePeriodSeconds, 15)
        XCTAssertEqual(store.load().idleTimeoutSeconds, 600)
        XCTAssertEqual(store.load().responseMode, .silent)
        XCTAssertEqual(store.load().enabledTriggers, [.chargerDisconnect, .networkChange])
        XCTAssertFalse(store.load().notificationsEnabled)
        XCTAssertEqual(store.load().alarmSound, .sosumi)
        XCTAssertEqual(store.load().alarmVolume, .maximum)
        XCTAssertFalse(store.load().lockScreenEnabled)
        XCTAssertTrue(store.load().launchAtLoginEnabled)
        XCTAssertEqual(store.load().eventLogDetail, .minimal)
        XCTAssertEqual(store.load().bluetoothTargetIdentifier, "C07F4E70-7A07-4032-8C77-8EB75490D620")
        XCTAssertEqual(store.load().bluetoothTargetName, "Tobias iPhone")
    }

    func testBluetoothTargetCanBeCleared() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            bluetoothTargetIdentifier: "C07F4E70-7A07-4032-8C77-8EB75490D620",
            bluetoothTargetName: "Tobias iPhone"
        ))

        var settings = store.load()
        settings.bluetoothTargetIdentifier = nil
        settings.bluetoothTargetName = nil
        store.save(settings)

        XCTAssertNil(store.load().bluetoothTargetIdentifier)
        XCTAssertNil(store.load().bluetoothTargetName)
    }

    func testInvalidGracePeriodFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set(999, forKey: "gracePeriodSeconds")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().gracePeriodSeconds, 5)
    }

    func testInvalidIdleTimeoutFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set(999, forKey: "idleTimeoutSeconds")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().idleTimeoutSeconds, 300)
    }

    func testZeroGracePeriodIsValid() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 0,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true
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
            alarmSound: .appleAlarm,
            lockScreenEnabled: true
        ))

        XCTAssertFalse(store.load().notificationsEnabled)
    }

    func testInvalidAlarmSoundFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("not-a-real-sound", forKey: "alarmSound")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().alarmSound, .appleAlarm)
    }

    func testInvalidAlarmVolumeFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("not-a-real-volume", forKey: "alarmVolume")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().alarmVolume, .normal)
    }

    func testInvalidEventLogDetailFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("not-a-real-detail", forKey: "eventLogDetail")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().eventLogDetail, .standard)
    }

    func testAlarmVolumeValuesMapToSoundVolumes() {
        XCTAssertEqual(GuardSettings.AlarmVolume.normal.soundVolume, 0.8)
        XCTAssertEqual(GuardSettings.AlarmVolume.maximum.soundVolume, 1.0)
    }

    func testCafePresetAppliesFastLoudPublicSettings() {
        let settings = customSettings().applyingPreset(.cafe)

        XCTAssertEqual(settings.gracePeriodSeconds, 5)
        XCTAssertEqual(settings.idleTimeoutSeconds, 300)
        XCTAssertEqual(settings.responseMode, .loudAlarm)
        XCTAssertEqual(settings.enabledTriggers, Set(GuardSettings.TriggerKind.allCases))
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.alarmSound, .ping)
        XCTAssertEqual(settings.alarmVolume, .maximum)
        XCTAssertTrue(settings.lockScreenEnabled)
        XCTAssertTrue(settings.launchAtLoginEnabled)
        XCTAssertEqual(settings.eventLogDetail, .minimal)
        XCTAssertEqual(settings.bluetoothTargetIdentifier, "C07F4E70-7A07-4032-8C77-8EB75490D620")
        XCTAssertEqual(settings.bluetoothTargetName, "Tobias iPhone")
    }

    func testLibraryPresetAppliesQuietPublicSettings() {
        let settings = customSettings().applyingPreset(.library)

        XCTAssertEqual(settings.gracePeriodSeconds, 15)
        XCTAssertEqual(settings.idleTimeoutSeconds, 900)
        XCTAssertEqual(settings.responseMode, .silent)
        XCTAssertEqual(settings.enabledTriggers, Set(GuardSettings.TriggerKind.allCases))
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.alarmSound, .ping)
        XCTAssertEqual(settings.alarmVolume, .normal)
        XCTAssertTrue(settings.lockScreenEnabled)
        XCTAssertTrue(settings.launchAtLoginEnabled)
        XCTAssertEqual(settings.eventLogDetail, .minimal)
        XCTAssertEqual(settings.bluetoothTargetIdentifier, "C07F4E70-7A07-4032-8C77-8EB75490D620")
        XCTAssertEqual(settings.bluetoothTargetName, "Tobias iPhone")
    }

    func testPresetMatchesOnlyWhenPresetControlledSettingsMatch() {
        var settings = customSettings().applyingPreset(.cafe)

        XCTAssertTrue(GuardSettings.SessionPreset.cafe.matches(settings))
        XCTAssertFalse(GuardSettings.SessionPreset.library.matches(settings))

        settings.alarmSound = .basso
        settings.bluetoothTargetName = nil
        XCTAssertTrue(GuardSettings.SessionPreset.cafe.matches(settings))

        settings.enabledTriggers.remove(.idleTimeout)
        XCTAssertFalse(GuardSettings.SessionPreset.cafe.matches(settings))
    }

    func testLockScreenCanBeDisabled() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: false
        ))

        XCTAssertFalse(store.load().lockScreenEnabled)
    }

    func testLaunchAtLoginCanBeEnabled() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            launchAtLoginEnabled: true
        ))

        XCTAssertTrue(store.load().launchAtLoginEnabled)
    }

    func testEventLogDetailCanBeMinimal() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            eventLogDetail: .minimal
        ))

        XCTAssertEqual(store.load().eventLogDetail, .minimal)
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

private extension GuardSettings {
    func applyingPreset(_ preset: GuardSettings.SessionPreset) -> GuardSettings {
        preset.applied(to: self)
    }
}

private func customSettings() -> GuardSettings {
    GuardSettings(
        gracePeriodSeconds: 30,
        idleTimeoutSeconds: 60,
        responseMode: .loudAlarm,
        enabledTriggers: [.chargerDisconnect],
        notificationsEnabled: false,
        alarmSound: .ping,
        alarmVolume: .normal,
        lockScreenEnabled: false,
        launchAtLoginEnabled: true,
        eventLogDetail: .minimal,
        bluetoothTargetIdentifier: "C07F4E70-7A07-4032-8C77-8EB75490D620",
        bluetoothTargetName: "Tobias iPhone"
    )
}
