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

## Test

```sh
swift test
```

## Manual Test Checklist

1. Launch PublicGuard.
2. Confirm it appears in the menu bar.
3. Click `Arm`.
4. Disconnect the power adapter.
5. Confirm an event is written to the log.
6. Wait for the grace period.
7. Confirm alarm sound starts and the screen lock action runs.
8. Re-open the app and choose `Disarm`.
9. Confirm Touch ID/password is required.
10. Confirm alarm stops after successful authentication.

## Log Location

```text
~/Library/Application Support/PublicGuard/events.log
```

## Known macOS Behavior

When a MacBook lid closes, macOS usually suspends regular app execution. PublicGuard currently treats sleep/wake as the practical MVP signal:

- `willSleep` is logged while armed.
- `didWake` triggers the grace period and alarm while armed.

Future versions should research whether power assertions, IOKit notifications, or helper processes can improve lid-close handling without harming battery life or privacy.
