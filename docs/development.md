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
3. Open `Recent Trigger Status` and confirm it shows current power, Wi-Fi, Bluetooth, idle, sleep, wake, sleep gap, observation count, and cooldown diagnostics.
4. Apply `Settings > Presets > Café` and confirm the Café preset checkmark, `Settings (Café)` title, grace period, loud mode, maximum alarm volume, notifications, lock screen, and trigger checkmarks update.
5. Apply `Settings > Presets > Library` and confirm the Library preset checkmark, `Settings (Library)` title, 15 second grace period, silent mode, normal alarm volume, notifications, lock screen, and trigger checkmarks update.
6. Apply `Settings > Presets > School` and confirm the School preset checkmark, `Settings (School)` title, 10 second grace period, loud mode, normal alarm volume, notifications, lock screen, and trigger checkmarks update.
7. Apply `Settings > Presets > Office` and confirm the Office preset checkmark, `Settings (Office)` title, 30 second grace period, silent mode, normal alarm volume, notifications, lock screen, and Wi-Fi Change unchecked.
8. Change `Settings > Grace Period` and confirm the checkmark moves.
9. Change `Settings > Trigger Cooldown` and confirm the checkmark moves.
10. Change `Settings > Trigger Grace Overrides` for Wi-Fi Change, then switch it back to `Use Default` and confirm the checkmark moves.
11. Change `Settings > Idle Timeout` and confirm the checkmark moves, including `Disabled`, `30 minutes`, and `1 hour`.
12. Change `Settings > Response Mode` and confirm the checkmark moves.
13. Change `Settings > Alarm Sound` and confirm the checkmark moves.
14. Change `Settings > Alarm Volume` and confirm the checkmark moves.
15. Change `Settings > Event Log Detail` and confirm the checkmark moves.
16. Change `Settings > Event Log Storage` to `Encrypted` and confirm the checkmark moves.
17. Trigger or change a setting, open `Recent Events`, and confirm new encrypted-storage entries are still readable in the menu.
18. Choose `Open Event Log` while encrypted storage is active and confirm Finder selects `events.log.enc`.
19. Change `Settings > Event Log Storage` back to `Plain Text` if you want readable file inspection for the rest of manual QA.
20. Change `Settings > Triggers` and confirm trigger checkmarks toggle.
21. Toggle `Settings > Notifications` and confirm the checkmark moves.
22. Toggle `Settings > Lock Screen` and confirm the checkmark moves.
23. In `dist/PublicGuard.app`, toggle `Settings > Launch at Login` and confirm the checkmark moves.
24. Confirm PublicGuard appears in macOS `System Settings > General > Login Items`.
25. Toggle `Settings > Launch at Login` off and confirm it is removed from login items.
26. Click `Arm`.
27. Open `Recent Trigger Status` and confirm Bluetooth armed baseline shows `not seen yet` until the learned target is observed after arming.
28. Disconnect the power adapter.
29. Confirm brief reconnects inside the debounce window do not write `charger_disconnected`.
30. Confirm a sustained disconnect writes `charger_disconnected` to the log.
31. Open `Recent Trigger Status` and confirm the power row now shows the adapter disconnected.
32. With `Settings > Trigger Cooldown` set to 30 seconds or more, trigger a second enabled condition during the cooldown and confirm it is logged as `trigger_ignored name="<trigger>.cooldown"`.
33. Open `Recent Trigger Status` and confirm the trigger cooldown row shows the remaining cooldown or ready state.
34. Set `Settings > Trigger Grace Overrides > Wi-Fi Change` to `30 seconds`, change Wi-Fi networks, and confirm the `grace_period_started` entry uses `seconds=30`.
35. Change Wi-Fi networks and confirm `network_changed kind="ssidChanged"` is logged when that trigger is enabled.
36. Disconnect Wi-Fi and confirm `network_changed kind="disconnected"` is logged when `Settings > Ignore Wi-Fi Disconnects` is off.
37. Turn `Settings > Ignore Wi-Fi Disconnects` on, disconnect Wi-Fi again, and confirm the event is logged as `trigger_ignored name="networkChange.disconnect"`.
38. Open `Recent Trigger Status` and confirm the Wi-Fi row reflects the current SSID or `Unknown / disconnected`.
39. Disable a trigger and confirm the matching event is logged as `trigger_ignored`.
40. Wait for the grace period.
41. In loud mode, confirm each bundled alarm sound starts, loops until disarm, and the screen lock action runs when enabled.
42. In maximum alarm volume mode, confirm alarm playback is louder without changing the Mac's global system volume.
43. With lock screen disabled, confirm alarm/log/notification behavior continues without locking the screen.
44. In silent mode, confirm log and optional lock happen without alarm sound.
45. With notifications enabled, confirm macOS notification behavior in an app bundle build.
46. With notifications disabled, confirm no macOS notification is sent.
47. Open `Recent Events` and confirm the newest local log entries are shown first.
48. Choose `Clear Event Log` and confirm the active storage log resets with a `log_cleared` entry.
49. Re-open the app and choose `Disarm`.
50. Confirm Touch ID/password is required.
51. Confirm alarm stops after successful authentication.
52. Confirm the event log records `alarm_stopped` when an active alarm is stopped.
53. Set `Settings > Event Log Detail > Minimal`, trigger Wi-Fi or Bluetooth events, and confirm new log entries omit SSIDs, Bluetooth names, and detailed response reasons.
54. Set `Settings > Idle Timeout > Disabled`, arm PublicGuard, and confirm the idle diagnostics row shows disabled rather than starting an idle response.
55. Set a positive idle timeout, leave the Mac idle past the selected threshold, and confirm `idle_timeout` is logged and the configured response starts.
56. Open `Recent Trigger Status` and confirm the idle row shows the current idle time and selected threshold.
57. In the app bundle build, grant Bluetooth permission when prompted.
58. Choose `Settings > Bluetooth Proximity > Learn Nearby Device` near the target BLE device.
59. Confirm the event log records `bluetooth_device_learned`.
60. Open `Recent Trigger Status` and confirm the Bluetooth rows show the learned device, scan state, last-seen status, armed baseline, and timeout.
61. Change `Settings > Bluetooth Proximity > Out-of-Range Timeout` and confirm the checkmark moves.
62. With PublicGuard armed and `Settings > Triggers > Bluetooth Proximity` enabled, move the learned device away or turn it off.
63. After the selected timeout, confirm `bluetooth_device_out_of_range` is logged and the configured response starts.
64. Sleep and wake the Mac, then confirm `Recent Trigger Status` shows the last observed sleep and wake notifications, the matched sleep gap, and increased sleep/wake observation counts.
65. Confirm the event log records `system_did_wake slept_seconds=...` when PublicGuard observed the preceding sleep, or `system_did_wake slept_seconds="unknown"` if the wake notification had no matched sleep observation.

Bluetooth proximity is experimental. iPhones may not advertise a stable BLE identity in every state, so record which device and macOS/iOS versions were tested.

Idle timeout uses macOS' local HID idle timer. Confirm it does not require accessibility permissions and does not log keyboard, pointer, app, or content details. `Disabled` should stop idle responses without affecting the other trigger categories.

Trigger grace overrides affect response delay only. They should not change whether the trigger event itself is logged.

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
- `didWake` is logged while armed with the matched sleep gap when available, then triggers the grace period and configured response if the lid/wake trigger is enabled and not in cooldown.

Future versions should research whether power assertions, IOKit notifications, or helper processes can improve lid-close handling without harming battery life or privacy.

See [lid-close-research.md](lid-close-research.md) for the current research note and v0.1 recommendation. Use [lid-close-qa.md](lid-close-qa.md) when recording hardware results.
