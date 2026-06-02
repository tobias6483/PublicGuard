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

    enum EventLogStorage: String, CaseIterable {
        case plainText
        case encrypted

        var title: String {
            switch self {
            case .plainText:
                "Plain Text"
            case .encrypted:
                "Encrypted"
            }
        }
    }

    enum EventLogRetention: String, CaseIterable {
        case forever
        case sevenDays
        case thirtyDays

        var title: String {
            switch self {
            case .forever:
                "Forever"
            case .sevenDays:
                "7 Days"
            case .thirtyDays:
                "30 Days"
            }
        }

        var days: Int? {
            switch self {
            case .forever:
                nil
            case .sevenDays:
                7
            case .thirtyDays:
                30
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
            if settings.bluetoothTargetIdentifier == nil {
                updated.enabledTriggers.remove(.bluetoothProximity)
            }
            updated.notificationsEnabled = true
            updated.lockScreenEnabled = true

            updated.gracePeriodSeconds = gracePeriodSeconds
            updated.idleTimeoutSeconds = idleTimeoutSeconds
            updated.responseMode = responseMode
            updated.alarmVolume = alarmVolume

            return updated
        }

        func matches(_ settings: GuardSettings) -> Bool {
            var expectedTriggers = enabledTriggers
            if settings.bluetoothTargetIdentifier == nil {
                expectedTriggers.remove(.bluetoothProximity)
            }

            return settings.enabledTriggers == expectedTriggers
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
                0
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
    var eventLogStorage: EventLogStorage = .plainText
    var eventLogRetention: EventLogRetention = .forever
    var bluetoothTargetIdentifier: String?
    var bluetoothTargetName: String?
    var bluetoothProximityTimeoutSeconds: Int = 30
    var ignoreWiFiDisconnects: Bool = false
    var triggerCooldownSeconds: Int = 30
    var triggerGracePeriodOverrides: [TriggerKind: Int] = [:]

    var gracePeriodDuration: Duration {
        .seconds(gracePeriodSeconds)
    }

    var triggerCooldownDuration: Duration {
        .seconds(triggerCooldownSeconds)
    }

    func isTriggerEnabled(_ trigger: TriggerKind) -> Bool {
        enabledTriggers.contains(trigger)
    }

    var hasLearnedBluetoothDevice: Bool {
        bluetoothTargetIdentifier != nil
    }

    func gracePeriodSeconds(for trigger: TriggerKind) -> Int {
        triggerGracePeriodOverrides[trigger] ?? gracePeriodSeconds
    }

    func gracePeriodDuration(for trigger: TriggerKind) -> Duration {
        .seconds(gracePeriodSeconds(for: trigger))
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
        static let eventLogStorage = "eventLogStorage"
        static let eventLogRetention = "eventLogRetention"
        static let bluetoothTargetIdentifier = "bluetoothTargetIdentifier"
        static let bluetoothTargetName = "bluetoothTargetName"
        static let bluetoothProximityTimeoutSeconds = "bluetoothProximityTimeoutSeconds"
        static let ignoreWiFiDisconnects = "ignoreWiFiDisconnects"
        static let triggerCooldownSeconds = "triggerCooldownSeconds"
        static let triggerGracePeriodOverrides = "triggerGracePeriodOverrides"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> GuardSettings {
        let storedGracePeriod = defaults.object(forKey: Key.gracePeriodSeconds) as? Int
        let gracePeriod = storedGracePeriod.flatMap { Self.validGracePeriods.contains($0) ? $0 : nil } ?? 0
        let storedIdleTimeout = defaults.object(forKey: Key.idleTimeoutSeconds) as? Int
        let idleTimeout = storedIdleTimeout.flatMap { Self.validIdleTimeouts.contains($0) ? $0 : nil } ?? 300

        let storedMode = defaults.string(forKey: Key.responseMode)
        let mode = storedMode.flatMap(GuardSettings.ResponseMode.init(rawValue:)) ?? .loudAlarm

        let bluetoothTargetIdentifier = defaults.string(forKey: Key.bluetoothTargetIdentifier)
        let bluetoothTargetName = defaults.string(forKey: Key.bluetoothTargetName)
        let storedTriggerValues = defaults.stringArray(forKey: Key.enabledTriggers)
        let triggers = storedTriggerValues.map { values in
            Set(values.compactMap(GuardSettings.TriggerKind.init(rawValue:)))
        } ?? Self.defaultEnabledTriggers(bluetoothTargetIdentifier: bluetoothTargetIdentifier)

        let enabledTriggers = Self.sanitizedEnabledTriggers(
            triggers,
            bluetoothTargetIdentifier: bluetoothTargetIdentifier
        )
        let notificationsEnabled = defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        let storedAlarmSound = defaults.string(forKey: Key.alarmSound)
        let alarmSound = storedAlarmSound.flatMap(GuardSettings.AlarmSound.init(rawValue:)) ?? .appleAlarm
        let storedAlarmVolume = defaults.string(forKey: Key.alarmVolume)
        let alarmVolume = storedAlarmVolume.flatMap(GuardSettings.AlarmVolume.init(rawValue:)) ?? .normal
        let lockScreenEnabled = defaults.object(forKey: Key.lockScreenEnabled) as? Bool ?? true
        let launchAtLoginEnabled = defaults.object(forKey: Key.launchAtLoginEnabled) as? Bool ?? false
        let storedEventLogDetail = defaults.string(forKey: Key.eventLogDetail)
        let eventLogDetail = storedEventLogDetail.flatMap(GuardSettings.EventLogDetail.init(rawValue:)) ?? .standard
        let storedEventLogStorage = defaults.string(forKey: Key.eventLogStorage)
        let eventLogStorage = storedEventLogStorage.flatMap(GuardSettings.EventLogStorage.init(rawValue:)) ?? .plainText
        let storedEventLogRetention = defaults.string(forKey: Key.eventLogRetention)
        let eventLogRetention = storedEventLogRetention.flatMap(GuardSettings.EventLogRetention.init(rawValue:)) ?? .forever
        let storedBluetoothTimeout = defaults.object(forKey: Key.bluetoothProximityTimeoutSeconds) as? Int
        let bluetoothProximityTimeout = storedBluetoothTimeout.flatMap { Self.validBluetoothProximityTimeouts.contains($0) ? $0 : nil } ?? 30
        let ignoreWiFiDisconnects = defaults.object(forKey: Key.ignoreWiFiDisconnects) as? Bool ?? false
        let storedTriggerCooldown = defaults.object(forKey: Key.triggerCooldownSeconds) as? Int
        let triggerCooldown = storedTriggerCooldown.flatMap { Self.validTriggerCooldowns.contains($0) ? $0 : nil } ?? 30
        let triggerGracePeriodOverrides = Self.sanitizedTriggerGracePeriodOverrides(
            defaults.dictionary(forKey: Key.triggerGracePeriodOverrides) ?? [:]
        )

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
            eventLogStorage: eventLogStorage,
            eventLogRetention: eventLogRetention,
            bluetoothTargetIdentifier: bluetoothTargetIdentifier,
            bluetoothTargetName: bluetoothTargetName,
            bluetoothProximityTimeoutSeconds: bluetoothProximityTimeout,
            ignoreWiFiDisconnects: ignoreWiFiDisconnects,
            triggerCooldownSeconds: triggerCooldown,
            triggerGracePeriodOverrides: triggerGracePeriodOverrides
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
        defaults.set(settings.eventLogStorage.rawValue, forKey: Key.eventLogStorage)
        defaults.set(settings.eventLogRetention.rawValue, forKey: Key.eventLogRetention)
        setOptional(settings.bluetoothTargetIdentifier, forKey: Key.bluetoothTargetIdentifier)
        setOptional(settings.bluetoothTargetName, forKey: Key.bluetoothTargetName)
        defaults.set(settings.bluetoothProximityTimeoutSeconds, forKey: Key.bluetoothProximityTimeoutSeconds)
        defaults.set(settings.ignoreWiFiDisconnects, forKey: Key.ignoreWiFiDisconnects)
        defaults.set(settings.triggerCooldownSeconds, forKey: Key.triggerCooldownSeconds)
        defaults.set(
            Dictionary(uniqueKeysWithValues: settings.triggerGracePeriodOverrides.map { ($0.key.rawValue, $0.value) }),
            forKey: Key.triggerGracePeriodOverrides
        )
    }

    static let validGracePeriods = [0, 1, 5, 10, 15, 30]
    static let validIdleTimeouts = [0, 60, 300, 600, 900, 1800, 3600]
    static let validBluetoothProximityTimeouts = [15, 30, 60, 120]
    static let validTriggerCooldowns = [0, 30, 60, 120]
    static let validTriggerGraceOverrides = [0, 1, 5, 10, 15, 30, 60, 120]

    private static func defaultEnabledTriggers(bluetoothTargetIdentifier: String?) -> Set<GuardSettings.TriggerKind> {
        var triggers = Set(GuardSettings.TriggerKind.allCases)
        if bluetoothTargetIdentifier == nil {
            triggers.remove(.bluetoothProximity)
        }
        return triggers
    }

    private static func sanitizedEnabledTriggers(
        _ triggers: Set<GuardSettings.TriggerKind>,
        bluetoothTargetIdentifier: String?
    ) -> Set<GuardSettings.TriggerKind> {
        var result = triggers.isEmpty ? defaultEnabledTriggers(bluetoothTargetIdentifier: bluetoothTargetIdentifier) : triggers
        if bluetoothTargetIdentifier == nil {
            result.remove(.bluetoothProximity)
        }
        return result
    }

    private static func sanitizedTriggerGracePeriodOverrides(_ values: [String: Any]) -> [GuardSettings.TriggerKind: Int] {
        values.reduce(into: [:]) { result, item in
            let seconds: Int?
            if let value = item.value as? Int {
                seconds = value
            } else if let value = item.value as? NSNumber {
                seconds = value.intValue
            } else {
                seconds = nil
            }

            guard
                let trigger = GuardSettings.TriggerKind(rawValue: item.key),
                let seconds,
                validTriggerGraceOverrides.contains(seconds)
            else {
                return
            }

            result[trigger] = seconds
        }
    }

    private func setOptional(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
