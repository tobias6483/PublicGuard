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

## Test

```sh
swift test
```

## Manual Test Checklist

1. Launch PublicGuard.
2. Confirm it appears in the menu bar.
3. Change `Settings > Grace Period` and confirm the checkmark moves.
4. Change `Settings > Response Mode` and confirm the checkmark moves.
5. Change `Settings > Triggers` and confirm trigger checkmarks toggle.
6. Click `Arm`.
7. Disconnect the power adapter.
8. Confirm an event is written to the log.
9. Optionally change Wi-Fi networks or disconnect Wi-Fi and confirm `network_changed` is logged when that trigger is enabled.
10. Disable a trigger and confirm the matching event is logged as `trigger_ignored`.
11. Wait for the grace period.
12. In loud mode, confirm alarm sound starts and the screen lock action runs.
13. In silent mode, confirm notification/log/lock happen without alarm sound.
14. Re-open the app and choose `Disarm`.
15. Confirm Touch ID/password is required.
16. Confirm alarm stops after successful authentication.

## Log Location

```text
~/Library/Application Support/PublicGuard/events.log
```

## Known macOS Behavior

When a MacBook lid closes, macOS usually suspends regular app execution. PublicGuard currently treats sleep/wake as the practical MVP signal:

- `willSleep` is logged while armed.
- `didWake` triggers the grace period and configured response while armed.

Future versions should research whether power assertions, IOKit notifications, or helper processes can improve lid-close handling without harming battery life or privacy.
