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
3. Change `Settings > Grace Period` and confirm the checkmark moves.
4. Change `Settings > Response Mode` and confirm the checkmark moves.
5. Change `Settings > Alarm Sound` and confirm the checkmark moves.
6. Change `Settings > Alarm Volume` and confirm the checkmark moves.
7. Change `Settings > Triggers` and confirm trigger checkmarks toggle.
8. Toggle `Settings > Notifications` and confirm the checkmark moves.
9. Toggle `Settings > Lock Screen` and confirm the checkmark moves.
10. Click `Arm`.
11. Disconnect the power adapter.
12. Confirm an event is written to the log.
13. Optionally change Wi-Fi networks or disconnect Wi-Fi and confirm `network_changed` is logged when that trigger is enabled.
14. Disable a trigger and confirm the matching event is logged as `trigger_ignored`.
15. Wait for the grace period.
16. In loud mode, confirm each bundled alarm sound starts, loops until disarm, and the screen lock action runs when enabled.
17. In maximum alarm volume mode, confirm alarm playback is louder without changing the Mac's global system volume.
18. With lock screen disabled, confirm alarm/log/notification behavior continues without locking the screen.
19. In silent mode, confirm log and optional lock happen without alarm sound.
20. With notifications enabled, confirm macOS notification behavior in an app bundle build.
21. With notifications disabled, confirm no macOS notification is sent.
22. Open `Recent Events` and confirm the newest local log entries are shown first.
23. Choose `Clear Event Log` and confirm the log resets with a `log_cleared` entry.
24. Re-open the app and choose `Disarm`.
25. Confirm Touch ID/password is required.
26. Confirm alarm stops after successful authentication.
27. Confirm the event log records `alarm_stopped` when an active alarm is stopped.
28. In the app bundle build, grant Bluetooth permission when prompted.
29. Choose `Settings > Bluetooth Proximity > Learn Nearby Device` near the target BLE device.
30. Confirm the event log records `bluetooth_device_learned`.
31. With PublicGuard armed and `Settings > Triggers > Bluetooth Proximity` enabled, move the learned device away or turn it off.
32. After roughly 30 seconds, confirm `bluetooth_device_out_of_range` is logged and the configured response starts.

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
