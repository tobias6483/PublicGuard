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
final class NetworkMonitor {
    var onNetworkChanged: ((NetworkChange) -> Void)?

    private var timer: Timer?
    private var lastSSID: String?

    func start() {
        lastSSID = currentSSID()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func snapshot() -> NetworkMonitorSnapshot {
        NetworkMonitorSnapshot(currentSSID: currentSSID())
    }

    private func poll() {
        let ssid = currentSSID()
        defer { lastSSID = ssid }

        guard ssid != lastSSID else { return }
        onNetworkChanged?(Self.change(previous: lastSSID, current: ssid))
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
