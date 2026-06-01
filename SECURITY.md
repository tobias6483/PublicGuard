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
- Keep idle timeout local-only; do not log keystrokes, pointer movement, app usage, or content.

## Reporting Issues

For now, open a GitHub issue with a clear description and reproduction steps.

If the project later gains users, this policy should be updated with a private vulnerability disclosure path.
