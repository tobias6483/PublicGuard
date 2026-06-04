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
- Visible menu bar icon and active preset/status summary
- Configurable grace period before response
- Per-trigger grace period overrides for tuning noisy signals
- Loud alarm and silent response modes
- Configurable alarm sound with bundled local choices and Apple Alarm default
- Configurable alarm playback volume
- Café, Library, School, and Office session presets
- Per-trigger enable/disable settings
- Notification enable/disable setting
- Lock screen enable/disable setting
- Launch at login setting for app bundle builds
- Event log detail setting with a minimal privacy mode
- Optional encrypted event log storage using a local Keychain-backed key
- Event log retention controls with manual pruning
- Manual response test from the menu bar
- Looping local alarm sound
- Touch ID/password protected alarm stop
- App icon in local app bundle builds
- Local macOS alarm notification
- Optional lock screen action
- Local-only event log
- Recent event preview from the menu bar
- Recent trigger diagnostics for power, Wi-Fi, Bluetooth, idle, sleep/wake, and cooldown state
- Event log open and clear actions
- GitHub Actions unsigned app artifact workflow with bundle validation and SHA-256 checksum

Planned:

- Manual hardware QA recorded in [docs/hardware-qa-results.md](docs/hardware-qa-results.md), including lid-close sleep/wake diagnostics and Bluetooth proximity behavior
- Camera snapshot remains out of scope until the privacy review gate in [docs/camera-snapshot-privacy-review.md](docs/camera-snapshot-privacy-review.md) is satisfied
- Shortcuts and Apple Watch support

See [docs/roadmap.md](docs/roadmap.md) for the current roadmap.
See [docs/requirements.md](docs/requirements.md) for the current feature coverage against the product brief.
See [docs/v0.1-release-checklist.md](docs/v0.1-release-checklist.md) for the current beta release gate.
See [docs/v0.1-release-notes.md](docs/v0.1-release-notes.md) for the current release notes draft.
See [docs/triage.md](docs/triage.md) for the GitHub issue triage labels and automation.
See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), [PRIVACY.md](PRIVACY.md), [SECURITY.md](SECURITY.md), and [SUPPORT.md](SUPPORT.md) for public user and contributor policies.

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

PublicGuard is in MVP beta development. The current goal is to harden and manually validate the local protection loop before a v0.1 release.

## Download A Release

Early PublicGuard releases are intended for technical testers. Release artifacts
are unsigned and not notarized unless the release notes say otherwise, so macOS
may warn before opening them.

1. Download `PublicGuard.app.zip` and `PublicGuard.app.zip.sha256` from the
   GitHub release.
2. Verify the ZIP checksum:

   ```sh
   shasum -a 256 -c PublicGuard.app.zip.sha256
   ```

3. Unzip the app.
4. Open PublicGuard from Finder or with:

   ```sh
   open PublicGuard.app
   ```

The checksum verifies the downloaded ZIP bytes only. It is not a code-signing
or notarization substitute. See [docs/release.md](docs/release.md) for release
artifact details and current limits.

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

## Clone And Test

For local development or fork-based testing:

```sh
git clone https://github.com/tobias6483/PublicGuard.git
cd PublicGuard
swift test
swift run PublicGuard
```

Use a branch for changes and open a pull request when ready. See
[CONTRIBUTING.md](CONTRIBUTING.md) and [docs/development.md](docs/development.md).

## Local App Bundle

```sh
scripts/build_app.sh
scripts/validate_app_bundle.sh
open dist/PublicGuard.app
```

The local bundle is unsigned, but it gives PublicGuard a real app bundle identity for more realistic manual testing. See [docs/release.md](docs/release.md).

For release dry runs, use:

```sh
scripts/release_check.sh
```

It runs build, tests, app bundle validation, and creates an unsigned zipped
artifact with a SHA-256 checksum under `dist/artifacts`.

## Event Log

By default, the local event log is written as plain text to:

```text
~/Library/Application Support/PublicGuard/events.log
```

`Settings > Event Log Storage` can switch new log writes to `Encrypted`. Encrypted logs are stored at:

```text
~/Library/Application Support/PublicGuard/events.log.enc
```

Encrypted log storage uses AES-GCM with a local key stored in macOS Keychain. `Recent Events` decrypts entries inside PublicGuard for quick inspection. Opening the encrypted event log from Finder shows the encrypted file bytes, not readable text. Switching storage modes affects new log writes; it does not migrate or delete the other log file.

You can also open it from the PublicGuard menu bar menu.
The menu includes a `Recent Events` submenu with the newest local log entries for quick inspection.
Stopping an active alarm writes an `alarm_stopped` entry before any armed guard session is logged as disarmed.
The menu also includes `Clear Event Log`, which resets the local log and writes a fresh `log_cleared` entry.

`Settings > Event Log Detail` can switch between `Standard` and `Minimal`. Minimal mode keeps event types and timing but omits SSIDs, Bluetooth device names, detailed response reasons, and most settings values from new log entries.

