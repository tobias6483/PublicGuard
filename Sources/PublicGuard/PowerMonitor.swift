import Foundation
import IOKit.ps

struct PowerMonitorSnapshot: Equatable {
    let isAdapterConnected: Bool
}

@MainActor
final class PowerMonitor {
    var onPowerAdapterDisconnected: (() -> Void)?

    private var timer: Timer?
    private var wasConnected: Bool?

    func start() {
        wasConnected = isPowerAdapterConnected()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func snapshot() -> PowerMonitorSnapshot {
        PowerMonitorSnapshot(isAdapterConnected: isPowerAdapterConnected())
    }

    private func poll() {
        let connected = isPowerAdapterConnected()
        defer { wasConnected = connected }

        if wasConnected == true && connected == false {
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
