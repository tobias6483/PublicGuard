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
    private let settingsStore = SettingsStore()
    private let powerMonitor = PowerMonitor()
    private let networkMonitor = NetworkMonitor()
    private let sleepWakeMonitor = SleepWakeMonitor()

    private var settings: GuardSettings
    private var statusItem: NSStatusItem?
    private var graceTask: Task<Void, Never>?

    init() {
        settings = settingsStore.load()
    }

    func start() {
        eventLog.write(.appStarted)
        notifications.requestAuthorization()
        setupMenuBar()

        powerMonitor.onPowerAdapterDisconnected = { [weak self] in
            Task { @MainActor in
                self?.handleTrigger(.chargerDisconnected)
            }
        }

        networkMonitor.onNetworkChanged = { [weak self] previous, current in
            Task { @MainActor in
                self?.handleTrigger(.networkChanged(previous: previous, current: current))
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
        networkMonitor.start()
        sleepWakeMonitor.start()
    }

    func stop() {
        eventLog.write(.appStopped)
        graceTask?.cancel()
        alarm.stop()
        powerMonitor.stop()
        networkMonitor.stop()
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

        menu.addItem(.separator())
        menu.addItem(settingsMenuItem())
        menu.addItem(NSMenuItem(title: "Test Response", action: #selector(testResponse), keyEquivalent: "t", target: self))
        menu.addItem(NSMenuItem(title: "Open Event Log", action: #selector(openEventLog), keyEquivalent: "l", target: self))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PublicGuard", action: #selector(quit), keyEquivalent: "q", target: self))

        statusItem?.menu = menu
        let modeSuffix = settings.responseMode == .silent ? " Silent" : ""
        statusItem?.button?.title = state.isArmed ? "PublicGuard On\(modeSuffix)" : "PublicGuard"
    }

    private func settingsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let gracePeriod = NSMenuItem(title: "Grace Period", action: nil, keyEquivalent: "")
        let graceSubmenu = NSMenu()

        for seconds in SettingsStore.validGracePeriods {
            let title = seconds == 0 ? "No Delay" : "\(seconds) seconds"
            let graceItem = NSMenuItem(title: title, action: #selector(setGracePeriod(_:)), keyEquivalent: "", target: self)
            graceItem.representedObject = seconds
            graceItem.state = settings.gracePeriodSeconds == seconds ? .on : .off
            graceSubmenu.addItem(graceItem)
        }

        gracePeriod.submenu = graceSubmenu
        submenu.addItem(gracePeriod)

        let responseMode = NSMenuItem(title: "Response Mode", action: nil, keyEquivalent: "")
        let responseSubmenu = NSMenu()

        for mode in GuardSettings.ResponseMode.allCases {
            let modeItem = NSMenuItem(title: mode.title, action: #selector(setResponseMode(_:)), keyEquivalent: "", target: self)
            modeItem.representedObject = mode.rawValue
            modeItem.state = settings.responseMode == mode ? .on : .off
            responseSubmenu.addItem(modeItem)
        }

        responseMode.submenu = responseSubmenu
        submenu.addItem(responseMode)

        item.submenu = submenu
        return item
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

    @objc private func testResponse() {
        triggerAlarmAfterGracePeriod(reason: "Manual response test", bypassArmedCheck: true)
    }

    @objc private func setGracePeriod(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }
        settings.gracePeriodSeconds = seconds
        persistSettings()
    }

    @objc private func setResponseMode(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let mode = GuardSettings.ResponseMode(rawValue: rawValue)
        else {
            return
        }

        settings.responseMode = mode
        if mode == .silent {
            alarm.stop()
        }
        persistSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func persistSettings() {
        settingsStore.save(settings)
        eventLog.write(.settingsChanged(
            gracePeriodSeconds: settings.gracePeriodSeconds,
            responseMode: settings.responseMode
        ))
        rebuildMenu()
    }

    private func handleTrigger(_ trigger: GuardTrigger) {
        guard state.isArmed else { return }

        switch trigger {
        case .chargerDisconnected:
            eventLog.write(.chargerDisconnected)
            triggerAlarmAfterGracePeriod(reason: "Power adapter disconnected")
        case let .networkChanged(previous, current):
            eventLog.write(.networkChanged(previous: previous, current: current))
            triggerAlarmAfterGracePeriod(reason: "Wi-Fi network changed")
        case .systemWillSleep:
            eventLog.write(.systemWillSleep)
        case .systemDidWake:
            eventLog.write(.systemDidWake)
            triggerAlarmAfterGracePeriod(reason: "Mac woke while armed")
        }
    }

    private func triggerAlarmAfterGracePeriod(reason: String, bypassArmedCheck: Bool = false) {
        graceTask?.cancel()
        eventLog.write(.gracePeriodStarted(reason: reason, seconds: settings.gracePeriodDuration))

        graceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: settings.gracePeriodDuration)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard bypassArmedCheck || self.state.isArmed else { return }

                if self.settings.responseMode == .loudAlarm {
                    self.state.markAlarmActive()
                    self.eventLog.write(.alarmTriggered(reason: reason))
                    self.alarm.start()
                } else {
                    self.eventLog.write(.silentResponseTriggered(reason: reason))
                }

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
