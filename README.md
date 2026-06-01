# PublicGuard

PublicGuard is an open-source macOS menu bar security app for people who build in public.

It helps developers, students, founders, designers, and open-source maintainers protect their laptops while working from cafés, libraries, universities, coworking spaces, and other public areas.

> Privacy-first laptop protection for public workspaces. No account, no cloud, no tracking.

## MVP Status

PublicGuard currently runs as a native Swift/AppKit menu bar app.

Implemented:

- Menu bar Arm/Disarm flow
- Touch ID/password protected disarm
- Charger disconnect trigger
- Wi-Fi network change trigger
- Sleep/wake trigger
- Experimental Bluetooth proximity trigger for a learned nearby BLE device
- Idle timeout trigger
- Configurable grace period before response
- Loud alarm and silent response modes
- Configurable alarm sound with bundled local choices and Apple Alarm default
- Configurable alarm playback volume
- Café and Library session presets
- Per-trigger enable/disable settings
- Notification enable/disable setting
- Lock screen enable/disable setting
- Launch at login setting for app bundle builds
- Manual response test from the menu bar
- Looping local alarm sound
- Touch ID/password protected alarm stop
- App icon in local app bundle builds
- Local macOS alarm notification
- Optional lock screen action
- Local-only event log
- Recent event preview from the menu bar
- Event log open and clear actions

Planned:

- Manual lid-close hardware QA and follow-up sleep/wake tuning
- Encrypted event logs
- Shortcuts and Apple Watch support

See [docs/roadmap.md](docs/roadmap.md) for the current roadmap.

## Why

People who work in public often leave a laptop unattended for small moments: grabbing coffee, walking to a counter, turning around in a lecture hall, or stepping away in a coworking space.

PublicGuard is not a tracking product. It is a local-first protection utility that reacts to suspicious physical events while the user is nearby and in control.

## Privacy Principles

- No account
- No analytics
- No cloud dependency
- No hidden recording
- No background tracking
- Local event logs only
- User-controlled triggers and actions

## Requirements

- macOS 14 or newer
- Swift 6 / Xcode 26 or newer recommended

## Repository Status

PublicGuard is in early MVP development. The current goal is to prove the core local protection loop before adding more advanced triggers.

## Build

```sh
swift build
```

## Test

```sh
swift test
```

## Run

```sh
swift run PublicGuard
```

PublicGuard appears in the macOS menu bar.

When running directly through SwiftPM, macOS notification delivery may be skipped because the process is not inside a signed app bundle. The rest of the local response loop still runs.

## Local App Bundle

```sh
scripts/build_app.sh
open dist/PublicGuard.app
```

The local bundle is unsigned, but it gives PublicGuard a real app bundle identity for more realistic manual testing. See [docs/release.md](docs/release.md).

## Event Log

The local event log is written to:

```text
~/Library/Application Support/PublicGuard/events.log
```

You can also open it from the PublicGuard menu bar menu.
The menu includes a `Recent Events` submenu with the newest local log entries for quick inspection.
Stopping an active alarm writes an `alarm_stopped` entry before any armed guard session is logged as disarmed.
The menu also includes `Clear Event Log`, which resets the local log and writes a fresh `log_cleared` entry.

## Bluetooth Proximity

PublicGuard can learn a nearby Bluetooth Low Energy device from `Settings > Bluetooth Proximity > Learn Nearby Device`. While armed, it starts the configured response if that learned device was seen and then disappears for about 30 seconds.

This is local-only and stores the CoreBluetooth device identifier and display name in macOS user defaults. The event log records learn/out-of-range events by display name. It requires Bluetooth permission in the app bundle build. iPhones do not always advertise as stable BLE peripherals, so this should be treated as experimental until manually tested with the target phone or accessory.

## Alarm Volume

`Settings > Alarm Volume` controls PublicGuard's own alarm playback volume. `Maximum` sets bundled and system alarm sounds to full app playback volume, but it does not change the Mac's global system volume.

## Session Presets

`Settings > Presets` can quickly apply local public-work profiles:

- `Café`: 5 second grace period, 5 minute idle timeout, loud response, maximum app playback volume, notifications, lock screen, and all triggers enabled.
- `Library`: 15 second grace period, 15 minute idle timeout, silent response, normal app playback volume, notifications, lock screen, and all triggers enabled.

Presets keep the selected alarm sound and learned Bluetooth device.

## Idle Timeout

`Settings > Idle Timeout` controls how long the Mac can go without local keyboard or pointer activity before PublicGuard responds while armed. It uses macOS' local HID idle timer and does not record keystrokes, pointer movement, app usage, or content.

## Launch at Login

`Settings > Launch at Login` can register the bundled PublicGuard app with macOS login items. This is local macOS behavior and does not add a helper service, cloud account, or network dependency.

The setting is only active when running `dist/PublicGuard.app`; `swift run PublicGuard` does not have the app bundle identity macOS needs for login item registration.

## Current Technical Notes

macOS usually sleeps immediately when a MacBook lid closes. That means a process cannot reliably keep running and play an alarm while the lid is closed. The first MVP logs sleep events and reacts when the Mac wakes while armed. Better lid-close behavior depends on hardware QA; see [docs/lid-close-research.md](docs/lid-close-research.md) and [docs/lid-close-qa.md](docs/lid-close-qa.md).

## Architecture

The app is being shaped around triggers and actions.

Triggers:

- `PowerMonitor`
- `NetworkMonitor`
- `SleepWakeMonitor`
- `BluetoothProximityMonitor`
- `IdleActivityMonitor`

Actions:

- `AlarmPlayer`
- `ScreenLocker`
- `NotificationAction`
- `EventLog`
- `SettingsStore`
- `LoginItemController`
- Future: `DelayAction`

## Contributing

PublicGuard is intentionally small and modular. Good first contributions include:

- Improving trigger reliability
- Adding tests around state and logging
- Improving documentation
- Adding privacy-preserving proximity detection
