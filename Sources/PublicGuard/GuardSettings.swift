import Foundation

struct GuardSettings {
    enum ResponseMode: String, CaseIterable {
        case loudAlarm
        case silent

        var title: String {
            switch self {
            case .loudAlarm:
                "Loud Alarm"
            case .silent:
                "Silent"
            }
        }
    }

    var gracePeriodSeconds: Int
    var responseMode: ResponseMode

    var gracePeriodDuration: Duration {
        .seconds(gracePeriodSeconds)
    }
}

struct SettingsStore {
    private enum Key {
        static let gracePeriodSeconds = "gracePeriodSeconds"
        static let responseMode = "responseMode"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GuardSettings {
        let storedGracePeriod = defaults.object(forKey: Key.gracePeriodSeconds) as? Int
        let gracePeriod = storedGracePeriod.flatMap { Self.validGracePeriods.contains($0) ? $0 : nil } ?? 5

        let storedMode = defaults.string(forKey: Key.responseMode)
        let mode = storedMode.flatMap(GuardSettings.ResponseMode.init(rawValue:)) ?? .loudAlarm

        return GuardSettings(gracePeriodSeconds: gracePeriod, responseMode: mode)
    }

    func save(_ settings: GuardSettings) {
        defaults.set(settings.gracePeriodSeconds, forKey: Key.gracePeriodSeconds)
        defaults.set(settings.responseMode.rawValue, forKey: Key.responseMode)
    }

    static let validGracePeriods = [0, 5, 10, 15, 30]
}
