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
        case bluetoothProximity

        var title: String {
            switch self {
            case .chargerDisconnect:
                "Charger Disconnect"
            case .networkChange:
                "Wi-Fi Change"
            case .wakeFromSleep:
                "Wake From Sleep"
            case .bluetoothProximity:
                "Bluetooth Proximity"
            }
        }
    }

    enum AlarmSound: String, CaseIterable {
        case appleAlarm
        case beaconPulse
        case highAlert
        case classic
        case basso
        case sosumi
        case ping

        var title: String {
            switch self {
            case .appleAlarm:
                "Apple Alarm"
            case .beaconPulse:
                "Beacon Pulse"
            case .highAlert:
                "High Alert"
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
            case .appleAlarm, .beaconPulse, .highAlert:
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

        var bundledResource: (name: String, extension: String)? {
            switch self {
            case .appleAlarm:
                ("AppleAlarm", "mp3")
            case .beaconPulse:
                ("BeaconPulse", "wav")
            case .highAlert:
                ("HighAlert", "wav")
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
    var lockScreenEnabled: Bool
    var bluetoothTargetIdentifier: String?
    var bluetoothTargetName: String?

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
        static let lockScreenEnabled = "lockScreenEnabled"
        static let bluetoothTargetIdentifier = "bluetoothTargetIdentifier"
        static let bluetoothTargetName = "bluetoothTargetName"
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
        let lockScreenEnabled = defaults.object(forKey: Key.lockScreenEnabled) as? Bool ?? true
        let bluetoothTargetIdentifier = defaults.string(forKey: Key.bluetoothTargetIdentifier)
        let bluetoothTargetName = defaults.string(forKey: Key.bluetoothTargetName)

        return GuardSettings(
            gracePeriodSeconds: gracePeriod,
            responseMode: mode,
            enabledTriggers: enabledTriggers,
            notificationsEnabled: notificationsEnabled,
            alarmSound: alarmSound,
            lockScreenEnabled: lockScreenEnabled,
            bluetoothTargetIdentifier: bluetoothTargetIdentifier,
            bluetoothTargetName: bluetoothTargetName
        )
    }

    func save(_ settings: GuardSettings) {
        defaults.set(settings.gracePeriodSeconds, forKey: Key.gracePeriodSeconds)
        defaults.set(settings.responseMode.rawValue, forKey: Key.responseMode)
        defaults.set(settings.enabledTriggers.map(\.rawValue).sorted(), forKey: Key.enabledTriggers)
        defaults.set(settings.notificationsEnabled, forKey: Key.notificationsEnabled)
        defaults.set(settings.alarmSound.rawValue, forKey: Key.alarmSound)
        defaults.set(settings.lockScreenEnabled, forKey: Key.lockScreenEnabled)
        setOptional(settings.bluetoothTargetIdentifier, forKey: Key.bluetoothTargetIdentifier)
        setOptional(settings.bluetoothTargetName, forKey: Key.bluetoothTargetName)
    }

    static let validGracePeriods = [0, 5, 10, 15, 30]

    private func setOptional(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
