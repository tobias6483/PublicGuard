# Hardware QA Results

Use this file to record real-device QA for PublicGuard releases. Keep entries
factual and reproducible. If a scenario has not been run, leave it marked
`Not tested` rather than implying coverage.

## Current Summary

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
| Event log storage | Not tested | - | Confirm plain text, encrypted, clear, open, and Recent Events. |

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
| Event log storage | Not tested |  |

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
