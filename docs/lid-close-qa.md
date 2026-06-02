# Lid-Close QA

This checklist is for validating PublicGuard's sleep/wake behavior on real
MacBook hardware. It is intentionally focused on observable local behavior,
because macOS usually suspends normal app execution when the lid is closed.

## Goal

Confirm what PublicGuard can honestly support for v0.1:

- Log that macOS is about to sleep while PublicGuard is armed.
- React when the Mac wakes while PublicGuard is armed.
- Avoid claiming that alarm audio keeps playing while the lid remains closed.

## Test Setup

Record these details with every run:

- Mac model and chip.
- macOS version.
- Whether the Mac is on battery or power adapter.
- Whether an external display, keyboard, mouse, or dock is connected.
- Whether `Prevent automatic sleeping on power adapter when the display is off`
  is enabled in macOS settings.
- PublicGuard build source: `swift run PublicGuard` or `dist/PublicGuard.app`.
- PublicGuard settings: response mode, grace period, alarm volume, notifications,
  lock screen, and enabled triggers.
- `Recent Trigger Status` sleep/wake rows before the test: last sleep, last wake,
  sleep gap, and observation counts.

Use the app bundle for the main pass:

```sh
scripts/build_app.sh
open dist/PublicGuard.app
```

Clear the event log before each run from the PublicGuard menu bar menu.

## Baseline: Open Lid Sleep/Wake

1. Arm PublicGuard.
2. Use the Apple menu or power key flow to put the Mac to sleep with the lid
   still open.
3. Wake the Mac.
4. Authenticate if PublicGuard starts a response.
5. Open `Recent Events` or the event log.

Expected result:

- `armed`
- `system_will_sleep`
- `system_did_wake slept_seconds=...`
- `grace_period_started ... reason="Mac woke while armed"`
- Loud or silent response entries, depending on settings.

Also confirm `Recent Trigger Status` increments the sleep/wake observation counts
and shows a sleep gap matching the rough sleep duration.

## Lid Close/Reopen

1. Arm PublicGuard.
2. Close the MacBook lid.
3. Wait at least 10 seconds.
4. Reopen the lid.
5. Authenticate if PublicGuard starts a response.
6. Open `Recent Events` or the event log.

Expected result:

- `system_will_sleep` may be logged before the Mac sleeps.
- `system_did_wake slept_seconds=...` should be logged after reopening if macOS
  delivers the wake event to PublicGuard and PublicGuard observed the preceding
  sleep notification.
- `system_did_wake slept_seconds="unknown"` means PublicGuard saw wake without a
  matched sleep notification in the current process lifetime.
- PublicGuard should start the configured response after wake while armed.

Important non-goal:

- Do not expect alarm sound while the lid remains closed and the machine is
  actually asleep.

## Closed-Display / External Display Mode

Run this only if an external display, keyboard, and pointer are available.

1. Connect power and the external display setup.
2. Arm PublicGuard.
3. Close the MacBook lid while the Mac remains usable from the external display.
4. Disconnect power or change Wi-Fi.
5. Confirm whether PublicGuard remains running and responds.

Expected result:

- If macOS keeps the system awake in closed-display mode, normal triggers such as
  charger disconnect and Wi-Fi change may still fire.
- Record the exact hardware setup, because this behavior depends on macOS power
  state and peripherals.

## Pass/Fail Criteria For v0.1

Pass:

- PublicGuard logs sleep/wake events reliably enough to document.
- `Recent Trigger Status` reflects the observed sleep/wake counts and matched
  sleep gap.
- PublicGuard reacts after wake while armed.
- README language remains honest about closed-lid sleep limitations.

Fail:

- Wake while armed does not trigger a response.
- Event log wording implies a guaranteed live closed-lid alarm.
- Any proposed fix requires broad sleep-prevention behavior by default.

## Follow-Up Options

If manual QA shows unreliable `NSWorkspace` sleep/wake delivery, consider a
separate implementation branch for `IORegisterForSystemPower`. That lower-level
API can provide more explicit power lifecycle messages, but it must acknowledge
sleep messages correctly and still should not be presented as a guarantee that
alarm playback continues while a sleeping MacBook lid is closed.
