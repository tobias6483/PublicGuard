# Hardware QA Results

Use this file to record real-device QA for PublicGuard releases. Keep entries
factual and reproducible. If a scenario has not been run, leave it marked
`Not tested` rather than implying coverage.

## Current Summary

Automated release verification has passed, but real-device hardware scenarios
remain untested until a manual pass is recorded below.

### Automated Baseline

| Area | Status | Last tested | Notes |
| --- | --- | --- | --- |
| Automated release baseline | Pass | 2026-06-02 | `scripts/release_check.sh` passed on commit `ece37b08375ee9a8ff347c0a320c230856164c18`; 72 tests passed; `dist/PublicGuard.app` validated; local unsigned artifact and SHA-256 checksum created. |
| GitHub artifact workflow | Pass | 2026-06-02 | `App Artifact` workflow run `26817849127` passed for tag `v0.1.0`; the `v0.1.0` GitHub pre-release also has uploaded unsigned assets with GitHub asset digests. |
| Event log storage invariants | Pass | 2026-06-02 | `swift test` passed with 86 tests, including plain/encrypted storage separation, active-storage clear behavior, and active-storage prune behavior. Manual menu UX still needs real app verification below. |

### Manual Hardware Scenarios

| Area | Status | Last tested | Notes |
| --- | --- | --- | --- |
| Charger disconnect | Not tested | - | Needs real adapter test. |
| Wi-Fi change/disconnect | Not tested | - | Needs network switch and disconnect test. |
| Bluetooth proximity | Not tested | - | Needs iPhone and common BLE accessory comparison. |
| Idle timeout | Not tested | - | Needs local idle timer observation on hardware. |
| Sleep/wake open lid | Not tested | - | Needs sleep/wake observation count check. |
| Lid close/reopen | Not tested | - | Must preserve honest closed-lid limitation wording. |
| Closed-display mode | Not tested | - | Optional; requires external display, keyboard, and pointer. |
| Notifications | Not tested | - | Test from `dist/PublicGuard.app`, not `swift run`. |
| Lock screen action | Not tested | - | Confirm setting enabled and disabled. |
| Launch at login | Not tested | - | Test from `dist/PublicGuard.app`. |
| Alarm sounds and volume | Not tested | - | Confirm bundled sounds loop and app volume setting works. |
| Event log storage menu UX | Not tested | - | Automated storage invariants pass; still confirm menu switching, Finder open target, clear/prune commands, and Recent Events in `dist/PublicGuard.app`. |

## 2026-06-02 - Automated Release Baseline

Tester: Codex local automation
PublicGuard commit: `ece37b08375ee9a8ff347c0a320c230856164c18`
Build source: `scripts/release_check.sh`
macOS version: 26.4.1, build 25E253
Swift version: Apple Swift 6.2

### Summary

| Area | Result | Notes |
| --- | --- | --- |
| `swift build` | Pass | Debug build completed. |
| `swift test` | Pass | 72 tests, 0 failures. |
| `scripts/build_app.sh` | Pass | Built `dist/PublicGuard.app`. |
| `scripts/validate_app_bundle.sh` | Pass | Validated executable, Info.plist, icon, resource bundle, and bundled alarm assets. |
| Unsigned artifact dry run | Pass | Created `dist/artifacts/PublicGuard.app.zip` and checksum file. |
| GitHub `App Artifact` workflow | Pass | Run `26817849127` passed for tag `v0.1.0`; the `v0.1.0` GitHub pre-release also has uploaded unsigned release assets. |
| Event log storage invariants | Pass | Later local `swift test` run passed with 86 tests, including storage switching, active-storage clear, and active-storage prune coverage. |
| Real-device hardware QA | Not tested | Requires manual charger, Wi-Fi, Bluetooth, sleep/wake, notification, lock screen, launch-at-login, alarm, and event-log checks. |

### Evidence

- Command run: `scripts/release_check.sh`
- Local dry-run checksum:
  `508a03c4f8557756787432d6f4bf26a763b2712f84545f7681bd08917ac64104`
- GitHub workflow run: `26817849127`
- GitHub pre-release:
  <https://github.com/tobias6483/PublicGuard/releases/tag/v0.1.0>
- GitHub release asset digests:
  - `PublicGuard.app.zip`: `sha256:63c39c4296647082734abaf957a94ec618d6f87b46ad7cd5c37c07744a58bc01`
  - `PublicGuard.app.zip.sha256`: `sha256:37103f6df2fa3a9c709a1daf4f454234619baa43e5e1b0b4e9893597cdc576d9`

### Follow-Up

- Run manual hardware QA before claiming trigger or app-bundle behavior has
  been validated on real devices.

## Result Status Values

- `Pass`: The scenario matched the expected behavior.
- `Partial`: The scenario worked with limitations that should be documented.
- `Fail`: The scenario did not meet expected behavior.
- `Blocked`: The scenario could not be completed because of permissions,
  missing hardware, OS behavior, or another concrete blocker.
- `Not tested`: No real-device result has been recorded yet.

## Entry Template

Copy this section for every hardware QA pass.

```md
## YYYY-MM-DD - Device / Build

Tester:
PublicGuard commit:
Build source: dist/PublicGuard.app / swift run PublicGuard
macOS version:
Mac model and chip:
Power state: battery / power adapter
External display setup:
Relevant macOS settings:
PublicGuard settings:

### Summary

| Area | Result | Notes |
| --- | --- | --- |
| Charger disconnect | Not tested |  |
| Wi-Fi change/disconnect | Not tested |  |
| Bluetooth proximity | Not tested |  |
| Idle timeout | Not tested |  |
| Sleep/wake open lid | Not tested |  |
| Lid close/reopen | Not tested |  |
| Closed-display mode | Not tested |  |
| Notifications | Not tested |  |
| Lock screen action | Not tested |  |
| Launch at login | Not tested |  |
| Alarm sounds and volume | Not tested |  |
| Event log storage menu UX | Not tested |  |

### Evidence

- Commands run:
- Recent Trigger Status before:
- Recent Trigger Status after:
- Relevant event log lines:
- Screenshots or screen recordings:

### Follow-Up

- Bugs filed:
- Docs that need wording changes:
- Settings that need tuning:
```

## Evidence Guidance

Prefer short excerpts over full logs. Do not paste SSIDs, Bluetooth device names,
or personal paths unless they are necessary and safe to publish. When testing
minimal event log detail, confirm new log entries omit SSIDs, Bluetooth names,
detailed response reasons, and most settings values.

For lid-close testing, use [lid-close-qa.md](lid-close-qa.md). For Bluetooth
proximity testing, use [bluetooth-proximity-qa.md](bluetooth-proximity-qa.md).
