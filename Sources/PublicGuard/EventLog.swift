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

    func write(_ event: GuardEvent, detail: GuardSettings.EventLogDetail = .standard) {
        let line = "\(Self.timestamp()) \(event.message(detail: detail))\n"
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
        lockScreenEnabled: Bool,
        launchAtLoginEnabled: Bool,
        eventLogDetail: GuardSettings.EventLogDetail
    )
    case launchAtLoginChangeFailed(error: String)
    case triggerIgnored(name: String)
    case logCleared

    var message: String {
        message(detail: .standard)
    }

    func message(detail: GuardSettings.EventLogDetail) -> String {
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
            switch detail {
            case .standard:
                "network_changed previous=\"\(previous ?? "none")\" current=\"\(current ?? "none")\""
            case .minimal:
                "network_changed"
            }
        case let .bluetoothDeviceLearned(name):
            switch detail {
            case .standard:
                "bluetooth_device_learned name=\"\(name)\""
            case .minimal:
                "bluetooth_device_learned"
            }
        case let .bluetoothDeviceOutOfRange(name):
            switch detail {
            case .standard:
                "bluetooth_device_out_of_range name=\"\(name)\""
            case .minimal:
                "bluetooth_device_out_of_range"
            }
        case let .idleTimeout(seconds):
            "idle_timeout seconds=\(seconds)"
        case .systemWillSleep:
            "system_will_sleep"
        case .systemDidWake:
            "system_did_wake"
        case let .gracePeriodStarted(reason, seconds):
            switch detail {
            case .standard:
                "grace_period_started seconds=\(seconds.components.seconds) reason=\"\(reason)\""
            case .minimal:
                "grace_period_started seconds=\(seconds.components.seconds)"
            }
        case let .alarmTriggered(reason):
            switch detail {
            case .standard:
                "alarm_triggered reason=\"\(reason)\""
            case .minimal:
                "alarm_triggered"
            }
        case .alarmStopped:
            "alarm_stopped"
        case let .silentResponseTriggered(reason):
            switch detail {
            case .standard:
                "silent_response_triggered reason=\"\(reason)\""
            case .minimal:
                "silent_response_triggered"
            }
        case let .settingsChanged(gracePeriodSeconds, idleTimeoutSeconds, responseMode, alarmSound, alarmVolume, lockScreenEnabled, launchAtLoginEnabled, eventLogDetail):
            switch detail {
            case .standard:
                "settings_changed grace_period_seconds=\(gracePeriodSeconds) idle_timeout_seconds=\(idleTimeoutSeconds) response_mode=\"\(responseMode.rawValue)\" alarm_sound=\"\(alarmSound.rawValue)\" alarm_volume=\"\(alarmVolume.rawValue)\" lock_screen_enabled=\(lockScreenEnabled) launch_at_login_enabled=\(launchAtLoginEnabled) event_log_detail=\"\(eventLogDetail.rawValue)\""
            case .minimal:
                "settings_changed event_log_detail=\"\(eventLogDetail.rawValue)\""
            }
        case let .launchAtLoginChangeFailed(error):
            switch detail {
            case .standard:
                "launch_at_login_change_failed error=\"\(error)\""
            case .minimal:
                "launch_at_login_change_failed"
            }
        case let .triggerIgnored(name):
            switch detail {
            case .standard:
                "trigger_ignored name=\"\(name)\""
            case .minimal:
                "trigger_ignored"
            }
        case .logCleared:
            "log_cleared"
        }
    }
}
