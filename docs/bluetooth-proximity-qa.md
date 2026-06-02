# Bluetooth Proximity QA

This checklist is for validating PublicGuard's experimental Bluetooth proximity trigger with real devices.

## Record Before Testing

- PublicGuard build source: `swift run PublicGuard` or `dist/PublicGuard.app`.
- macOS version and Mac model.
- Target device type, OS version, and Bluetooth state.
- Selected `Settings > Bluetooth Proximity > Out-of-Range Timeout` value.
- Whether the Mac is on battery or power adapter.
- Whether the target device is locked, unlocked, screen-on, screen-off, or in low power mode.

## Learn Flow

1. Open `dist/PublicGuard.app`.
2. Grant Bluetooth permission when prompted.
3. Keep the target device near the Mac.
4. Choose `Settings > Bluetooth Proximity > Learn Nearby Device`.
5. Confirm `bluetooth_device_learned` is written to the active event log.
6. Confirm the menu shows the learned device name.

## Out-Of-Range Flow

1. Set `Settings > Bluetooth Proximity > Out-of-Range Timeout` to `30 seconds`.
2. Confirm `Settings > Triggers > Bluetooth Proximity` is enabled.
3. Arm PublicGuard.
4. Move the learned device away, turn off Bluetooth on it, or place it where the Mac no longer sees advertisements.
5. Wait for the selected timeout.
6. Confirm `bluetooth_device_out_of_range` is written to the active event log.
7. Confirm the configured response starts.

## Timeout Tuning

Repeat the out-of-range flow with:

- `15 seconds` for fast response.
- `1 minute` for a more tolerant public workspace setting.
- `2 minutes` for noisy Bluetooth environments.

Record false positives, missed events, and approximate time to response for each value.

## Pass Criteria

- The learned device is recorded locally.
- PublicGuard only triggers after the learned device has been seen at least once in the current session.
- The selected out-of-range timeout changes the approximate response timing.
- The event log does not record Bluetooth advertisements from unrelated devices.

## Known Limits

iPhones and some accessories may not advertise a stable BLE identity in every state. If a phone is unreliable, test a common BLE accessory as a comparison point and keep the feature marked experimental until behavior is validated across devices.

