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
    }

    func testSaveAndLoadRoundTripsSettings() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        let expected = GuardSettings(
            gracePeriodSeconds: 15,
            responseMode: .silent,
            enabledTriggers: [.chargerDisconnect, .networkChange],
            notificationsEnabled: false
        )

        store.save(expected)

        XCTAssertEqual(store.load().gracePeriodSeconds, 15)
        XCTAssertEqual(store.load().responseMode, .silent)
        XCTAssertEqual(store.load().enabledTriggers, [.chargerDisconnect, .networkChange])
        XCTAssertFalse(store.load().notificationsEnabled)
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
            notificationsEnabled: true
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
            notificationsEnabled: false
        ))

        XCTAssertFalse(store.load().notificationsEnabled)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "PublicGuardTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
