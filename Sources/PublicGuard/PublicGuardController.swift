import AppKit
import Foundation

@MainActor
final class PublicGuardController {
    private let state = GuardState()
    private let eventLog = EventLog()
    private let authenticator = DeviceAuthenticator()
    private let alarm = AlarmPlayer()
    private let locker = ScreenLocker()
    private let notifications = NotificationAction()
    private let powerMonitor = PowerMonitor()
    private let sleepWakeMonitor = SleepWakeMonitor()

    private var statusItem: NSStatusItem?
    private var graceTask: Task<Void, Never>?

    func start() {
        eventLog.write(.appStarted)
        notifications.requestAuthorization()
        setupMenuBar()

        powerMonitor.onPowerAdapterDisconnected = { [weak self] in
            Task { @MainActor in
                self?.handleTrigger(.chargerDisconnected)
            }
        }

        sleepWakeMonitor.onWillSleep = { [weak self] in
            Task { @MainActor in
                self?.handleTrigger(.systemWillSleep)
            }
        }

        sleepWakeMonitor.onDidWake = { [weak self] in
            Task { @MainActor in
                self?.handleTrigger(.systemDidWake)
            }
        }

        powerMonitor.start()
        sleepWakeMonitor.start()
    }

    func stop() {
        eventLog.write(.appStopped)
        graceTask?.cancel()
        alarm.stop()
        powerMonitor.stop()
        sleepWakeMonitor.stop()
    }

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "PublicGuard"
        item.button?.target = self
        item.button?.action = #selector(openMenu)
        statusItem = item
        rebuildMenu()
    }

    @objc private func openMenu() {
        rebuildMenu()
        statusItem?.button?.performClick(nil)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let title = NSMenuItem(title: state.isArmed ? "PublicGuard: Armed" : "PublicGuard: Disarmed", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        menu.addItem(.separator())

        if state.isArmed {
            menu.addItem(NSMenuItem(title: "Disarm...", action: #selector(disarm), keyEquivalent: "d", target: self))
        } else {
            menu.addItem(NSMenuItem(title: "Arm", action: #selector(arm), keyEquivalent: "a", target: self))
        }

        if state.isAlarmActive {
            menu.addItem(NSMenuItem(title: "Stop Alarm...", action: #selector(disarm), keyEquivalent: "s", target: self))
        }

        menu.addItem(NSMenuItem(title: "Open Event Log", action: #selector(openEventLog), keyEquivalent: "l", target: self))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PublicGuard", action: #selector(quit), keyEquivalent: "q", target: self))

        statusItem?.menu = menu
        statusItem?.button?.title = state.isArmed ? "PublicGuard On" : "PublicGuard"
    }

    @objc private func arm() {
        state.arm()
        eventLog.write(.armed)
        NotificationCenter.default.post(name: .guardStateDidChange, object: nil)
        rebuildMenu()
    }

    @objc private func disarm() {
        Task {
            let allowed = await authenticator.authenticate(reason: "Disarm PublicGuard")
            guard allowed else {
                eventLog.write(.authenticationFailed)
                return
            }

            graceTask?.cancel()
            alarm.stop()
            state.disarm()
            eventLog.write(.disarmed)
            NotificationCenter.default.post(name: .guardStateDidChange, object: nil)
            rebuildMenu()
        }
    }

    @objc private func openEventLog() {
        NSWorkspace.shared.activateFileViewerSelecting([eventLog.url])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func handleTrigger(_ trigger: GuardTrigger) {
        guard state.isArmed else { return }

        switch trigger {
        case .chargerDisconnected:
            eventLog.write(.chargerDisconnected)
            triggerAlarmAfterGracePeriod(reason: "Power adapter disconnected")
        case .systemWillSleep:
            eventLog.write(.systemWillSleep)
        case .systemDidWake:
            eventLog.write(.systemDidWake)
            triggerAlarmAfterGracePeriod(reason: "Mac woke while armed")
        }
    }

    private func triggerAlarmAfterGracePeriod(reason: String) {
        graceTask?.cancel()
        eventLog.write(.gracePeriodStarted(reason: reason, seconds: state.gracePeriodSeconds))

        graceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: state.gracePeriodSeconds)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.state.isArmed else { return }
                self.state.markAlarmActive()
                self.eventLog.write(.alarmTriggered(reason: reason))
                self.alarm.start()
                self.notifications.sendAlarmNotification(reason: reason)
                self.locker.lock()
                self.rebuildMenu()
            }
        }
    }
}

private extension NSMenuItem {
    convenience init(title: String, action: Selector?, keyEquivalent: String, target: AnyObject) {
        self.init(title: title, action: action, keyEquivalent: keyEquivalent)
        self.target = target
    }
}

extension Notification.Name {
    static let guardStateDidChange = Notification.Name("PublicGuard.guardStateDidChange")
}
