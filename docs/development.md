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
scripts/validate_app_bundle.sh
open dist/PublicGuard.app
```

The generated bundle is unsigned and intended for local manual testing.

The local bundle includes the `PublicGuard.icns` app icon, bundled alarm sounds from `Sources/PublicGuard/Resources`, and a Bluetooth usage description for proximity testing.

`scripts/validate_app_bundle.sh` checks the generated bundle's executable,
Info.plist metadata, icon, SwiftPM resource bundle, and bundled alarm assets.

Launch at login registration uses macOS ServiceManagement and should be tested from `dist/PublicGuard.app`. It is disabled in `swift run PublicGuard`, because that executable does not have the app bundle identity macOS uses for login items.

## Test

```sh
swift test
```

If app resources, app bundle metadata, packaging, release behavior, or bundled
assets changed, also run:

```sh
scripts/build_app.sh
scripts/validate_app_bundle.sh
```

## GitHub Workflow

PublicGuard is open source. External contributors can fork the repository, push a branch to their fork, and open a pull request against `main`.

Maintainers and project agents with write access should follow the detailed workflow in [../AGENTS.md](../AGENTS.md). The short version is: work on a branch, stage only relevant files, run `swift test`, use `gh` for PR creation and merge, wait for the `Swift Build and Test` check, then squash-merge and delete the branch. Do not commit or push directly to `main`.

Issue routing is automated by `.github/workflows/issue-triage.yml`. See
[triage.md](triage.md) for label behavior and maintainer review notes.

## Manual Test Checklist

1. Launch PublicGuard.
2. Confirm it appears in the menu bar with the PublicGuard icon and label.
3. Open `Recent Trigger Status` and confirm it shows current power, Wi-Fi, Bluetooth, idle, sleep, and wake diagnostics.
4. Apply `Settings > Presets > Café` and confirm the Café preset checkmark, `Settings (Café)` title, grace period, loud mode, maximum alarm volume, notifications, lock screen, and trigger checkmarks update.
5. Apply `Settings > Presets > Library` and confirm the Library preset checkmark, `Settings (Library)` title, 15 second grace period, silent mode, normal alarm volume, notifications, lock screen, and trigger checkmarks update.
6. Apply `Settings > Presets > School` and confirm the School preset checkmark, `Settings (School)` title, 10 second grace period, loud mode, normal alarm volume, notifications, lock screen, and trigger checkmarks update.
7. Apply `Settings > Presets > Office` and confirm the Office preset checkmark, `Settings (Office)` title, 30 second grace period, silent mode, normal alarm volume, notifications, lock screen, and Wi-Fi Change unchecked.
8. Change `Settings > Grace Period` and confirm the checkmark moves.
9. Change `Settings > Idle Timeout` and confirm the checkmark moves.
10. Change `Settings > Response Mode` and confirm the checkmark moves.
11. Change `Settings > Alarm Sound` and confirm the checkmark moves.
12. Change `Settings > Alarm Volume` and confirm the checkmark moves.
13. Change `Settings > Event Log Detail` and confirm the checkmark moves.
14. Change `Settings > Event Log Storage` to `Encrypted` and confirm the checkmark moves.
15. Trigger or change a setting, open `Recent Events`, and confirm new encrypted-storage entries are still readable in the menu.
16. Choose `Open Event Log` while encrypted storage is active and confirm Finder selects `events.log.enc`.
17. Change `Settings > Event Log Storage` back to `Plain Text` if you want readable file inspection for the rest of manual QA.
18. Change `Settings > Triggers` and confirm trigger checkmarks toggle.
19. Toggle `Settings > Notifications` and confirm the checkmark moves.
20. Toggle `Settings > Lock Screen` and confirm the checkmark moves.
21. In `dist/PublicGuard.app`, toggle `Settings > Launch at Login` and confirm the checkmark moves.
22. Confirm PublicGuard appears in macOS `System Settings > General > Login Items`.
23. Toggle `Settings > Launch at Login` off and confirm it is removed from login items.
24. Click `Arm`.
25. Disconnect the power adapter.
26. Confirm an event is written to the log.
27. Open `Recent Trigger Status` and confirm the power row now shows the adapter disconnected.
28. Optionally change Wi-Fi networks or disconnect Wi-Fi and confirm `network_changed` is logged when that trigger is enabled.
29. Open `Recent Trigger Status` and confirm the Wi-Fi row reflects the current SSID or `Unknown / disconnected`.
30. Disable a trigger and confirm the matching event is logged as `trigger_ignored`.
31. Wait for the grace period.
32. In loud mode, confirm each bundled alarm sound starts, loops until disarm, and the screen lock action runs when enabled.
33. In maximum alarm volume mode, confirm alarm playback is louder without changing the Mac's global system volume.
34. With lock screen disabled, confirm alarm/log/notification behavior continues without locking the screen.
35. In silent mode, confirm log and optional lock happen without alarm sound.
36. With notifications enabled, confirm macOS notification behavior in an app bundle build.
37. With notifications disabled, confirm no macOS notification is sent.
38. Open `Recent Events` and confirm the newest local log entries are shown first.
39. Choose `Clear Event Log` and confirm the active storage log resets with a `log_cleared` entry.
40. Re-open the app and choose `Disarm`.
41. Confirm Touch ID/password is required.
42. Confirm alarm stops after successful authentication.
43. Confirm the event log records `alarm_stopped` when an active alarm is stopped.
44. Set `Settings > Event Log Detail > Minimal`, trigger Wi-Fi or Bluetooth events, and confirm new log entries omit SSIDs, Bluetooth names, and detailed response reasons.
45. Arm PublicGuard, leave the Mac idle past the selected idle timeout, and confirm `idle_timeout` is logged and the configured response starts.
46. Open `Recent Trigger Status` and confirm the idle row shows the current idle time and selected threshold.
47. In the app bundle build, grant Bluetooth permission when prompted.
48. Choose `Settings > Bluetooth Proximity > Learn Nearby Device` near the target BLE device.
49. Confirm the event log records `bluetooth_device_learned`.
50. Open `Recent Trigger Status` and confirm the Bluetooth rows show the learned device, scan state, last-seen status, and timeout.
51. Change `Settings > Bluetooth Proximity > Out-of-Range Timeout` and confirm the checkmark moves.
52. With PublicGuard armed and `Settings > Triggers > Bluetooth Proximity` enabled, move the learned device away or turn it off.
53. After the selected timeout, confirm `bluetooth_device_out_of_range` is logged and the configured response starts.
54. Sleep and wake the Mac, then confirm `Recent Trigger Status` shows the last observed sleep and wake notifications.

Bluetooth proximity is experimental. iPhones may not advertise a stable BLE identity in every state, so record which device and macOS/iOS versions were tested.

Idle timeout uses macOS' local HID idle timer. Confirm it does not require accessibility permissions and does not log keyboard, pointer, app, or content details.

Minimal event log detail affects new log entries only. Existing standard-detail log lines remain until the event log is cleared.

Encrypted event log storage affects new log writes only. Existing plain-text `events.log` entries are not migrated or deleted when encrypted storage is enabled.

## Log Location

```text
~/Library/Application Support/PublicGuard/events.log
~/Library/Application Support/PublicGuard/events.log.enc
```

## Known macOS Behavior

When a MacBook lid closes, macOS usually suspends regular app execution. PublicGuard treats sleep/wake as the practical MVP signal:

- `willSleep` is logged while armed and starts the configured response immediately when macOS gives PublicGuard time to run before suspension.
- `didWake` triggers the grace period and configured response while armed.

Future versions should research whether power assertions, IOKit notifications, or helper processes can improve lid-close handling without harming battery life or privacy.

See [lid-close-research.md](lid-close-research.md) for the current research note and v0.1 recommendation. Use [lid-close-qa.md](lid-close-qa.md) when recording hardware results.
