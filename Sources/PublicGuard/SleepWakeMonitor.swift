import AppKit

struct SleepWakeMonitorSnapshot: Equatable {
    let lastWillSleepAt: Date?
    let lastDidWakeAt: Date?
    let lastSleepDurationSeconds: TimeInterval?
    let observedSleepCount: Int
    let observedWakeCount: Int
}

@MainActor
final class SleepWakeMonitor {
    var onWillSleep: (() -> Void)?
    var onDidWake: ((TimeInterval?) -> Void)?

    private var observers: [NSObjectProtocol] = []
    private var lastWillSleepAt: Date?
    private var lastDidWakeAt: Date?
    private var lastSleepDurationSeconds: TimeInterval?
    private var observedSleepCount = 0
    private var observedWakeCount = 0

    func start() {
        let center = NSWorkspace.shared.notificationCenter

        observers.append(center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordWillSleep(at: Date())
                self?.onWillSleep?()
            }
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                let sleepDuration = self?.recordDidWake(at: Date())
                self?.onDidWake?(sleepDuration)
            }
        })
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    func snapshot() -> SleepWakeMonitorSnapshot {
        SleepWakeMonitorSnapshot(
            lastWillSleepAt: lastWillSleepAt,
            lastDidWakeAt: lastDidWakeAt,
            lastSleepDurationSeconds: lastSleepDurationSeconds,
            observedSleepCount: observedSleepCount,
            observedWakeCount: observedWakeCount
        )
    }

    @discardableResult
    func recordWillSleep(at date: Date) -> SleepWakeMonitorSnapshot {
        lastWillSleepAt = date
        observedSleepCount += 1
        return snapshot()
    }

    @discardableResult
    func recordDidWake(at date: Date) -> TimeInterval? {
        lastDidWakeAt = date
        observedWakeCount += 1

        if let lastWillSleepAt, lastWillSleepAt <= date {
            lastSleepDurationSeconds = date.timeIntervalSince(lastWillSleepAt)
        } else {
            lastSleepDurationSeconds = nil
        }

        return lastSleepDurationSeconds
    }
}
