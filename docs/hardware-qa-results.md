# Hardware QA Results

Use this file to record real-device QA for PublicGuard releases. Keep entries
factual and reproducible. If a scenario has not been run, leave it marked
`Not tested` rather than implying coverage.

## Current Summary

Automated release verification has passed on the latest `main`, but
real-device hardware scenarios remain untested until a manual pass is recorded
below.

### Automated Baseline

| Area | Status | Last tested | Notes |
| --- | --- | --- | --- |
| Automated release baseline | Pass | 2026-06-03 | `scripts/release_check.sh` passed on commit `dac30c9ee05ad80c419994d148c51562de292cd1`; 98 tests passed; `dist/PublicGuard.app` validated; local unsigned artifact and SHA-256 checksum created. |
| Automated release baseline | Pass | 2026-06-02 | `scripts/release_check.sh` passed on commit `ece37b08375ee9a8ff347c0a320c230856164c18`; 72 tests passed; `dist/PublicGuard.app` validated; local unsigned artifact and SHA-256 checksum created. |
| GitHub artifact workflow | Pass | 2026-06-02 | `App Artifact` workflow run `26817849127` passed for tag `v0.1.0`; the `v0.1.0` GitHub pre-release also has uploaded unsigned assets with GitHub asset digests. |
| Event log storage invariants | Pass | 2026-06-02 | `swift test` passed with 86 tests, including plain/encrypted storage separation, active-storage clear behavior, and active-storage prune behavior. Manual menu UX still needs real app verification below. |
| Lock screen command fallback | Pass | 2026-06-03 | Local investigation on macOS 26.4.1 confirmed the legacy `CGSession` path is missing. `swift test` passed with 89 tests after adding fallback coverage for `pmset displaysleepnow`. Manual app-bundle lock behavior still needs real-device verification below. |

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
| Lock screen action | Not tested | - | Confirm setting enabled and disabled from `dist/PublicGuard.app`; automated tests cover command fallback only. |
| Launch at login | Not tested | - | Test from `dist/PublicGuard.app`. |
| Alarm sounds and volume | Not tested | - | Confirm bundled sounds loop and app volume setting works. |
| Event log storage menu UX | Not tested | - | Automated storage invariants pass; still confirm menu switching, Finder open target, clear/prune commands, and Recent Events in `dist/PublicGuard.app`. |

## 2026-06-03 - Automated Release Baseline

Tester: Codex local automation
PublicGuard commit: `dac30c9ee05ad80c419994d148c51562de292cd1`
Build source: `scripts/release_check.sh`
macOS version: 26.4.1, build 25E253
Swift version: Apple Swift 6.2
Mac model and chip: MacBook Pro, MacBookPro17,1, Apple M1

### Summary

| Area | Result | Notes |
| --- | --- | --- |
| `swift build` | Pass | Debug build completed. |
| `swift test` | Pass | 98 tests, 0 failures. |
| `scripts/build_app.sh` | Pass | Built `dist/PublicGuard.app`. |
| `scripts/validate_app_bundle.sh` | Pass | Validated executable, Info.plist, icon, resource bundle, and bundled alarm assets. |
| Unsigned artifact dry run | Pass | Created `dist/artifacts/PublicGuard.app.zip` and checksum file. |
| Real-device hardware QA | Not tested | Requires manual charger, Wi-Fi, Bluetooth, sleep/wake, notification, lock screen, launch-at-login, alarm, and event-log menu checks from `dist/PublicGuard.app`. |

### Evidence

- Command run: `scripts/release_check.sh`
- Local dry-run checksum:
  `0e87b53abb962628e2619b36c5d52006fcb21a5bb135b390e6316816c002457d`
- Built app for manual QA:
  `dist/PublicGuard.app`

### Follow-Up

- Run the manual hardware QA pass below from `dist/PublicGuard.app`.
- Keep all unrun real-device scenarios marked `Not tested`.

## 2026-06-03 - Manual Hardware QA Pass

Tester:
PublicGuard commit: `dac30c9ee05ad80c419994d148c51562de292cd1`
Build source: `dist/PublicGuard.app`
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
| Closed-display mode | Not tested | Optional; requires external display, keyboard, and pointer. |
| Notifications | Not tested |  |
| Lock screen action | Not tested |  |
| Launch at login | Not tested |  |
| Alarm sounds and volume | Not tested |  |
| Event log storage menu UX | Not tested |  |

### Required Observations

- Recent Trigger Status before and after each trigger.
- Relevant event log lines with private SSIDs and Bluetooth names redacted.
- Whether Touch ID/password is required for disarm and alarm stop.
- Whether the top-level Protection status line matches the actual armed state,
  trigger availability, Bluetooth baseline, notification availability, and lock
  availability.
- Whether minimal event log detail omits SSIDs, Bluetooth names, and response
  reasons in new entries.
- Whether encrypted event log storage keeps plaintext details out of
  `events.log.enc`.

### Follow-Up

- Bugs filed:
- Docs that need wording changes:
- Settings that need tuning:

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
| Lock screen command fallback | Pass | Later local `swift test` run passed with 89 tests after confirming the legacy `CGSession` path is missing on macOS 26.4.1 and adding fallback coverage for `pmset displaysleepnow`. |
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
- Run a real app-bundle lock screen check with `Settings > Lock Screen` enabled
  and disabled before claiming lock behavior has been manually verified.

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
