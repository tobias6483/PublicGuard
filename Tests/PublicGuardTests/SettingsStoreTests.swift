import XCTest
@testable import PublicGuard

final class SettingsStoreTests: XCTestCase {
    func testLoadUsesDefaultsWhenNothingStored() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        let settings = store.load()

        XCTAssertEqual(settings.gracePeriodSeconds, 0)
        XCTAssertEqual(settings.idleTimeoutSeconds, 300)
        XCTAssertEqual(settings.responseMode, .loudAlarm)
        XCTAssertEqual(settings.enabledTriggers, allTriggersExceptBluetooth)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.alarmSound, .appleAlarm)
        XCTAssertEqual(settings.alarmVolume, .normal)
        XCTAssertTrue(settings.lockScreenEnabled)
        XCTAssertFalse(settings.launchAtLoginEnabled)
        XCTAssertEqual(settings.eventLogDetail, .standard)
        XCTAssertEqual(settings.eventLogStorage, .plainText)
        XCTAssertEqual(settings.eventLogRetention, .forever)
        XCTAssertNil(settings.bluetoothTargetIdentifier)
        XCTAssertNil(settings.bluetoothTargetName)
        XCTAssertEqual(settings.bluetoothProximityTimeoutSeconds, 30)
        XCTAssertFalse(settings.ignoreWiFiDisconnects)
        XCTAssertEqual(settings.triggerCooldownSeconds, 30)
        XCTAssertEqual(settings.triggerGracePeriodOverrides, [:])
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
            eventLogStorage: .encrypted,
            eventLogRetention: .sevenDays,
            bluetoothTargetIdentifier: "C07F4E70-7A07-4032-8C77-8EB75490D620",
            bluetoothTargetName: "Tobias iPhone",
            bluetoothProximityTimeoutSeconds: 60,
            ignoreWiFiDisconnects: true,
            triggerCooldownSeconds: 120,
            triggerGracePeriodOverrides: [.networkChange: 30, .bluetoothProximity: 60]
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
        XCTAssertEqual(store.load().eventLogStorage, .encrypted)
        XCTAssertEqual(store.load().eventLogRetention, .sevenDays)
        XCTAssertEqual(store.load().bluetoothTargetIdentifier, "C07F4E70-7A07-4032-8C77-8EB75490D620")
        XCTAssertEqual(store.load().bluetoothTargetName, "Tobias iPhone")
        XCTAssertEqual(store.load().bluetoothProximityTimeoutSeconds, 60)
        XCTAssertTrue(store.load().ignoreWiFiDisconnects)
        XCTAssertEqual(store.load().triggerCooldownSeconds, 120)
        XCTAssertEqual(store.load().triggerGracePeriodOverrides, [.networkChange: 30, .bluetoothProximity: 60])
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
        XCTAssertFalse(store.load().enabledTriggers.contains(.bluetoothProximity))
    }

    func testInvalidGracePeriodFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set(999, forKey: "gracePeriodSeconds")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().gracePeriodSeconds, 0)
    }

    func testInvalidIdleTimeoutFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set(999, forKey: "idleTimeoutSeconds")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().idleTimeoutSeconds, 300)
    }

    func testDisabledIdleTimeoutIsValid() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            idleTimeoutSeconds: 0,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true
        ))

        XCTAssertEqual(store.load().idleTimeoutSeconds, 0)
    }

    func testLongIdleTimeoutIsValid() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            idleTimeoutSeconds: 3600,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true
        ))

        XCTAssertEqual(store.load().idleTimeoutSeconds, 3600)
    }

    func testInvalidBluetoothProximityTimeoutFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set(999, forKey: "bluetoothProximityTimeoutSeconds")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().bluetoothProximityTimeoutSeconds, 30)
    }

    func testInvalidTriggerCooldownFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set(999, forKey: "triggerCooldownSeconds")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().triggerCooldownSeconds, 30)
    }

    func testInvalidTriggerGraceOverridesAreDropped() {
        let defaults = makeDefaults()
        defaults.set([
            "networkChange": 60,
            "notATrigger": 30,
            "idleTimeout": 999
        ], forKey: "triggerGracePeriodOverrides")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().triggerGracePeriodOverrides, [.networkChange: 60])
    }

    func testTriggerGracePeriodUsesOverrideWhenPresent() {
        let settings = GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            triggerGracePeriodOverrides: [.networkChange: 60]
        )

        XCTAssertEqual(settings.gracePeriodSeconds(for: .networkChange), 60)
        XCTAssertEqual(settings.gracePeriodSeconds(for: .chargerDisconnect), 5)
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

    func testOneSecondGracePeriodIsValid() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 1,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            triggerGracePeriodOverrides: [.networkChange: 1]
        ))

        let settings = store.load()
        XCTAssertEqual(settings.gracePeriodSeconds, 1)
        XCTAssertEqual(settings.triggerGracePeriodOverrides, [.networkChange: 1])
    }

    func testEmptyStoredTriggerListKeepsAllTriggersDisabled() {
        let defaults = makeDefaults()
        defaults.set([String](), forKey: "enabledTriggers")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().enabledTriggers, [])
    }

    func testBluetoothTriggerIsValidWhenTargetIsLearned() {
        let defaults = makeDefaults()
        defaults.set("C07F4E70-7A07-4032-8C77-8EB75490D620", forKey: "bluetoothTargetIdentifier")
        defaults.set("Tobias iPhone", forKey: "bluetoothTargetName")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().enabledTriggers, Set(GuardSettings.TriggerKind.allCases))
    }

    func testStoredBluetoothTriggerIsDroppedWithoutTarget() {
        let defaults = makeDefaults()
        defaults.set(GuardSettings.TriggerKind.allCases.map(\.rawValue), forKey: "enabledTriggers")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().enabledTriggers, allTriggersExceptBluetooth)
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

    func testInvalidEventLogStorageFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("not-a-real-storage", forKey: "eventLogStorage")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().eventLogStorage, .plainText)
    }

    func testInvalidEventLogRetentionFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("not-a-real-retention", forKey: "eventLogRetention")
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load().eventLogRetention, .forever)
    }

    func testEventLogRetentionCanBeSevenDays() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            eventLogRetention: .sevenDays
        ))

        XCTAssertEqual(store.load().eventLogRetention, .sevenDays)
    }

    func testAlarmVolumeValuesMapToSoundVolumes() {
        XCTAssertEqual(GuardSettings.AlarmVolume.normal.soundVolume, 0.8)
        XCTAssertEqual(GuardSettings.AlarmVolume.maximum.soundVolume, 1.0)
        XCTAssertEqual(GuardSettings.AlarmVolume.maximumSystem.soundVolume, 1.0)
        XCTAssertFalse(GuardSettings.AlarmVolume.normal.raisesSystemOutputVolume)
        XCTAssertFalse(GuardSettings.AlarmVolume.maximum.raisesSystemOutputVolume)
        XCTAssertTrue(GuardSettings.AlarmVolume.maximumSystem.raisesSystemOutputVolume)
    }

    func testCafePresetAppliesFastLoudPublicSettings() {
        let settings = customSettings().applyingPreset(.cafe)

        XCTAssertEqual(settings.gracePeriodSeconds, 0)
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

    func testSchoolPresetAppliesCampusSettings() {
        let settings = customSettings().applyingPreset(.school)

        XCTAssertEqual(settings.gracePeriodSeconds, 10)
        XCTAssertEqual(settings.idleTimeoutSeconds, 600)
        XCTAssertEqual(settings.responseMode, .loudAlarm)
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

    func testOfficePresetDisablesNetworkChangeForRoamingNetworks() {
        let settings = customSettings().applyingPreset(.office)

        XCTAssertEqual(settings.gracePeriodSeconds, 30)
        XCTAssertEqual(settings.idleTimeoutSeconds, 600)
        XCTAssertEqual(settings.responseMode, .silent)
        XCTAssertEqual(settings.enabledTriggers, [.chargerDisconnect, .wakeFromSleep, .bluetoothProximity, .idleTimeout])
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
        XCTAssertFalse(GuardSettings.SessionPreset.school.matches(settings))
        XCTAssertFalse(GuardSettings.SessionPreset.office.matches(settings))

        settings.alarmSound = .basso
        settings.bluetoothTargetName = nil
        XCTAssertTrue(GuardSettings.SessionPreset.cafe.matches(settings))

        settings.enabledTriggers.remove(.idleTimeout)
        XCTAssertFalse(GuardSettings.SessionPreset.cafe.matches(settings))
    }

    func testOfficePresetMatchesWithNetworkChangeDisabled() {
        let settings = customSettings().applyingPreset(.office)

        XCTAssertTrue(GuardSettings.SessionPreset.office.matches(settings))
        XCTAssertFalse(settings.enabledTriggers.contains(.networkChange))
    }

    func testPresetDoesNotEnableBluetoothWithoutLearnedTarget() {
        var base = customSettings()
        base.bluetoothTargetIdentifier = nil
        base.bluetoothTargetName = nil

        let settings = base.applyingPreset(.cafe)

        XCTAssertEqual(settings.enabledTriggers, allTriggersExceptBluetooth)
        XCTAssertTrue(GuardSettings.SessionPreset.cafe.matches(settings))
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

    func testEventLogStorageCanBeEncrypted() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            eventLogStorage: .encrypted
        ))

        XCTAssertEqual(store.load().eventLogStorage, .encrypted)
    }

    func testBluetoothProximityTimeoutCanBeChanged() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            bluetoothProximityTimeoutSeconds: 120
        ))

        XCTAssertEqual(store.load().bluetoothProximityTimeoutSeconds, 120)
    }

    func testIgnoreWiFiDisconnectsCanBeEnabled() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            ignoreWiFiDisconnects: true
        ))

        XCTAssertTrue(store.load().ignoreWiFiDisconnects)
    }

    func testTriggerCooldownCanBeChanged() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        store.save(GuardSettings(
            gracePeriodSeconds: 5,
            responseMode: .loudAlarm,
            enabledTriggers: Set(GuardSettings.TriggerKind.allCases),
            notificationsEnabled: true,
            alarmSound: .appleAlarm,
            lockScreenEnabled: true,
            triggerCooldownSeconds: 0
        ))

        XCTAssertEqual(store.load().triggerCooldownSeconds, 0)
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

private var allTriggersExceptBluetooth: Set<GuardSettings.TriggerKind> {
    Set(GuardSettings.TriggerKind.allCases).subtracting([.bluetoothProximity])
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
