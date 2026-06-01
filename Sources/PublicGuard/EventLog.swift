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
    case systemWillSleep
    case systemDidWake
    case gracePeriodStarted(reason: String, seconds: Duration)
    case alarmTriggered(reason: String)

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
        case .systemWillSleep:
            "system_will_sleep"
        case .systemDidWake:
            "system_did_wake"
        case let .gracePeriodStarted(reason, seconds):
            "grace_period_started seconds=\(seconds.components.seconds) reason=\"\(reason)\""
        case let .alarmTriggered(reason):
            "alarm_triggered reason=\"\(reason)\""
        }
    }
}
