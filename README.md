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
- Sleep/wake trigger
- 5 second grace period before alarm
- Repeating local alarm sound
- Local macOS alarm notification
- Lock screen action
- Local-only event log

Planned:

- Better lid-close detection
- iPhone Bluetooth proximity trigger
- Wi-Fi/network change trigger
- Silent alert mode
- Configurable alarm sounds
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

## Event Log

The local event log is written to:

```text
~/Library/Application Support/PublicGuard/events.log
```

You can also open it from the PublicGuard menu bar menu.

## Current Technical Notes

macOS usually sleeps immediately when a MacBook lid closes. That means a process cannot reliably keep running and play an alarm while the lid is closed. The first MVP logs sleep events and reacts when the Mac wakes while armed. Better lid-close behavior is tracked as a roadmap item.

## Architecture

The app is being shaped around triggers and actions.

Triggers:

- `PowerMonitor`
- `SleepWakeMonitor`
- Future: `BluetoothProximityTrigger`
- Future: `NetworkChangeTrigger`

Actions:

- `AlarmPlayer`
- `ScreenLocker`
- `NotificationAction`
- `EventLog`
- Future: `DelayAction`

## Contributing

PublicGuard is intentionally small and modular. Good first contributions include:

- Improving trigger reliability
- Adding tests around state and logging
- Improving documentation
- Adding configurable alarm behavior
- Adding privacy-preserving proximity detection
