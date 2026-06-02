import AppKit

struct SleepWakeMonitorSnapshot: Equatable {
    let lastWillSleepAt: Date?
    let lastDidWakeAt: Date?
}

@MainActor
final class SleepWakeMonitor {
    var onWillSleep: (() -> Void)?
    var onDidWake: (() -> Void)?

    private var observers: [NSObjectProtocol] = []
    private var lastWillSleepAt: Date?
    private var lastDidWakeAt: Date?

    func start() {
        let center = NSWorkspace.shared.notificationCenter

        observers.append(center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.lastWillSleepAt = Date()
                self?.onWillSleep?()
            }
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.lastDidWakeAt = Date()
                self?.onDidWake?()
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
            lastDidWakeAt: lastDidWakeAt
        )
    }
}
