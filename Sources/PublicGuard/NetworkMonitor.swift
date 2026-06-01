import CoreWLAN
import Foundation

@MainActor
final class NetworkMonitor {
    var onNetworkChanged: ((_ previous: String?, _ current: String?) -> Void)?

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

    private func poll() {
        let ssid = currentSSID()
        defer { lastSSID = ssid }

        guard ssid != lastSSID else { return }
        onNetworkChanged?(lastSSID, ssid)
    }

    private func currentSSID() -> String? {
        CWWiFiClient.shared().interface()?.ssid()
    }
}