`Settings > Event Log Retention` can keep entries forever, for 7 days, or for 30 days. Retention applies to the active log storage mode when new events are written. The menu also includes `Prune Old Event Log Entries`, which manually applies the current retention setting and writes a `log_pruned` audit entry with the number of removed entries.

## Bluetooth Proximity

PublicGuard can scan for a nearby Bluetooth Low Energy device from `Settings > Bluetooth Proximity > Scan and Confirm Nearby Device`. It shows a confirmation dialog with the candidate name and CoreBluetooth identifier prefix before saving anything. Bluetooth Proximity becomes an enabled trigger only after a device is confirmed. While armed, it starts the configured response if that confirmed device was seen and then disappears for the configured out-of-range timeout.

`Settings > Bluetooth Proximity > Out-of-Range Timeout` can be set to 15 seconds, 30 seconds, 1 minute, or 2 minutes. Shorter timeouts react faster but may be more sensitive to normal Bluetooth advertising gaps.

This is local-only and stores the confirmed CoreBluetooth device identifier and display name in macOS user defaults. Clearing the learned device also disables the Bluetooth Proximity trigger until another device is confirmed. It is not Bluetooth pairing and does not prove device ownership; keep the intended phone or accessory closest to the Mac during scanning and confirm the displayed name/identifier before saving. The event log records learn/out-of-range events by display name. It requires Bluetooth permission in the app bundle build. iPhones do not always advertise as stable BLE peripherals, so this should be treated as experimental until manually tested with the target phone or accessory. See [docs/bluetooth-proximity-qa.md](docs/bluetooth-proximity-qa.md).

## Alarm Volume

`Settings > Alarm Volume` controls PublicGuard's own alarm playback volume. `Maximum` sets bundled and system alarm sounds to full app playback volume, but it does not change the Mac's global system volume.

## Lock Screen Action

`Settings > Lock Screen` controls whether PublicGuard also asks macOS to lock
or sleep the display when a configured response starts. PublicGuard first uses
the legacy `CGSession -suspend` command when available, then falls back to
`pmset displaysleepnow` on newer macOS versions where that command is no longer
present. The fallback path is covered by unit tests, but the release hardware QA
still needs a real app-bundle pass with the setting enabled and disabled.

## Session Presets

`Settings > Presets` can quickly apply local public-work profiles:

- `Café`: no response delay, 5 minute idle timeout, loud response, maximum app playback volume, notifications, lock screen, and all configured triggers enabled.
- `Library`: 15 second grace period, 15 minute idle timeout, silent response, normal app playback volume, notifications, lock screen, and all configured triggers enabled.
- `School`: 10 second grace period, 10 minute idle timeout, loud response, normal app playback volume, notifications, lock screen, and all configured triggers enabled.
- `Office`: 30 second grace period, 10 minute idle timeout, silent response, normal app playback volume, notifications, lock screen, and charger, lid/wake, Bluetooth proximity, and idle triggers enabled. Wi-Fi change is disabled in this preset to reduce false alarms on roaming office networks.

Presets keep the selected alarm sound and learned Bluetooth device. Bluetooth Proximity is included by presets only when a learned device exists.

Trigger enable/disable choices are persisted exactly as selected. If all triggers are disabled, PublicGuard keeps that explicit zero-trigger configuration across relaunches until the user re-enables triggers or applies a preset.

## Idle Timeout

`Settings > Idle Timeout` controls how long the Mac can go without local keyboard or pointer activity before PublicGuard responds while armed. It can be disabled, or set from 1 minute up to 1 hour for quieter sessions. It uses macOS' local HID idle timer and does not record keystrokes, pointer movement, app usage, or content.

## Trigger Tuning

`Settings > Trigger Grace Overrides` can override the global grace period per trigger. This is useful when a noisy signal, such as Wi-Fi or Bluetooth proximity, should wait longer before starting the configured response while charger or sleep/wake behavior stays fast. The global grace period supports `No Delay` and a 1 second option for fast public-session tuning.

## Launch at Login

`Settings > Launch at Login` can register the bundled PublicGuard app with macOS login items. This is local macOS behavior and does not add a helper service, cloud account, or network dependency.

The setting is only active when running `dist/PublicGuard.app`; `swift run PublicGuard` does not have the app bundle identity macOS needs for login item registration.

## Current Technical Notes

When PublicGuard is armed and macOS reports that the system is about to sleep, PublicGuard immediately starts the configured response before suspension when the OS gives the app time to run. It also reacts after wake while armed. Wake log entries include the matched sleep gap when PublicGuard observed both notifications, and `Recent Trigger Status` shows sleep/wake counts for QA. macOS can still suspend regular app execution quickly when a MacBook lid closes, so alarm playback is not guaranteed to continue while the lid remains closed and the machine is actually asleep. Better lid-close behavior depends on hardware QA; see [docs/lid-close-research.md](docs/lid-close-research.md) and [docs/lid-close-qa.md](docs/lid-close-qa.md).

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

Please follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) and use the issue
templates for bugs, feature requests, and permission-sensitive privacy reviews.
