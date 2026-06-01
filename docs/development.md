# Development Notes

## Build

```sh
swift build
```

## Run

```sh
swift run PublicGuard
```

The app runs as a menu bar utility and does not open a Dock icon.

SwiftPM runs the executable without a full app bundle identity. PublicGuard skips UserNotifications in that mode so local development does not crash; bundled builds can request notification permission normally.

## Build Local App Bundle

```sh
scripts/build_app.sh
open dist/PublicGuard.app
```

The generated bundle is unsigned and intended for local manual testing.

The local bundle includes the `PublicGuard.icns` app icon, bundled alarm sounds from `Sources/PublicGuard/Resources`, and a Bluetooth usage description for proximity testing.

## Test

```sh
swift test
```

## GitHub Workflow

PublicGuard is open source. External contributors can fork the repository, push a branch to their fork, and open a pull request against `main`.

Maintainers and project agents with write access should follow the detailed workflow in [../AGENTS.md](../AGENTS.md). The short version is: work on a branch, stage only relevant files, run `swift test`, use `gh` for PR creation and merge, wait for the `Swift Build and Test` check, then squash-merge and delete the branch. Do not commit or push directly to `main`.

## Manual Test Checklist

1. Launch PublicGuard.
2. Confirm it appears in the menu bar.
3. Apply `Settings > Presets > Café` and confirm grace period, loud mode, maximum alarm volume, notifications, lock screen, and trigger checkmarks update.
4. Apply `Settings > Presets > Library` and confirm 15 second grace period, silent mode, normal alarm volume, notifications, lock screen, and trigger checkmarks update.
5. Change `Settings > Grace Period` and confirm the checkmark moves.
6. Change `Settings > Response Mode` and confirm the checkmark moves.
7. Change `Settings > Alarm Sound` and confirm the checkmark moves.
8. Change `Settings > Alarm Volume` and confirm the checkmark moves.
9. Change `Settings > Triggers` and confirm trigger checkmarks toggle.
10. Toggle `Settings > Notifications` and confirm the checkmark moves.
11. Toggle `Settings > Lock Screen` and confirm the checkmark moves.
12. Click `Arm`.
13. Disconnect the power adapter.
14. Confirm an event is written to the log.
15. Optionally change Wi-Fi networks or disconnect Wi-Fi and confirm `network_changed` is logged when that trigger is enabled.
16. Disable a trigger and confirm the matching event is logged as `trigger_ignored`.
17. Wait for the grace period.
18. In loud mode, confirm each bundled alarm sound starts, loops until disarm, and the screen lock action runs when enabled.
19. In maximum alarm volume mode, confirm alarm playback is louder without changing the Mac's global system volume.
20. With lock screen disabled, confirm alarm/log/notification behavior continues without locking the screen.
21. In silent mode, confirm log and optional lock happen without alarm sound.
22. With notifications enabled, confirm macOS notification behavior in an app bundle build.
23. With notifications disabled, confirm no macOS notification is sent.
24. Open `Recent Events` and confirm the newest local log entries are shown first.
25. Choose `Clear Event Log` and confirm the log resets with a `log_cleared` entry.
26. Re-open the app and choose `Disarm`.
27. Confirm Touch ID/password is required.
28. Confirm alarm stops after successful authentication.
29. Confirm the event log records `alarm_stopped` when an active alarm is stopped.
30. In the app bundle build, grant Bluetooth permission when prompted.
31. Choose `Settings > Bluetooth Proximity > Learn Nearby Device` near the target BLE device.
32. Confirm the event log records `bluetooth_device_learned`.
33. With PublicGuard armed and `Settings > Triggers > Bluetooth Proximity` enabled, move the learned device away or turn it off.
34. After roughly 30 seconds, confirm `bluetooth_device_out_of_range` is logged and the configured response starts.

Bluetooth proximity is experimental. iPhones may not advertise a stable BLE identity in every state, so record which device and macOS/iOS versions were tested.

## Log Location

```text
~/Library/Application Support/PublicGuard/events.log
```

## Known macOS Behavior

When a MacBook lid closes, macOS usually suspends regular app execution. PublicGuard currently treats sleep/wake as the practical MVP signal:

- `willSleep` is logged while armed.
- `didWake` triggers the grace period and configured response while armed.

Future versions should research whether power assertions, IOKit notifications, or helper processes can improve lid-close handling without harming battery life or privacy.

See [lid-close-research.md](lid-close-research.md) for the current research note and v0.1 recommendation.
