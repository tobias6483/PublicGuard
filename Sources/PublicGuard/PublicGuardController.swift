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
    private let idleMonitor = IdleActivityMonitor()
    private let loginItemController = LoginItemController()

    private var settings: GuardSettings
    private var statusItem: NSStatusItem?
    private var graceTask: Task<Void, Never>?

    init() {
        settings = settingsStore.load()
    }

    func start() {
        writeEvent(.appStarted)
        if settings.notificationsEnabled {
            notifications.requestAuthorization()
        }
        setupMenuBar()

        powerMonitor.onPowerAdapterDisconnected = { [weak self] in
            Task { @MainActor in
                self?.handleTrigger(.chargerDisconnected)
            }
        }

        networkMonitor.onNetworkChanged = { [weak self] change in
            Task { @MainActor in
                self?.handleTrigger(.networkChanged(change))
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

        idleMonitor.onIdleTimeout = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.handleTrigger(.idleTimeout(seconds: self.settings.idleTimeoutSeconds))
            }
        }

        powerMonitor.start()
        networkMonitor.start()
        sleepWakeMonitor.start()
        bluetoothMonitor.updateLostAfterSeconds(settings.bluetoothProximityTimeoutSeconds)
        bluetoothMonitor.start(
            targetIdentifier: settings.bluetoothTargetIdentifier,
            targetName: settings.bluetoothTargetName
        )
        idleMonitor.start(thresholdSeconds: settings.idleTimeoutSeconds)
    }

    func stop() {
        writeEvent(.appStopped)
        graceTask?.cancel()
        alarm.stop()
        powerMonitor.stop()
        networkMonitor.stop()
        sleepWakeMonitor.stop()
        bluetoothMonitor.stop()
        idleMonitor.stop()
    }

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusButton(item.button)
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
        menu.addItem(triggerDiagnosticsMenuItem())
        menu.addItem(recentEventsMenuItem())
        menu.addItem(NSMenuItem(title: "Open Event Log", action: #selector(openEventLog), keyEquivalent: "l", target: self))
        menu.addItem(NSMenuItem(title: "Clear Event Log", action: #selector(clearEventLog), keyEquivalent: "", target: self))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PublicGuard", action: #selector(quit), keyEquivalent: "q", target: self))

        statusItem?.menu = menu
        let modeSuffix = settings.responseMode == .silent ? " Silent" : ""
        statusItem?.button?.title = state.isArmed ? "PublicGuard On\(modeSuffix)" : "PublicGuard"
        statusItem?.button?.toolTip = state.isArmed ? "PublicGuard armed" : "PublicGuard disarmed"
    }

    private func settingsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Settings \(currentPresetSummary())", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let currentSettings = NSMenuItem(title: currentSettingsSummary(), action: nil, keyEquivalent: "")
        currentSettings.isEnabled = false
        submenu.addItem(currentSettings)
        submenu.addItem(.separator())

        let presets = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        let presetsSubmenu = NSMenu()

        for preset in GuardSettings.SessionPreset.allCases {
            let presetItem = NSMenuItem(title: preset.title, action: #selector(applyPreset(_:)), keyEquivalent: "", target: self)
            presetItem.representedObject = preset.rawValue
            presetItem.state = preset.matches(settings) ? .on : .off
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

        let idleTimeout = NSMenuItem(title: "Idle Timeout", action: nil, keyEquivalent: "")
        let idleTimeoutSubmenu = NSMenu()

        for seconds in SettingsStore.validIdleTimeouts {
            let idleItem = NSMenuItem(title: Self.idleTimeoutTitle(seconds: seconds), action: #selector(setIdleTimeout(_:)), keyEquivalent: "", target: self)
            idleItem.representedObject = seconds
            idleItem.state = settings.idleTimeoutSeconds == seconds ? .on : .off
            idleTimeoutSubmenu.addItem(idleItem)
        }

        idleTimeout.submenu = idleTimeoutSubmenu
        submenu.addItem(idleTimeout)

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

        let eventLogDetail = NSMenuItem(title: "Event Log Detail", action: nil, keyEquivalent: "")
        let eventLogDetailSubmenu = NSMenu()

        for detail in GuardSettings.EventLogDetail.allCases {
            let detailItem = NSMenuItem(title: detail.title, action: #selector(setEventLogDetail(_:)), keyEquivalent: "", target: self)
            detailItem.representedObject = detail.rawValue
            detailItem.state = settings.eventLogDetail == detail ? .on : .off
            eventLogDetailSubmenu.addItem(detailItem)
        }

        eventLogDetail.submenu = eventLogDetailSubmenu
        submenu.addItem(eventLogDetail)

        let eventLogStorage = NSMenuItem(title: "Event Log Storage", action: nil, keyEquivalent: "")
        let eventLogStorageSubmenu = NSMenu()

        for storage in GuardSettings.EventLogStorage.allCases {
            let storageItem = NSMenuItem(title: storage.title, action: #selector(setEventLogStorage(_:)), keyEquivalent: "", target: self)
            storageItem.representedObject = storage.rawValue
            storageItem.state = settings.eventLogStorage == storage ? .on : .off
            eventLogStorageSubmenu.addItem(storageItem)
        }

        eventLogStorage.submenu = eventLogStorageSubmenu
        submenu.addItem(eventLogStorage)

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

        let ignoreWiFiDisconnectsItem = NSMenuItem(title: "Ignore Wi-Fi Disconnects", action: #selector(toggleIgnoreWiFiDisconnects), keyEquivalent: "", target: self)
        ignoreWiFiDisconnectsItem.state = settings.ignoreWiFiDisconnects ? .on : .off
        submenu.addItem(ignoreWiFiDisconnectsItem)

        submenu.addItem(bluetoothProximityMenuItem())

        let notificationsItem = NSMenuItem(title: "Notifications", action: #selector(toggleNotifications), keyEquivalent: "", target: self)
        notificationsItem.state = settings.notificationsEnabled ? .on : .off
        submenu.addItem(notificationsItem)

        let lockScreenItem = NSMenuItem(title: "Lock Screen", action: #selector(toggleLockScreen), keyEquivalent: "", target: self)
        lockScreenItem.state = settings.lockScreenEnabled ? .on : .off
        submenu.addItem(lockScreenItem)

        let launchAtLoginTitle = loginItemController.canManageLaunchAtLogin ? "Launch at Login" : "Launch at Login (App Bundle Only)"
        let launchAtLoginItem = NSMenuItem(title: launchAtLoginTitle, action: #selector(toggleLaunchAtLogin), keyEquivalent: "", target: self)
        launchAtLoginItem.state = settings.launchAtLoginEnabled ? .on : .off
        launchAtLoginItem.isEnabled = loginItemController.canManageLaunchAtLogin
        submenu.addItem(launchAtLoginItem)

        item.submenu = submenu
        return item
    }

    private func triggerDiagnosticsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Recent Trigger Status", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let powerSnapshot = powerMonitor.snapshot()
        let powerTitle: String
        if powerSnapshot.isAdapterConnected {
            powerTitle = "Power: adapter connected"
        } else if let pendingDisconnectStartedAt = powerSnapshot.pendingDisconnectStartedAt {
            powerTitle = "Power: adapter disconnected, debouncing for \(Self.durationTitle(seconds: powerSnapshot.disconnectDebounceSeconds - Date().timeIntervalSince(pendingDisconnectStartedAt)))"
        } else {
            powerTitle = "Power: adapter disconnected"
        }
        submenu.addItem(Self.disabledMenuItem(
            title: powerTitle
        ))

        let networkSnapshot = networkMonitor.snapshot()
        submenu.addItem(Self.disabledMenuItem(
            title: "Wi-Fi: \(networkSnapshot.currentSSID ?? "Unknown / disconnected")"
        ))
        submenu.addItem(Self.disabledMenuItem(
            title: "Wi-Fi disconnect policy: \(settings.ignoreWiFiDisconnects ? "ignored" : "triggers")"
        ))

        let bluetoothSnapshot = bluetoothMonitor.snapshot()
        submenu.addItem(Self.disabledMenuItem(
            title: "Bluetooth device: \(Self.bluetoothDeviceTitle(bluetoothSnapshot.learnedDevice))"
        ))
        submenu.addItem(Self.disabledMenuItem(
            title: "Bluetooth last seen: \(Self.relativeDateTitle(bluetoothSnapshot.lastSeenTargetAt))"
        ))
        submenu.addItem(Self.disabledMenuItem(
            title: "Bluetooth timeout: \(Self.bluetoothTimeoutTitle(seconds: Int(bluetoothSnapshot.lostAfterSeconds)))"
        ))
        submenu.addItem(Self.disabledMenuItem(
            title: "Bluetooth scan: \(Self.bluetoothScanStateTitle(bluetoothSnapshot.scanState))"
        ))
        submenu.addItem(Self.disabledMenuItem(
            title: "Bluetooth armed baseline: \(bluetoothSnapshot.hasSeenTarget ? "seen target" : "not seen yet")"
        ))
        if bluetoothSnapshot.hasReportedCurrentLoss {
            submenu.addItem(Self.disabledMenuItem(title: "Bluetooth loss: already reported"))
        }

        let idleSnapshot = idleMonitor.snapshot()
        submenu.addItem(Self.disabledMenuItem(
            title: "Idle: \(Self.durationTitle(seconds: idleSnapshot.currentIdleSeconds)) / \(Self.idleTimeoutTitle(seconds: idleSnapshot.thresholdSeconds))"
        ))

        let sleepWakeSnapshot = sleepWakeMonitor.snapshot()
        submenu.addItem(Self.disabledMenuItem(
            title: "Sleep: \(Self.relativeDateTitle(sleepWakeSnapshot.lastWillSleepAt))"
        ))
        submenu.addItem(Self.disabledMenuItem(
            title: "Wake: \(Self.relativeDateTitle(sleepWakeSnapshot.lastDidWakeAt))"
        ))

        item.submenu = submenu
        return item
    }

    private func recentEventsMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Recent Events", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let entries = eventLog.recentEntries(storage: settings.eventLogStorage)

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

        let timeoutItem = NSMenuItem(title: "Out-of-Range Timeout", action: nil, keyEquivalent: "")
        let timeoutSubmenu = NSMenu()

        for seconds in SettingsStore.validBluetoothProximityTimeouts {
            let item = NSMenuItem(title: Self.bluetoothTimeoutTitle(seconds: seconds), action: #selector(setBluetoothProximityTimeout(_:)), keyEquivalent: "", target: self)
            item.representedObject = seconds
            item.state = settings.bluetoothProximityTimeoutSeconds == seconds ? .on : .off
            timeoutSubmenu.addItem(item)
        }

        timeoutItem.submenu = timeoutSubmenu
        submenu.addItem(timeoutItem)

        let clearItem = NSMenuItem(title: "Clear Learned Device", action: #selector(clearBluetoothDevice), keyEquivalent: "", target: self)
        clearItem.isEnabled = settings.bluetoothTargetIdentifier != nil
        submenu.addItem(clearItem)

        item.submenu = submenu
        return item
    }

    @objc private func arm() {
        state.arm()
        idleMonitor.resetBaseline()
        writeEvent(.armed)
        NotificationCenter.default.post(name: .guardStateDidChange, object: nil)
        rebuildMenu()
    }

    @objc private func disarm() {
        Task {
            let allowed = await authenticator.authenticate(reason: "Disarm PublicGuard")
            guard allowed else {
                writeEvent(.authenticationFailed)
                return
            }

            graceTask?.cancel()
            let wasArmed = state.isArmed
            let wasAlarmActive = state.isAlarmActive

            if wasAlarmActive {
                alarm.stop()
                state.markAlarmInactive()
                writeEvent(.alarmStopped)
            }

            if wasArmed {
                state.disarm()
                writeEvent(.disarmed)
            }

            NotificationCenter.default.post(name: .guardStateDidChange, object: nil)
            rebuildMenu()
        }
    }

    @objc private func openEventLog() {
        NSWorkspace.shared.activateFileViewerSelecting([eventLog.url(for: settings.eventLogStorage)])
    }

    @objc private func clearEventLog() {
        eventLog.clear(storage: settings.eventLogStorage)
        writeEvent(.logCleared)
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

    @objc private func setBluetoothProximityTimeout(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }

        settings.bluetoothProximityTimeoutSeconds = seconds
        bluetoothMonitor.updateLostAfterSeconds(seconds)
        persistSettings()
    }

    @objc private func setGracePeriod(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }
        settings.gracePeriodSeconds = seconds
        persistSettings()
    }

    @objc private func setIdleTimeout(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }
        settings.idleTimeoutSeconds = seconds
        idleMonitor.updateThreshold(seconds: seconds)
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
        idleMonitor.updateThreshold(seconds: settings.idleTimeoutSeconds)
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

    @objc private func toggleIgnoreWiFiDisconnects() {
        settings.ignoreWiFiDisconnects.toggle()
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

    @objc private func toggleLaunchAtLogin() {
        let enabled = !settings.launchAtLoginEnabled

        do {
            try loginItemController.setLaunchAtLoginEnabled(enabled)
            settings.launchAtLoginEnabled = enabled
            persistSettings()
        } catch {
            writeEvent(.launchAtLoginChangeFailed(error: String(describing: error)))
            rebuildMenu()
        }
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

    @objc private func setEventLogDetail(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let detail = GuardSettings.EventLogDetail(rawValue: rawValue)
        else {
            return
        }

        settings.eventLogDetail = detail
        persistSettings()
    }

    @objc private func setEventLogStorage(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let storage = GuardSettings.EventLogStorage(rawValue: rawValue)
        else {
            return
        }

        settings.eventLogStorage = storage
        persistSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func persistSettings() {
        settingsStore.save(settings)
        writeEvent(.settingsChanged(
            gracePeriodSeconds: settings.gracePeriodSeconds,
            idleTimeoutSeconds: settings.idleTimeoutSeconds,
            responseMode: settings.responseMode,
            alarmSound: settings.alarmSound,
            alarmVolume: settings.alarmVolume,
            lockScreenEnabled: settings.lockScreenEnabled,
            launchAtLoginEnabled: settings.launchAtLoginEnabled,
            eventLogDetail: settings.eventLogDetail,
            eventLogStorage: settings.eventLogStorage,
            bluetoothProximityTimeoutSeconds: settings.bluetoothProximityTimeoutSeconds,
            ignoreWiFiDisconnects: settings.ignoreWiFiDisconnects
        ))
        rebuildMenu()
    }

    private func storeLearnedBluetoothDevice(_ device: LearnedBluetoothDevice) {
        settings.bluetoothTargetIdentifier = device.identifier.uuidString
        settings.bluetoothTargetName = device.name
        settings.enabledTriggers.insert(.bluetoothProximity)
        settingsStore.save(settings)
        writeEvent(.bluetoothDeviceLearned(name: device.name))
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
                writeEvent(.triggerIgnored(name: GuardSettings.TriggerKind.chargerDisconnect.rawValue))
                return
            }
            writeEvent(.chargerDisconnected)
            triggerAlarmAfterGracePeriod(reason: "Power adapter disconnected")
        case let .networkChanged(change):
            guard settings.isTriggerEnabled(.networkChange) else {
                writeEvent(.triggerIgnored(name: GuardSettings.TriggerKind.networkChange.rawValue))
                return
            }
            if settings.ignoreWiFiDisconnects, change.kind == .disconnected {
                writeEvent(.triggerIgnored(name: "\(GuardSettings.TriggerKind.networkChange.rawValue).disconnect"))
                return
            }
            writeEvent(.networkChanged(previous: change.previousSSID, current: change.currentSSID, kind: change.kind))
            triggerAlarmAfterGracePeriod(reason: "Wi-Fi \(change.kind.title.lowercased())")
        case let .bluetoothDeviceOutOfRange(name):
            guard settings.isTriggerEnabled(.bluetoothProximity) else {
                writeEvent(.triggerIgnored(name: GuardSettings.TriggerKind.bluetoothProximity.rawValue))
                return
            }
            writeEvent(.bluetoothDeviceOutOfRange(name: name))
            triggerAlarmAfterGracePeriod(reason: "Bluetooth device out of range: \(name)")
        case let .idleTimeout(seconds):
            guard settings.isTriggerEnabled(.idleTimeout) else {
                writeEvent(.triggerIgnored(name: GuardSettings.TriggerKind.idleTimeout.rawValue))
                return
            }
            writeEvent(.idleTimeout(seconds: seconds))
            triggerAlarmAfterGracePeriod(reason: "Mac idle for \(Self.idleTimeoutTitle(seconds: seconds))")
        case .systemWillSleep:
            writeEvent(.systemWillSleep)
            guard settings.isTriggerEnabled(.wakeFromSleep) else {
                writeEvent(.triggerIgnored(name: GuardSettings.TriggerKind.wakeFromSleep.rawValue))
                return
            }
            triggerConfiguredResponse(reason: "Mac is going to sleep while armed")
        case .systemDidWake:
            guard settings.isTriggerEnabled(.wakeFromSleep) else {
                writeEvent(.triggerIgnored(name: GuardSettings.TriggerKind.wakeFromSleep.rawValue))
                return
            }
            writeEvent(.systemDidWake)
            triggerAlarmAfterGracePeriod(reason: "Mac woke while armed")
        }
    }

    private func triggerAlarmAfterGracePeriod(reason: String, bypassArmedCheck: Bool = false) {
        graceTask?.cancel()
        writeEvent(.gracePeriodStarted(reason: reason, seconds: settings.gracePeriodDuration))

        graceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: settings.gracePeriodDuration)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard bypassArmedCheck || self.state.isArmed else { return }
                self.triggerConfiguredResponse(reason: reason)
            }
        }
    }

    private func triggerConfiguredResponse(reason: String) {
        if settings.responseMode == .loudAlarm {
            state.markAlarmActive()
            writeEvent(.alarmTriggered(reason: reason))
            alarm.start(sound: settings.alarmSound, volume: settings.alarmVolume)
        } else {
            writeEvent(.silentResponseTriggered(reason: reason))
        }

        if settings.notificationsEnabled {
            notifications.sendAlarmNotification(reason: reason)
        }
        if settings.lockScreenEnabled {
            locker.lock()
        }
        rebuildMenu()
    }

    private func writeEvent(_ event: GuardEvent) {
        eventLog.write(event, detail: settings.eventLogDetail, storage: settings.eventLogStorage)
    }
}

private extension PublicGuardController {
    func configureStatusButton(_ button: NSStatusBarButton?) {
        guard let button else { return }

        button.title = "PublicGuard"
        button.image = Self.statusIcon()
        button.imagePosition = .imageLeading
    }

    static func statusIcon() -> NSImage? {
        guard let iconURL = Bundle.module.url(forResource: "PublicGuard", withExtension: "icns"),
              let image = NSImage(contentsOf: iconURL)
        else {
            return nil
        }

        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = false
        return image
    }

    func currentPresetSummary() -> String {
        guard let preset = GuardSettings.SessionPreset.allCases.first(where: { $0.matches(settings) }) else {
            return "(Custom)"
        }

        return "(\(preset.title))"
    }

    func currentSettingsSummary() -> String {
        let enabledTriggerCount = settings.enabledTriggers.count
        let totalTriggerCount = GuardSettings.TriggerKind.allCases.count
        return "Current: \(currentPresetSummary().trimmingCharacters(in: CharacterSet(charactersIn: "()"))) | \(settings.responseMode.title), \(Self.idleTimeoutTitle(seconds: settings.idleTimeoutSeconds)), \(enabledTriggerCount)/\(totalTriggerCount) triggers"
    }

    static func idleTimeoutTitle(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        }

        let minutes = seconds / 60
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    static func bluetoothTimeoutTitle(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        }

        let minutes = seconds / 60
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    static func bluetoothDeviceTitle(_ device: LearnedBluetoothDevice?) -> String {
        guard let device else { return "None learned" }

        return "\(device.name) (\(device.identifier.uuidString.prefix(8)))"
    }

    static func bluetoothScanStateTitle(_ state: BluetoothProximityMonitorSnapshot.ScanState) -> String {
        switch state {
        case .idle, .monitoring, .unavailable:
            return state.title
        case let .learning(until):
            return "\(state.title) until \(timeFormatter.string(from: until))"
        }
    }

    static func relativeDateTitle(_ date: Date?) -> String {
        guard let date else { return "Never observed" }

        return "\(durationTitle(seconds: Date().timeIntervalSince(date))) ago at \(timeFormatter.string(from: date))"
    }

    static func durationTitle(seconds: TimeInterval) -> String {
        let roundedSeconds = max(0, Int(seconds.rounded()))

        if roundedSeconds < 60 {
            return "\(roundedSeconds) seconds"
        }

        let minutes = roundedSeconds / 60
        let secondsRemainder = roundedSeconds % 60
        if minutes < 60 {
            return secondsRemainder == 0 ? "\(minutes) minutes" : "\(minutes)m \(secondsRemainder)s"
        }

        let hours = minutes / 60
        let minutesRemainder = minutes % 60
        return minutesRemainder == 0 ? "\(hours) hours" : "\(hours)h \(minutesRemainder)m"
    }

    static func disabledMenuItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
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
