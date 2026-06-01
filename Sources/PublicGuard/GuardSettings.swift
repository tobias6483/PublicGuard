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

    enum TriggerKind: String, CaseIterable {
        case chargerDisconnect
        case networkChange
        case wakeFromSleep

        var title: String {
            switch self {
            case .chargerDisconnect:
                "Charger Disconnect"
            case .networkChange:
                "Wi-Fi Change"
            case .wakeFromSleep:
                "Wake From Sleep"
            }
        }
    }

    enum AlarmSound: String, CaseIterable {
        case appleAlarm
        case classic
        case basso
        case sosumi
        case ping

        var title: String {
            switch self {
            case .appleAlarm:
                "Apple Alarm"
            case .classic:
                "Classic Burst"
            case .basso:
                "Basso"
            case .sosumi:
                "Sosumi"
            case .ping:
                "Ping"
            }
        }

        var systemSoundNames: [String] {
            switch self {
            case .appleAlarm:
                []
            case .classic:
                ["Basso", "Sosumi", "Ping"]
            case .basso:
                ["Basso"]
            case .sosumi:
                ["Sosumi"]
            case .ping:
                ["Ping"]
            }
        }

        var bundledResourceName: String? {
            switch self {
            case .appleAlarm:
                "AppleAlarm"
            case .classic, .basso, .sosumi, .ping:
                nil
            }
        }
    }

    var gracePeriodSeconds: Int
    var responseMode: ResponseMode
    var enabledTriggers: Set<TriggerKind>
    var notificationsEnabled: Bool
    var alarmSound: AlarmSound

    var gracePeriodDuration: Duration {
        .seconds(gracePeriodSeconds)
    }

    func isTriggerEnabled(_ trigger: TriggerKind) -> Bool {
        enabledTriggers.contains(trigger)
    }
}

struct SettingsStore {
    private enum Key {
        static let gracePeriodSeconds = "gracePeriodSeconds"
        static let responseMode = "responseMode"
        static let enabledTriggers = "enabledTriggers"
        static let notificationsEnabled = "notificationsEnabled"
        static let alarmSound = "alarmSound"
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

        let storedTriggerValues = defaults.stringArray(forKey: Key.enabledTriggers)
        let triggers = storedTriggerValues.map { values in
            Set(values.compactMap(GuardSettings.TriggerKind.init(rawValue:)))
        } ?? Set(GuardSettings.TriggerKind.allCases)

        let enabledTriggers = triggers.isEmpty ? Set(GuardSettings.TriggerKind.allCases) : triggers
        let notificationsEnabled = defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        let storedAlarmSound = defaults.string(forKey: Key.alarmSound)
        let alarmSound = storedAlarmSound.flatMap(GuardSettings.AlarmSound.init(rawValue:)) ?? .appleAlarm

        return GuardSettings(
            gracePeriodSeconds: gracePeriod,
            responseMode: mode,
            enabledTriggers: enabledTriggers,
            notificationsEnabled: notificationsEnabled,
            alarmSound: alarmSound
        )
    }

    func save(_ settings: GuardSettings) {
        defaults.set(settings.gracePeriodSeconds, forKey: Key.gracePeriodSeconds)
        defaults.set(settings.responseMode.rawValue, forKey: Key.responseMode)
        defaults.set(settings.enabledTriggers.map(\.rawValue).sorted(), forKey: Key.enabledTriggers)
        defaults.set(settings.notificationsEnabled, forKey: Key.notificationsEnabled)
        defaults.set(settings.alarmSound.rawValue, forKey: Key.alarmSound)
    }

    static let validGracePeriods = [0, 5, 10, 15, 30]
}
