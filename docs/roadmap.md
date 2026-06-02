# Roadmap

## MVP

- Menu bar Arm/Disarm
- Touch ID/password protected disarm
- Charger disconnect trigger
- Wi-Fi network change trigger
- Sleep/wake trigger
- Experimental Bluetooth proximity trigger for a learned BLE device
- Idle timeout trigger
- Configurable idle timeout with disabled and longer-session options
- Visible menu bar icon and active preset/status summary
- Configurable grace period before response
- Per-trigger grace period overrides for trigger tuning
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
- Recent trigger diagnostics with sleep/wake observation counters
- Authenticated alarm stop with local audit logging
- Event log open and clear actions
- Local unsigned app bundle script
- Bundle validation script
- GitHub Actions unsigned zipped app artifact with SHA-256 checksum
- GitHub Actions issue triage labels for maintainer routing
- App icon for local app bundles

## Next

- Complete manual hardware QA and record results in `docs/hardware-qa-results.md`
- Prepare v0.1 release using `docs/v0.1-release-checklist.md`
- Update `docs/v0.1-release-notes.md` with actual hardware QA results before tagging
- Run the lid-close QA checklist on Apple silicon MacBook hardware and record the observed sleep/wake counts plus sleep gap
- Validate Bluetooth proximity behavior with iPhone and common BLE accessories using `docs/bluetooth-proximity-qa.md`
- Validate immediate lid-close/sleep response and wake fallback behavior against the research note
- Tune bundled alarm sound files after hardware testing
- Capture README screenshots or GIFs after manual app bundle QA
- Keep camera snapshot out of scope unless the privacy review gate is completed

## Later

- Apple Watch support
- Shortcuts integration
- Verified iPhone companion or pairing flow for cryptographic phone ownership checks, such as challenge/response, if PublicGuard needs stronger assurance than passive CoreBluetooth proximity
- Opt-in camera snapshot action only after `docs/camera-snapshot-privacy-review.md` is satisfied
- Signed app release pipeline
- Notarized release pipeline
- Homebrew cask exploration
