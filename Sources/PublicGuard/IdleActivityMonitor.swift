import Foundation
import IOKit

@MainActor
final class IdleActivityMonitor {
    var onIdleTimeout: (() -> Void)?

    private var timer: Timer?
    private var thresholdSeconds = 300
    private var wasIdlePastThreshold = false

    func start(thresholdSeconds: Int) {
        self.thresholdSeconds = thresholdSeconds
        resetBaseline()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func updateThreshold(seconds: Int) {
        thresholdSeconds = seconds
        resetBaseline()
    }

    func resetBaseline() {
        wasIdlePastThreshold = currentIdleSeconds() >= TimeInterval(thresholdSeconds)
    }

    private func poll() {
        let isIdlePastThreshold = currentIdleSeconds() >= TimeInterval(thresholdSeconds)
        defer { wasIdlePastThreshold = isIdlePastThreshold }

        guard isIdlePastThreshold, !wasIdlePastThreshold else { return }
        onIdleTimeout?()
    }

    private func currentIdleSeconds() -> TimeInterval {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != 0 else { return 0 }
        defer { IOObjectRelease(service) }

        guard
            let property = IORegistryEntryCreateCFProperty(
                service,
                "HIDIdleTime" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue(),
            let idleNanoseconds = property as? NSNumber
        else {
            return 0
        }

        return idleNanoseconds.doubleValue / 1_000_000_000
    }
}
