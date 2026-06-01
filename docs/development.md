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

The local bundle includes the `PublicGuard.icns` app icon and bundled alarm sounds from `Sources/PublicGuard/Resources`.

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
6. Change `Settings > Triggers` and confirm trigger checkmarks toggle.
7. Toggle `Settings > Notifications` and confirm the checkmark moves.
8. Click `Arm`.
9. Disconnect the power adapter.
10. Confirm an event is written to the log.
11. Optionally change Wi-Fi networks or disconnect Wi-Fi and confirm `network_changed` is logged when that trigger is enabled.
12. Disable a trigger and confirm the matching event is logged as `trigger_ignored`.
13. Wait for the grace period.
14. In loud mode, confirm each bundled alarm sound starts, loops until disarm, and the screen lock action runs.
15. In silent mode, confirm log/lock happen without alarm sound.
16. With notifications enabled, confirm macOS notification behavior in an app bundle build.
17. With notifications disabled, confirm no macOS notification is sent.
18. Open `Recent Events` and confirm the newest local log entries are shown first.
19. Choose `Clear Event Log` and confirm the log resets with a `log_cleared` entry.
20. Re-open the app and choose `Disarm`.
21. Confirm Touch ID/password is required.
22. Confirm alarm stops after successful authentication.

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
