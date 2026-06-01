# Changelog

## Unreleased

- Started PublicGuard as a Swift/AppKit macOS menu bar app.
- Added Arm/Disarm menu bar flow.
- Added Touch ID/password protected disarm.
- Added local event logging.
- Added charger disconnect trigger.
- Added sleep/wake trigger.
- Added grace period before alarm.
- Added repeating local alarm sound.
- Added local macOS alarm notification.
- Added lock screen action.
- Added initial unit tests for guard state and event logging.
- Added configurable grace period settings.
- Added loud alarm and silent response modes.
- Added a manual response test menu item.
- Added local unsigned `.app` bundle build script.
- Added Wi-Fi network change trigger.
- Added per-trigger enable/disable settings.
- Added notification enable/disable setting.
- Added event log clearing from the menu bar.
- Added configurable alarm sound selection with a bundled looping Apple Alarm default.
- Added a generated app icon to local `.app` bundles.
- Added Beacon Pulse and High Alert bundled alarm sounds.
- Documented lid-close behavior research and tightened MVP limitation language.
- Enabled `main` branch protection with required pull requests and the `Swift Build and Test` check.
- Added a `Recent Events` menu preview for the local event log.
- Added a `Lock Screen` setting for enabling or disabling the lock action.
- Added `alarm_stopped` audit logging for authenticated alarm stops.
- Added an experimental Bluetooth proximity trigger for a learned local BLE device.
- Added configurable alarm playback volume.
- Added Café and Library session presets.
- Added a local idle timeout trigger.
- Added an optional launch at login setting for app bundle builds.
