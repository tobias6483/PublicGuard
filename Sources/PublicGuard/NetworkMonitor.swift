import CoreWLAN
import Foundation

enum NetworkChangeKind: String, Equatable {
    case connected
    case disconnected
    case ssidChanged

    var title: String {
        switch self {
        case .connected:
            "Connected"
        case .disconnected:
            "Disconnected"
        case .ssidChanged:
            "SSID Changed"
        }
    }
}

struct NetworkChange: Equatable {
    let previousSSID: String?
    let currentSSID: String?
    let kind: NetworkChangeKind
}

struct NetworkMonitorSnapshot: Equatable {
    let currentSSID: String?
}

@MainActor
final class NetworkMonitor: NSObject, CWEventDelegate {
    var onNetworkChanged: ((NetworkChange) -> Void)?

    private static let pollInterval: TimeInterval = 0.5

    private let wifiClient = CWWiFiClient.shared()
    private var timer: Timer?
    private var lastSSID: String?
    private var lastDeliveredChange: NetworkChange?

    override init() {
        super.init()
    }

    func start() {
        lastSSID = currentSSID()
        wifiClient.delegate = self
        try? wifiClient.startMonitoringEvent(with: .ssidDidChange)
        try? wifiClient.startMonitoringEvent(with: .bssidDidChange)
        try? wifiClient.startMonitoringEvent(with: .linkDidChange)
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        timer?.tolerance = 0.1
    }

    func stop() {
        try? wifiClient.stopMonitoringEvent(with: .ssidDidChange)
        try? wifiClient.stopMonitoringEvent(with: .bssidDidChange)
        try? wifiClient.stopMonitoringEvent(with: .linkDidChange)
        wifiClient.delegate = nil
        timer?.invalidate()
        timer = nil
        lastDeliveredChange = nil
    }

    func snapshot() -> NetworkMonitorSnapshot {
        NetworkMonitorSnapshot(currentSSID: currentSSID())
    }

    nonisolated func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in
            self.poll()
        }
    }

    nonisolated func bssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in
            self.poll()
        }
    }

    nonisolated func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in
            self.poll()
        }
    }

    nonisolated func clientConnectionInterrupted() {
        Task { @MainActor in
            self.poll()
        }
    }

    nonisolated func clientConnectionInvalidated() {
        Task { @MainActor in
            self.poll()
        }
    }

    private func poll() {
        let ssid = currentSSID()
        defer { lastSSID = ssid }

        guard ssid != lastSSID else { return }
        let change = Self.change(previous: lastSSID, current: ssid)
        guard change != lastDeliveredChange else { return }

        lastDeliveredChange = change
        onNetworkChanged?(change)
    }

    private func currentSSID() -> String? {
        CWWiFiClient.shared().interface()?.ssid()
    }

    nonisolated static func change(previous: String?, current: String?) -> NetworkChange {
        let kind: NetworkChangeKind
        switch (previous, current) {
        case (nil, .some):
            kind = .connected
        case (.some, nil):
            kind = .disconnected
        case (.some, .some):
            kind = .ssidChanged
        case (nil, nil):
            kind = .disconnected
        }

        return NetworkChange(previousSSID: previous, currentSSID: current, kind: kind)
    }
}
