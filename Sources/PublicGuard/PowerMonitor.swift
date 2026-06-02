import Foundation
import IOKit.ps

struct PowerMonitorSnapshot: Equatable {
    let isAdapterConnected: Bool
    let pendingDisconnectStartedAt: Date?
    let disconnectDebounceSeconds: TimeInterval
}

@MainActor
final class PowerMonitor {
    var onPowerAdapterDisconnected: (() -> Void)?

    private let disconnectDebounceSeconds: TimeInterval
    private let pollInterval: TimeInterval
    private var timer: Timer?
    private var wasConnected: Bool?
    private var pendingDisconnectStartedAt: Date?

    init(disconnectDebounceSeconds: TimeInterval = 1.5, pollInterval: TimeInterval = 0.5) {
        self.disconnectDebounceSeconds = disconnectDebounceSeconds
        self.pollInterval = pollInterval
    }

    func start() {
        wasConnected = isPowerAdapterConnected()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        timer?.tolerance = 0.1
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        pendingDisconnectStartedAt = nil
    }

    func snapshot() -> PowerMonitorSnapshot {
        PowerMonitorSnapshot(
            isAdapterConnected: isPowerAdapterConnected(),
            pendingDisconnectStartedAt: pendingDisconnectStartedAt,
            disconnectDebounceSeconds: disconnectDebounceSeconds
        )
    }

    private func poll() {
        let connected = isPowerAdapterConnected()
        defer { wasConnected = connected }

        if connected {
            pendingDisconnectStartedAt = nil
            return
        }

        if wasConnected == true && connected == false {
            pendingDisconnectStartedAt = Date()
            return
        }

        guard
            let pendingDisconnectStartedAt,
            Date().timeIntervalSince(pendingDisconnectStartedAt) >= disconnectDebounceSeconds
        else {
            return
        }

        self.pendingDisconnectStartedAt = nil
        if wasConnected == false {
            onPowerAdapterDisconnected?()
        }
    }

    private func isPowerAdapterConnected() -> Bool {
        guard let info = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any] else {
            return false
        }

        return !info.isEmpty
    }
}
