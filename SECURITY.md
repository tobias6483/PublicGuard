# Security Policy

PublicGuard is security-adjacent software. Changes that affect permissions, authentication, logging, device state, lock behavior, Bluetooth, networking, camera, microphone, or background execution should be reviewed carefully.

## Principles

- Do not add hidden recording.
- Do not add covert location tracking.
- Do not send device data to a server by default.
- Prefer local-only behavior.
- Make every sensitive permission clear to the user.
- Keep sensitive actions, including screen locking, user-controlled.
- Keep alarm sound selection local; do not fetch or upload audio.
- Do not silently change global system volume; alarm volume settings should affect PublicGuard playback only.
- Keep Bluetooth proximity local-only; do not upload learned device identifiers, names, or scan history.
- Bluetooth proximity learning must require visible user confirmation before saving a scanned candidate. Do not present passive BLE scanning as Bluetooth pairing or proof of ownership.
- Cryptographic proof that a nearby device is the user's phone requires a future verified companion or pairing flow, such as an iPhone app challenge/response. CoreBluetooth proximity alone can only match a previously confirmed BLE identifier exposed to this Mac.
- Keep idle timeout local-only and user-controlled; do not log keystrokes, pointer movement, app usage, or content.
- Keep launch at login user-controlled and local to macOS login item registration.
- Keep sleep/wake instrumentation local and limited to timestamps, observation counts, and matched sleep duration.
- Keep trigger grace overrides local settings; they should tune response timing without hiding trigger audit events.
- Keep event log detail user-controlled; minimal mode should omit SSIDs, Bluetooth device names, detailed reasons, and most settings values from new log entries.
- Keep event log retention user-controlled and local. Pruning should apply only to timestamped local log entries and should not hide the fact that pruning occurred.
- Treat the `privacy-review` issue label as a maintainer routing hint, not as a substitute for manual security review.
- Do not add camera snapshot behavior until the opt-in local-only review gate in `docs/camera-snapshot-privacy-review.md` is satisfied.

## Reporting Issues

For now, open a GitHub issue with a clear description and reproduction steps.

If the project later gains users, this policy should be updated with a private vulnerability disclosure path.
