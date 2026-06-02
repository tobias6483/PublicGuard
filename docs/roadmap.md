# Roadmap

## MVP

- Menu bar Arm/Disarm
- Touch ID/password protected disarm
- Charger disconnect trigger
- Wi-Fi network change trigger
- Sleep/wake trigger
- Experimental Bluetooth proximity trigger for a learned BLE device
- Idle timeout trigger
- Visible menu bar icon and active preset/status summary
- Configurable grace period before response
- Loud local alarm
- Configurable alarm sound with bundled local choices
- Configurable alarm playback volume
- Café, Library, School, and Office session presets
- Silent response mode
- Per-trigger enable/disable settings
- Notification enable/disable setting
- Optional lock screen action
- Optional launch at login setting for app bundle builds
- Local-only event log
- Minimal event log detail mode
- Optional encrypted event log storage
- Recent event preview in the menu bar
- Authenticated alarm stop with local audit logging
- Event log open and clear actions
- Local unsigned app bundle script
- GitHub Actions unsigned zipped app artifact
- App icon for local app bundles

## Next

- Complete manual hardware QA and record results
- Run the lid-close QA checklist on Apple silicon MacBook hardware
- Validate Bluetooth proximity behavior with iPhone and common BLE accessories using `docs/bluetooth-proximity-qa.md`
- Validate immediate lid-close/sleep response and wake fallback behavior against the research note
- Tune bundled alarm sound files after hardware testing
- Design opt-in privacy review for any future camera snapshot action

## Later

- Apple Watch support
- Shortcuts integration
- Opt-in camera snapshot action with explicit local-only storage controls
- Signed app release pipeline
- Notarized release pipeline
- Homebrew cask exploration
