# Privacy Policy

PublicGuard is designed as a local-first macOS menu bar security app. It should
help users protect a laptop in public spaces without creating an account, cloud
dependency, analytics trail, or hidden recording surface.

## Current Data Handling

PublicGuard currently keeps its data on the user's Mac.

It does not:

- Require an account.
- Send analytics.
- Upload event logs.
- Sync settings to a server.
- Record audio, camera images, screen contents, keystrokes, pointer movement,
  app usage, or file contents.
- Track location.

It may store locally:

- Guard settings in macOS user defaults.
- The selected preset, trigger settings, grace periods, cooldowns, alarm sound,
  alarm volume, lock screen setting, notification setting, event log mode, and
  retention setting.
- A user-confirmed Bluetooth Low Energy device identifier and display name when
  Bluetooth Proximity is configured.
- Local event log entries under `~/Library/Application Support/PublicGuard/`.

## Event Logs

Plain-text event logs are stored at:

```text
~/Library/Application Support/PublicGuard/events.log
```

Encrypted event logs are stored at:

```text
~/Library/Application Support/PublicGuard/events.log.enc
```

Encrypted event storage uses AES-GCM with a local key stored in macOS Keychain.
The encrypted file is still local to the Mac. Switching storage modes affects
new log writes; it does not migrate or delete older log files.

`Settings > Event Log Detail > Minimal` reduces new log detail by omitting SSIDs,
Bluetooth device names, detailed response reasons, and most settings values.
Existing log entries remain until the user clears or prunes them.

## Permissions

PublicGuard may request Bluetooth permission when the app bundle build is used
and Bluetooth Proximity is configured. Bluetooth Proximity is passive local BLE
scanning for a user-confirmed nearby device. It is not Bluetooth pairing, phone
ownership proof, or location tracking.

macOS notification permission may be requested by app bundle builds when
notifications are enabled.

## Release Downloads

Early PublicGuard releases are unsigned and not notarized unless the release
notes say otherwise. macOS may warn before opening them. A SHA-256 checksum can
verify downloaded ZIP bytes, but it is not a substitute for code signing,
notarization, or reviewing the source.

## Future Changes

Any future feature that adds networking, account behavior, camera access,
microphone access, cloud sync, companion devices, background services, or richer
local telemetry must be documented before release and reviewed against
[SECURITY.md](SECURITY.md).
