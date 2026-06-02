# Bluetooth Proximity QA

This checklist is for validating PublicGuard's experimental Bluetooth proximity trigger with real devices.

## Record Before Testing

- PublicGuard build source: `swift run PublicGuard` or `dist/PublicGuard.app`.
- macOS version and Mac model.
- Target device type, OS version, and Bluetooth state.
- Selected `Settings > Bluetooth Proximity > Out-of-Range Timeout` value.
- Whether the Mac is on battery or power adapter.
- Whether the target device is locked, unlocked, screen-on, screen-off, or in low power mode.

Record final results in [hardware-qa-results.md](hardware-qa-results.md), with
separate notes for iPhone and non-phone BLE accessory behavior when possible.

## Learn Flow

1. Open `dist/PublicGuard.app`.
2. Grant Bluetooth permission when prompted.
3. Keep the target device near the Mac.
4. Choose `Settings > Bluetooth Proximity > Scan and Confirm Nearby Device`.
5. Confirm PublicGuard shows a candidate name and identifier prefix before saving.
6. Cancel once and confirm the previous learned device remains unchanged.
7. Scan again with the intended target closest to the Mac, then choose `Use This Device`.
8. Confirm `bluetooth_device_learned` is written to the active event log.
9. Confirm the menu shows the learned device name and identifier prefix.
10. Confirm `Settings > Triggers > Bluetooth Proximity` is enabled after learning.

## Clear Flow

1. Choose `Settings > Bluetooth Proximity > Clear Learned Device`.
2. Confirm the menu shows no learned Bluetooth device.
3. Confirm `Settings > Triggers > Bluetooth Proximity` is disabled or unavailable.
4. Apply a preset before learning another device and confirm Bluetooth Proximity remains disabled.

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
- The app does not save a newly scanned candidate until the user confirms it.
- Bluetooth Proximity is not enabled when no learned device exists.
- PublicGuard only triggers after the learned device has been seen at least once in the current session.
- The selected out-of-range timeout changes the approximate response timing.
- The event log does not record Bluetooth advertisements from unrelated devices.

## Known Limits

This is not Bluetooth pairing. PublicGuard watches for the confirmed CoreBluetooth identifier that macOS exposes to this app. CoreBluetooth proximity alone can only say that the previously confirmed BLE identifier is currently visible to this Mac. Cryptographic proof that the device is the user's phone requires a future verified companion or pairing flow, such as an iPhone app challenge/response.

iPhones and some accessories may not advertise a stable BLE identity in every state. If a phone is unreliable, test a common BLE accessory as a comparison point and keep the feature marked experimental until behavior is validated across devices.
