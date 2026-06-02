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

Launch at login registration uses macOS ServiceManagement and should be tested from `dist/PublicGuard.app`. It is disabled in `swift run PublicGuard`, because that executable does not have the app bundle identity macOS uses for login items.

## Test

```sh
swift test
```

## GitHub Workflow

PublicGuard is open source. External contributors can fork the repository, push a branch to their fork, and open a pull request against `main`.

Maintainers and project agents with write access should follow the detailed workflow in [../AGENTS.md](../AGENTS.md). The short version is: work on a branch, stage only relevant files, run `swift test`, use `gh` for PR creation and merge, wait for the `Swift Build and Test` check, then squash-merge and delete the branch. Do not commit or push directly to `main`.

## Manual Test Checklist

1. Launch PublicGuard.
2. Confirm it appears in the menu bar with the PublicGuard icon and label.
3. Apply `Settings > Presets > Café` and confirm the Café preset checkmark, `Settings (Café)` title, grace period, loud mode, maximum alarm volume, notifications, lock screen, and trigger checkmarks update.
4. Apply `Settings > Presets > Library` and confirm the Library preset checkmark, `Settings (Library)` title, 15 second grace period, silent mode, normal alarm volume, notifications, lock screen, and trigger checkmarks update.
5. Apply `Settings > Presets > School` and confirm the School preset checkmark, `Settings (School)` title, 10 second grace period, loud mode, normal alarm volume, notifications, lock screen, and trigger checkmarks update.
6. Apply `Settings > Presets > Office` and confirm the Office preset checkmark, `Settings (Office)` title, 30 second grace period, silent mode, normal alarm volume, notifications, lock screen, and Wi-Fi Change unchecked.
7. Change `Settings > Grace Period` and confirm the checkmark moves.
8. Change `Settings > Idle Timeout` and confirm the checkmark moves.
9. Change `Settings > Response Mode` and confirm the checkmark moves.
10. Change `Settings > Alarm Sound` and confirm the checkmark moves.
11. Change `Settings > Alarm Volume` and confirm the checkmark moves.
12. Change `Settings > Event Log Detail` and confirm the checkmark moves.
13. Change `Settings > Triggers` and confirm trigger checkmarks toggle.
14. Toggle `Settings > Notifications` and confirm the checkmark moves.
15. Toggle `Settings > Lock Screen` and confirm the checkmark moves.
16. In `dist/PublicGuard.app`, toggle `Settings > Launch at Login` and confirm the checkmark moves.
17. Confirm PublicGuard appears in macOS `System Settings > General > Login Items`.
18. Toggle `Settings > Launch at Login` off and confirm it is removed from login items.
19. Click `Arm`.
20. Disconnect the power adapter.
21. Confirm an event is written to the log.
22. Optionally change Wi-Fi networks or disconnect Wi-Fi and confirm `network_changed` is logged when that trigger is enabled.
23. Disable a trigger and confirm the matching event is logged as `trigger_ignored`.
24. Wait for the grace period.
25. In loud mode, confirm each bundled alarm sound starts, loops until disarm, and the screen lock action runs when enabled.
26. In maximum alarm volume mode, confirm alarm playback is louder without changing the Mac's global system volume.
27. With lock screen disabled, confirm alarm/log/notification behavior continues without locking the screen.
28. In silent mode, confirm log and optional lock happen without alarm sound.
29. With notifications enabled, confirm macOS notification behavior in an app bundle build.
30. With notifications disabled, confirm no macOS notification is sent.
31. Open `Recent Events` and confirm the newest local log entries are shown first.
32. Choose `Clear Event Log` and confirm the log resets with a `log_cleared` entry.
33. Re-open the app and choose `Disarm`.
34. Confirm Touch ID/password is required.
35. Confirm alarm stops after successful authentication.
36. Confirm the event log records `alarm_stopped` when an active alarm is stopped.
37. Set `Settings > Event Log Detail > Minimal`, trigger Wi-Fi or Bluetooth events, and confirm new log entries omit SSIDs, Bluetooth names, and detailed response reasons.
38. Arm PublicGuard, leave the Mac idle past the selected idle timeout, and confirm `idle_timeout` is logged and the configured response starts.
39. In the app bundle build, grant Bluetooth permission when prompted.
40. Choose `Settings > Bluetooth Proximity > Learn Nearby Device` near the target BLE device.
41. Confirm the event log records `bluetooth_device_learned`.
42. With PublicGuard armed and `Settings > Triggers > Bluetooth Proximity` enabled, move the learned device away or turn it off.
43. After roughly 30 seconds, confirm `bluetooth_device_out_of_range` is logged and the configured response starts.

Bluetooth proximity is experimental. iPhones may not advertise a stable BLE identity in every state, so record which device and macOS/iOS versions were tested.

Idle timeout uses macOS' local HID idle timer. Confirm it does not require accessibility permissions and does not log keyboard, pointer, app, or content details.

Minimal event log detail affects new log entries only. Existing standard-detail log lines remain until the event log is cleared.

## Log Location

```text
~/Library/Application Support/PublicGuard/events.log
```

## Known macOS Behavior

When a MacBook lid closes, macOS usually suspends regular app execution. PublicGuard treats sleep/wake as the practical MVP signal:

- `willSleep` is logged while armed and starts the configured response immediately when macOS gives PublicGuard time to run before suspension.
- `didWake` triggers the grace period and configured response while armed.

Future versions should research whether power assertions, IOKit notifications, or helper processes can improve lid-close handling without harming battery life or privacy.

See [lid-close-research.md](lid-close-research.md) for the current research note and v0.1 recommendation. Use [lid-close-qa.md](lid-close-qa.md) when recording hardware results.
