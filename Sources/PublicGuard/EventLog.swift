import Foundation

struct EventLog {
    let url: URL

    init(url: URL? = nil) {
        if let url {
            self.url = url
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            return
        }

        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PublicGuard", isDirectory: true)

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = directory.appendingPathComponent("events.log")
    }

    func write(_ event: GuardEvent) {
        let line = "\(Self.timestamp()) \(event.message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            }
        } else {
            try? data.write(to: url)
        }
    }

    func clear() {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Data().write(to: url)
    }

    func recentEntries(limit: Int = 5) -> [String] {
        guard limit > 0,
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            return []
        }

        return contents
            .split(separator: "\n")
            .suffix(limit)
            .map(String.init)
    }

    private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}

enum GuardEvent {
    case appStarted
    case appStopped
    case armed
    case disarmed
    case authenticationFailed
    case chargerDisconnected
    case networkChanged(previous: String?, current: String?)
    case bluetoothDeviceLearned(name: String)
    case bluetoothDeviceOutOfRange(name: String)
    case idleTimeout(seconds: Int)
    case systemWillSleep
    case systemDidWake
    case gracePeriodStarted(reason: String, seconds: Duration)
    case alarmTriggered(reason: String)
    case alarmStopped
    case silentResponseTriggered(reason: String)
    case settingsChanged(
        gracePeriodSeconds: Int,
        idleTimeoutSeconds: Int,
        responseMode: GuardSettings.ResponseMode,
        alarmSound: GuardSettings.AlarmSound,
        alarmVolume: GuardSettings.AlarmVolume,
        lockScreenEnabled: Bool
    )
    case triggerIgnored(name: String)
    case logCleared

    var message: String {
        switch self {
        case .appStarted:
            "app_started"
        case .appStopped:
            "app_stopped"
        case .armed:
            "armed"
        case .disarmed:
            "disarmed"
        case .authenticationFailed:
            "authentication_failed"
        case .chargerDisconnected:
            "charger_disconnected"
        case let .networkChanged(previous, current):
            "network_changed previous=\"\(previous ?? "none")\" current=\"\(current ?? "none")\""
        case let .bluetoothDeviceLearned(name):
            "bluetooth_device_learned name=\"\(name)\""
        case let .bluetoothDeviceOutOfRange(name):
            "bluetooth_device_out_of_range name=\"\(name)\""
        case let .idleTimeout(seconds):
            "idle_timeout seconds=\(seconds)"
        case .systemWillSleep:
            "system_will_sleep"
        case .systemDidWake:
            "system_did_wake"
        case let .gracePeriodStarted(reason, seconds):
            "grace_period_started seconds=\(seconds.components.seconds) reason=\"\(reason)\""
        case let .alarmTriggered(reason):
            "alarm_triggered reason=\"\(reason)\""
        case .alarmStopped:
            "alarm_stopped"
        case let .silentResponseTriggered(reason):
            "silent_response_triggered reason=\"\(reason)\""
        case let .settingsChanged(gracePeriodSeconds, idleTimeoutSeconds, responseMode, alarmSound, alarmVolume, lockScreenEnabled):
            "settings_changed grace_period_seconds=\(gracePeriodSeconds) idle_timeout_seconds=\(idleTimeoutSeconds) response_mode=\"\(responseMode.rawValue)\" alarm_sound=\"\(alarmSound.rawValue)\" alarm_volume=\"\(alarmVolume.rawValue)\" lock_screen_enabled=\(lockScreenEnabled)"
        case let .triggerIgnored(name):
            "trigger_ignored name=\"\(name)\""
        case .logCleared:
            "log_cleared"
        }
    }
}
