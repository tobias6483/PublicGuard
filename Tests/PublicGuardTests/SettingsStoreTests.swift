import XCTest
@testable import PublicGuard

final class SettingsStoreTests: XCTestCase {
    func testLoadUsesDefaultsWhenNothingStored() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)

        let settings = store.load()

        XCTAssertEqual(settings.gracePeriodSeconds, 5)
        XCTAssertEqual(settings.responseMode, .loudAlarm)
    }

    func testSaveAndLoadRoundTripsSettings() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        let expected = GuardSettings(gracePeriodSeconds: 15, responseMode: .silent)

        store.save(expected)

        XCTAssertEqual(store.load().gracePeriodSeconds, 15)
        XCTAssertEqual(store.load().responseMode, .silent)
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

        store.save(GuardSettings(gracePeriodSeconds: 0, responseMode: .loudAlarm))

        XCTAssertEqual(store.load().gracePeriodSeconds, 0)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "PublicGuardTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
