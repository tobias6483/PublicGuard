import Foundation
import CryptoKit
import Security

protocol EventLogKeyProviding {
    func key() throws -> SymmetricKey
}

enum EventLogEncryptionError: Error {
    case invalidStoredKey
    case keychainReadFailed(OSStatus)
    case keychainWriteFailed(OSStatus)
}

struct KeychainEventLogKeyProvider: EventLogKeyProviding {
    private let service = "dev.publicguard.PublicGuard"
    private let account = "event-log-encryption-key"

    func key() throws -> SymmetricKey {
        if let storedKey = try readStoredKey() {
            return storedKey
        }

        let key = SymmetricKey(size: .bits256)
        let didStoreKey = try store(key)
        if didStoreKey {
            return key
        }
        if let storedKey = try readStoredKey() {
            return storedKey
        }

        throw EventLogEncryptionError.invalidStoredKey
    }

    private func readStoredKey() throws -> SymmetricKey? {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw EventLogEncryptionError.keychainReadFailed(status)
        }
        guard let data = result as? Data, data.count == 32 else {
            throw EventLogEncryptionError.invalidStoredKey
        }

        return SymmetricKey(data: data)
    }

    private func store(_ key: SymmetricKey) throws -> Bool {
        var query = keychainQuery()
        query[kSecValueData as String] = key.data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            return false
        }
        guard status == errSecSuccess else {
            throw EventLogEncryptionError.keychainWriteFailed(status)
        }
        return true
    }

    private func keychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private extension SymmetricKey {
    var data: Data {
        withUnsafeBytes { Data($0) }
    }
}

struct EventLog {
    let url: URL
    let encryptedURL: URL

    private let keyProvider: EventLogKeyProviding

    init(url: URL? = nil, keyProvider: EventLogKeyProviding = KeychainEventLogKeyProvider()) {
        self.keyProvider = keyProvider

        if let url {
            self.url = url
            encryptedURL = url.appendingPathExtension("enc")
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            return
        }

        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PublicGuard", isDirectory: true)

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = directory.appendingPathComponent("events.log")
        encryptedURL = directory.appendingPathComponent("events.log.enc")
    }

    func write(
        _ event: GuardEvent,
        detail: GuardSettings.EventLogDetail = .standard,
        storage: GuardSettings.EventLogStorage = .plainText
    ) {
        let line = "\(Self.timestamp()) \(event.message(detail: detail))\n"
        guard let data = line.data(using: .utf8) else { return }

        switch storage {
        case .plainText:
            append(data, to: url)
        case .encrypted:
            appendEncrypted(line)
        }
    }

    func clear(storage: GuardSettings.EventLogStorage = .plainText) {
        switch storage {
        case .plainText:
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? Data().write(to: url)
        case .encrypted:
            writeEncryptedContents("")
        }
    }

    func recentEntries(limit: Int = 5, storage: GuardSettings.EventLogStorage = .plainText) -> [String] {
        guard limit > 0,
              let contents = contents(storage: storage)
        else {
            return []
        }

        return contents
            .split(separator: "\n")
            .suffix(limit)
            .map(String.init)
    }

    func url(for storage: GuardSettings.EventLogStorage) -> URL {
        switch storage {
        case .plainText:
            url
        case .encrypted:
            encryptedURL
        }
    }

    private func append(_ data: Data, to url: URL) {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

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

    private func appendEncrypted(_ line: String) {
        let currentContents = contents(storage: .encrypted) ?? ""
        writeEncryptedContents(currentContents + line)
    }

    private func contents(storage: GuardSettings.EventLogStorage) -> String? {
        switch storage {
        case .plainText:
            try? String(contentsOf: url, encoding: .utf8)
        case .encrypted:
            encryptedContents()
        }
    }

    private func encryptedContents() -> String? {
        guard let data = try? Data(contentsOf: encryptedURL), !data.isEmpty else {
            return ""
        }
        guard let key = try? keyProvider.key(),
              let sealedBox = try? AES.GCM.SealedBox(combined: data),
              let decryptedData = try? AES.GCM.open(sealedBox, using: key)
        else {
            return nil
        }

        return String(data: decryptedData, encoding: .utf8)
    }

    private func writeEncryptedContents(_ contents: String) {
        guard let data = contents.data(using: .utf8),
              let key = try? keyProvider.key(),
              let sealedBox = try? AES.GCM.seal(data, using: key),
              let encryptedData = sealedBox.combined
        else {
            return
        }

        try? FileManager.default.createDirectory(at: encryptedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? encryptedData.write(to: encryptedURL)
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
    case networkChanged(previous: String?, current: String?, kind: NetworkChangeKind)
    case bluetoothDeviceLearned(name: String)
    case bluetoothDeviceOutOfRange(name: String)
    case idleTimeout(seconds: Int)
    case systemWillSleep
    case systemDidWake(sleptSeconds: Int?)
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
        eventLogDetail: GuardSettings.EventLogDetail,
        eventLogStorage: GuardSettings.EventLogStorage,
        bluetoothProximityTimeoutSeconds: Int,
        ignoreWiFiDisconnects: Bool,
        triggerCooldownSeconds: Int
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
        case let .networkChanged(previous, current, kind):
            switch detail {
            case .standard:
                "network_changed kind=\"\(kind.rawValue)\" previous=\"\(previous ?? "none")\" current=\"\(current ?? "none")\""
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
        case let .systemDidWake(sleptSeconds):
            if let sleptSeconds {
                "system_did_wake slept_seconds=\(sleptSeconds)"
            } else {
                "system_did_wake slept_seconds=\"unknown\""
            }
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
        case let .settingsChanged(gracePeriodSeconds, idleTimeoutSeconds, responseMode, alarmSound, alarmVolume, lockScreenEnabled, launchAtLoginEnabled, eventLogDetail, eventLogStorage, bluetoothProximityTimeoutSeconds, ignoreWiFiDisconnects, triggerCooldownSeconds):
            switch detail {
            case .standard:
                "settings_changed grace_period_seconds=\(gracePeriodSeconds) idle_timeout_seconds=\(idleTimeoutSeconds) response_mode=\"\(responseMode.rawValue)\" alarm_sound=\"\(alarmSound.rawValue)\" alarm_volume=\"\(alarmVolume.rawValue)\" lock_screen_enabled=\(lockScreenEnabled) launch_at_login_enabled=\(launchAtLoginEnabled) event_log_detail=\"\(eventLogDetail.rawValue)\" event_log_storage=\"\(eventLogStorage.rawValue)\" bluetooth_proximity_timeout_seconds=\(bluetoothProximityTimeoutSeconds) ignore_wifi_disconnects=\(ignoreWiFiDisconnects) trigger_cooldown_seconds=\(triggerCooldownSeconds)"
            case .minimal:
                "settings_changed event_log_detail=\"\(eventLogDetail.rawValue)\" event_log_storage=\"\(eventLogStorage.rawValue)\" ignore_wifi_disconnects=\(ignoreWiFiDisconnects) trigger_cooldown_seconds=\(triggerCooldownSeconds)"
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
