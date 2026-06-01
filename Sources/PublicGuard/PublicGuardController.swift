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
    private let bluetoothMonitor = BluetoothProximityMonitor()

    private var settings: GuardSettings
    private var statusItem: NSStatusItem?
    private var graceTask: Task<Void, Never>?

    init() {
        settings = settingsStore.load()
    }

    func start() {
        eventLog.write(.appStarted)
        if settings.notificationsEnabled {
            notifications.requestAuthorization()
        }
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

        bluetoothMonitor.onDeviceLearned = { [weak self] device in
            Task { @MainActor in
                self?.storeLearnedBluetoothDevice(device)
            }
        }

        bluetoothMonitor.onDeviceOutOfRange = { [weak self] device in
            Task { @MainActor in
                self?.handleTrigger(.bluetoothDeviceOutOfRange(name: device.name))
            }
        }

        powerMonitor.start()
        networkMonitor.start()
        sleepWakeMonitor.start()
        bluetoothMonitor.start(
            targetIdentifier: settings.bluetoothTargetIdentifier,
            targetName: settings.bluetoothTargetName
        )
    }

    func stop() {
        eventLog.write(.appStopped)
        graceTask?.cancel()
        alarm.stop()
        powerMonitor.stop()
        networkMonitor.stop()
        sleepWakeMonitor.stop()
        bluetoothMonitor.stop()
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
        menu.addItem(recentEventsMenuItem())
        menu.addItem(NSMenuItem(title: "Open Event Log", action: #selector(openEventLog), keyEquivalent: "l", target: self))
        menu.addItem(NSMenuItem(title: "Clear Event Log", action: #selector(clearEventLog), keyEquivalent: "", target: self))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PublicGuard", action: #selector(quit), keyEquivalent: "q", target: self))

        statusItem?.menu = menu
        let modeSuffix = settings.responseMode == .silent ? " Silent" : ""
        statusItem?.button?.title = state.isArmed ? "PublicGuard On\(modeSuffix)" : "PublicGuard"
    }

    private func settingsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let presets = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        let presetsSubmenu = NSMenu()

        for preset in GuardSettings.SessionPreset.allCases {
            let presetItem = NSMenuItem(title: preset.title, action: #selector(applyPreset(_:)), keyEquivalent: "", target: self)
            presetItem.representedObject = preset.rawValue
            presetsSubmenu.addItem(presetItem)
        }

        presets.submenu = presetsSubmenu
        submenu.addItem(presets)

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

        let alarmSound = NSMenuItem(title: "Alarm Sound", action: nil, keyEquivalent: "")
        let alarmSoundSubmenu = NSMenu()

        for sound in GuardSettings.AlarmSound.allCases {
            let soundItem = NSMenuItem(title: sound.title, action: #selector(setAlarmSound(_:)), keyEquivalent: "", target: self)
            soundItem.representedObject = sound.rawValue
            soundItem.state = settings.alarmSound == sound ? .on : .off
            alarmSoundSubmenu.addItem(soundItem)
        }

        alarmSound.submenu = alarmSoundSubmenu
        submenu.addItem(alarmSound)

        let alarmVolume = NSMenuItem(title: "Alarm Volume", action: nil, keyEquivalent: "")
        let alarmVolumeSubmenu = NSMenu()

        for volume in GuardSettings.AlarmVolume.allCases {
            let volumeItem = NSMenuItem(title: volume.title, action: #selector(setAlarmVolume(_:)), keyEquivalent: "", target: self)
            volumeItem.representedObject = volume.rawValue
            volumeItem.state = settings.alarmVolume == volume ? .on : .off
            alarmVolumeSubmenu.addItem(volumeItem)
        }

        alarmVolume.submenu = alarmVolumeSubmenu
        submenu.addItem(alarmVolume)

        let triggers = NSMenuItem(title: "Triggers", action: nil, keyEquivalent: "")
        let triggerSubmenu = NSMenu()

        for trigger in GuardSettings.TriggerKind.allCases {
            let triggerItem = NSMenuItem(title: trigger.title, action: #selector(toggleTrigger(_:)), keyEquivalent: "", target: self)
            triggerItem.representedObject = trigger.rawValue
            triggerItem.state = settings.isTriggerEnabled(trigger) ? .on : .off
            triggerSubmenu.addItem(triggerItem)
        }

        triggers.submenu = triggerSubmenu
        submenu.addItem(triggers)

        submenu.addItem(bluetoothProximityMenuItem())

        let notificationsItem = NSMenuItem(title: "Notifications", action: #selector(toggleNotifications), keyEquivalent: "", target: self)
        notificationsItem.state = settings.notificationsEnabled ? .on : .off
        submenu.addItem(notificationsItem)

        let lockScreenItem = NSMenuItem(title: "Lock Screen", action: #selector(toggleLockScreen), keyEquivalent: "", target: self)
        lockScreenItem.state = settings.lockScreenEnabled ? .on : .off
        submenu.addItem(lockScreenItem)

        item.submenu = submenu
        return item
    }

    private func recentEventsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Recent Events", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let entries = eventLog.recentEntries()

        if entries.isEmpty {
            let emptyItem = NSMenuItem(title: "No events yet", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            for entry in entries.reversed() {
                let eventItem = NSMenuItem(title: entry, action: nil, keyEquivalent: "")
                eventItem.isEnabled = false
                submenu.addItem(eventItem)
            }
        }

        item.submenu = submenu
        return item
    }

    private func bluetoothProximityMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Bluetooth Proximity", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let targetTitle: String
        if let name = settings.bluetoothTargetName {
            targetTitle = "Learned Device: \(name)"
        } else {
            targetTitle = "No Learned Device"
        }

        let targetItem = NSMenuItem(title: targetTitle, action: nil, keyEquivalent: "")
        targetItem.isEnabled = false
        submenu.addItem(targetItem)
        submenu.addItem(NSMenuItem(title: "Learn Nearby Device", action: #selector(learnBluetoothDevice), keyEquivalent: "", target: self))

        let clearItem = NSMenuItem(title: "Clear Learned Device", action: #selector(clearBluetoothDevice), keyEquivalent: "", target: self)
        clearItem.isEnabled = settings.bluetoothTargetIdentifier != nil
        submenu.addItem(clearItem)

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
            let wasArmed = state.isArmed
            let wasAlarmActive = state.isAlarmActive

            if wasAlarmActive {
                alarm.stop()
                state.markAlarmInactive()
                eventLog.write(.alarmStopped)
            }

            if wasArmed {
                state.disarm()
                eventLog.write(.disarmed)
            }

            NotificationCenter.default.post(name: .guardStateDidChange, object: nil)
            rebuildMenu()
        }
    }

    @objc private func openEventLog() {
        NSWorkspace.shared.activateFileViewerSelecting([eventLog.url])
    }

    @objc private func clearEventLog() {
        eventLog.clear()
        eventLog.write(.logCleared)
    }

    @objc private func testResponse() {
        triggerAlarmAfterGracePeriod(reason: "Manual response test", bypassArmedCheck: true)
    }

    @objc private func learnBluetoothDevice() {
        bluetoothMonitor.learnNearbyDevice()
    }

    @objc private func clearBluetoothDevice() {
        settings.bluetoothTargetIdentifier = nil
        settings.bluetoothTargetName = nil
        settingsStore.save(settings)
        bluetoothMonitor.start(targetIdentifier: nil, targetName: nil)
        rebuildMenu()
    }

    @objc private func setGracePeriod(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }
        settings.gracePeriodSeconds = seconds
        persistSettings()
    }

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let preset = GuardSettings.SessionPreset(rawValue: rawValue)
        else {
            return
        }

        settings = preset.applied(to: settings)
        if settings.notificationsEnabled {
            notifications.requestAuthorization()
        }
        if settings.responseMode == .silent {
            alarm.stop()
        }
        persistSettings()
    }

    @objc private func toggleTrigger(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let trigger = GuardSettings.TriggerKind(rawValue: rawValue)
        else {
            return
        }

        if settings.enabledTriggers.contains(trigger) {
            settings.enabledTriggers.remove(trigger)
        } else {
            settings.enabledTriggers.insert(trigger)
        }

        persistSettings()
    }

    @objc private func toggleNotifications() {
        settings.notificationsEnabled.toggle()
        if settings.notificationsEnabled {
            notifications.requestAuthorization()
        }
        persistSettings()
    }

    @objc private func toggleLockScreen() {
        settings.lockScreenEnabled.toggle()
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

    @objc private func setAlarmSound(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let sound = GuardSettings.AlarmSound(rawValue: rawValue)
        else {
            return
        }

        settings.alarmSound = sound
        persistSettings()
    }

    @objc private func setAlarmVolume(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let volume = GuardSettings.AlarmVolume(rawValue: rawValue)
        else {
            return
        }

        settings.alarmVolume = volume
        persistSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func persistSettings() {
        settingsStore.save(settings)
        eventLog.write(.settingsChanged(
            gracePeriodSeconds: settings.gracePeriodSeconds,
            responseMode: settings.responseMode,
            alarmSound: settings.alarmSound,
            alarmVolume: settings.alarmVolume,
            lockScreenEnabled: settings.lockScreenEnabled
        ))
        rebuildMenu()
    }

    private func storeLearnedBluetoothDevice(_ device: LearnedBluetoothDevice) {
        settings.bluetoothTargetIdentifier = device.identifier.uuidString
        settings.bluetoothTargetName = device.name
        settings.enabledTriggers.insert(.bluetoothProximity)
        settingsStore.save(settings)
        eventLog.write(.bluetoothDeviceLearned(name: device.name))
        bluetoothMonitor.start(
            targetIdentifier: settings.bluetoothTargetIdentifier,
            targetName: settings.bluetoothTargetName
        )
        rebuildMenu()
    }

    private func handleTrigger(_ trigger: GuardTrigger) {
        guard state.isArmed else { return }

        switch trigger {
        case .chargerDisconnected:
            guard settings.isTriggerEnabled(.chargerDisconnect) else {
                eventLog.write(.triggerIgnored(name: GuardSettings.TriggerKind.chargerDisconnect.rawValue))
                return
            }
            eventLog.write(.chargerDisconnected)
            triggerAlarmAfterGracePeriod(reason: "Power adapter disconnected")
        case let .networkChanged(previous, current):
            guard settings.isTriggerEnabled(.networkChange) else {
                eventLog.write(.triggerIgnored(name: GuardSettings.TriggerKind.networkChange.rawValue))
                return
            }
            eventLog.write(.networkChanged(previous: previous, current: current))
            triggerAlarmAfterGracePeriod(reason: "Wi-Fi network changed")
        case let .bluetoothDeviceOutOfRange(name):
            guard settings.isTriggerEnabled(.bluetoothProximity) else {
                eventLog.write(.triggerIgnored(name: GuardSettings.TriggerKind.bluetoothProximity.rawValue))
                return
            }
            eventLog.write(.bluetoothDeviceOutOfRange(name: name))
            triggerAlarmAfterGracePeriod(reason: "Bluetooth device out of range: \(name)")
        case .systemWillSleep:
            eventLog.write(.systemWillSleep)
        case .systemDidWake:
            guard settings.isTriggerEnabled(.wakeFromSleep) else {
                eventLog.write(.triggerIgnored(name: GuardSettings.TriggerKind.wakeFromSleep.rawValue))
                return
            }
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
                    self.alarm.start(sound: self.settings.alarmSound, volume: self.settings.alarmVolume)
                } else {
                    self.eventLog.write(.silentResponseTriggered(reason: reason))
                }

                if self.settings.notificationsEnabled {
                    self.notifications.sendAlarmNotification(reason: reason)
                }
                if self.settings.lockScreenEnabled {
                    self.locker.lock()
                }
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
