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
        case idleTimeout

        var title: String {
            switch self {
            case .chargerDisconnect:
                "Charger Disconnect"
            case .networkChange:
                "Wi-Fi Change"
            case .wakeFromSleep:
                "Lid Close / Wake"
            case .bluetoothProximity:
                "Bluetooth Proximity"
            case .idleTimeout:
                "Idle Timeout"
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

    enum AlarmVolume: String, CaseIterable {
        case normal
        case maximum

        var title: String {
            switch self {
            case .normal:
                "Normal"
            case .maximum:
                "Maximum"
            }
        }

        var soundVolume: Float {
            switch self {
            case .normal:
                0.8
            case .maximum:
                1.0
            }
        }
    }

    enum EventLogDetail: String, CaseIterable {
        case standard
        case minimal

        var title: String {
            switch self {
            case .standard:
                "Standard"
            case .minimal:
                "Minimal"
            }
        }
    }

    enum SessionPreset: String, CaseIterable {
        case cafe
        case library
        case school
        case office

        var title: String {
            switch self {
            case .cafe:
                "Café"
            case .library:
                "Library"
            case .school:
                "School"
            case .office:
                "Office"
            }
        }

        func applied(to settings: GuardSettings) -> GuardSettings {
            var updated = settings
            updated.enabledTriggers = enabledTriggers
            updated.notificationsEnabled = true
            updated.lockScreenEnabled = true

            updated.gracePeriodSeconds = gracePeriodSeconds
            updated.idleTimeoutSeconds = idleTimeoutSeconds
            updated.responseMode = responseMode
            updated.alarmVolume = alarmVolume

            return updated
        }

        func matches(_ settings: GuardSettings) -> Bool {
            settings.enabledTriggers == enabledTriggers
                && settings.notificationsEnabled
                && settings.lockScreenEnabled
                && settings.gracePeriodSeconds == gracePeriodSeconds
                && settings.idleTimeoutSeconds == idleTimeoutSeconds
                && settings.responseMode == responseMode
                && settings.alarmVolume == alarmVolume
        }

        private var gracePeriodSeconds: Int {
            switch self {
            case .cafe:
                5
            case .library:
                15
            case .school:
                10
            case .office:
                30
            }
        }

        private var idleTimeoutSeconds: Int {
            switch self {
            case .cafe:
                300
            case .library:
                900
            case .school:
                600
            case .office:
                600
            }
        }

        private var responseMode: ResponseMode {
            switch self {
            case .cafe:
                .loudAlarm
            case .library:
                .silent
            case .school:
                .loudAlarm
            case .office:
                .silent
            }
        }

        private var alarmVolume: AlarmVolume {
            switch self {
            case .cafe:
                .maximum
            case .library:
                .normal
            case .school:
                .normal
            case .office:
                .normal
            }
        }

        private var enabledTriggers: Set<TriggerKind> {
            switch self {
            case .cafe, .library, .school:
                Set(TriggerKind.allCases)
            case .office:
                [.chargerDisconnect, .wakeFromSleep, .bluetoothProximity, .idleTimeout]
            }
        }
    }

    var gracePeriodSeconds: Int
    var idleTimeoutSeconds: Int = 300
    var responseMode: ResponseMode
    var enabledTriggers: Set<TriggerKind>
    var notificationsEnabled: Bool
    var alarmSound: AlarmSound
    var alarmVolume: AlarmVolume = .normal
    var lockScreenEnabled: Bool
    var launchAtLoginEnabled: Bool = false
    var eventLogDetail: EventLogDetail = .standard
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
        static let idleTimeoutSeconds = "idleTimeoutSeconds"
        static let responseMode = "responseMode"
        static let enabledTriggers = "enabledTriggers"
        static let notificationsEnabled = "notificationsEnabled"
        static let alarmSound = "alarmSound"
        static let alarmVolume = "alarmVolume"
        static let lockScreenEnabled = "lockScreenEnabled"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let eventLogDetail = "eventLogDetail"
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
        let storedIdleTimeout = defaults.object(forKey: Key.idleTimeoutSeconds) as? Int
        let idleTimeout = storedIdleTimeout.flatMap { Self.validIdleTimeouts.contains($0) ? $0 : nil } ?? 300

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
        let storedAlarmVolume = defaults.string(forKey: Key.alarmVolume)
        let alarmVolume = storedAlarmVolume.flatMap(GuardSettings.AlarmVolume.init(rawValue:)) ?? .normal
        let lockScreenEnabled = defaults.object(forKey: Key.lockScreenEnabled) as? Bool ?? true
        let launchAtLoginEnabled = defaults.object(forKey: Key.launchAtLoginEnabled) as? Bool ?? false
        let storedEventLogDetail = defaults.string(forKey: Key.eventLogDetail)
        let eventLogDetail = storedEventLogDetail.flatMap(GuardSettings.EventLogDetail.init(rawValue:)) ?? .standard
        let bluetoothTargetIdentifier = defaults.string(forKey: Key.bluetoothTargetIdentifier)
        let bluetoothTargetName = defaults.string(forKey: Key.bluetoothTargetName)

        return GuardSettings(
            gracePeriodSeconds: gracePeriod,
            idleTimeoutSeconds: idleTimeout,
            responseMode: mode,
            enabledTriggers: enabledTriggers,
            notificationsEnabled: notificationsEnabled,
            alarmSound: alarmSound,
            alarmVolume: alarmVolume,
            lockScreenEnabled: lockScreenEnabled,
            launchAtLoginEnabled: launchAtLoginEnabled,
            eventLogDetail: eventLogDetail,
            bluetoothTargetIdentifier: bluetoothTargetIdentifier,
            bluetoothTargetName: bluetoothTargetName
        )
    }

    func save(_ settings: GuardSettings) {
        defaults.set(settings.gracePeriodSeconds, forKey: Key.gracePeriodSeconds)
        defaults.set(settings.idleTimeoutSeconds, forKey: Key.idleTimeoutSeconds)
        defaults.set(settings.responseMode.rawValue, forKey: Key.responseMode)
        defaults.set(settings.enabledTriggers.map(\.rawValue).sorted(), forKey: Key.enabledTriggers)
        defaults.set(settings.notificationsEnabled, forKey: Key.notificationsEnabled)
        defaults.set(settings.alarmSound.rawValue, forKey: Key.alarmSound)
        defaults.set(settings.alarmVolume.rawValue, forKey: Key.alarmVolume)
        defaults.set(settings.lockScreenEnabled, forKey: Key.lockScreenEnabled)
        defaults.set(settings.launchAtLoginEnabled, forKey: Key.launchAtLoginEnabled)
        defaults.set(settings.eventLogDetail.rawValue, forKey: Key.eventLogDetail)
        setOptional(settings.bluetoothTargetIdentifier, forKey: Key.bluetoothTargetIdentifier)
        setOptional(settings.bluetoothTargetName, forKey: Key.bluetoothTargetName)
    }

    static let validGracePeriods = [0, 5, 10, 15, 30]
    static let validIdleTimeouts = [60, 300, 600, 900]

    private func setOptional(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
