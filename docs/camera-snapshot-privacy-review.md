# Camera Snapshot Privacy Review

PublicGuard does not currently include camera snapshot behavior. This document
defines the review gate that must be completed before any camera-based action is
implemented.

The goal is to prevent PublicGuard from drifting into hidden recording,
surveillance, or cloud tracking. Any future camera snapshot action must be
explicit, local-only, and easy for the user to disable.

## Non-Negotiable Requirements

- No hidden capture.
- No continuous recording.
- No microphone capture.
- No cloud upload, remote viewing, analytics, or third-party processing.
- No automatic enablement in presets.
- No capture while PublicGuard is disarmed.
- No capture before the user explicitly enables the camera action.
- No capture without visible app settings and clear permission copy.
- No long-term retention by default.
- No use of snapshots for identity recognition, face analysis, or tracking.

## Required Product Design

A future camera snapshot action must have all of these controls:

- A dedicated `Settings > Camera Snapshot` section.
- A disabled-by-default toggle.
- Plain-language copy explaining when a snapshot can happen.
- A local storage location shown to the user.
- A retention setting, with the shortest option as the default.
- A `Clear Snapshots` action.
- A way to test the action manually before relying on it.
- Event log entries for enablement, capture attempts, successful captures,
  failures, and clearing snapshots.

## Required Permission Copy

The app bundle must include camera permission copy that states:

```text
PublicGuard can use the camera only when you explicitly enable local camera
snapshots for armed security responses. Snapshots stay on this Mac and are not
uploaded.
```

This copy should be reviewed before adding `NSCameraUsageDescription`.

## Required Storage Rules

- Store snapshots only under PublicGuard's Application Support directory.
- Do not write snapshots to shared folders, Photos, Desktop, or Documents by default.
- Use filenames that include timestamps but not trigger details, SSIDs, Bluetooth names, or personal labels.
- Prefer encrypted local storage if event log encryption is enabled, or document
  why encrypted snapshot storage is not yet available.
- Exclude snapshots from automatic upload workflows.

## Required Event Log Behavior

Standard log detail may include:

- `camera_snapshot_enabled`
- `camera_snapshot_disabled`
- `camera_snapshot_captured`
- `camera_snapshot_failed`
- `camera_snapshots_cleared`

Minimal log detail must not include file paths, faces, trigger reasons, device
names, SSIDs, or other identifying context.

## Required Tests

At minimum, implementation should add tests for:

- Settings persistence and default disabled state.
- Minimal event log redaction.
- Retention policy calculations.
- Snapshot storage path construction.
- Clearing snapshot metadata or files.
- Behavior when camera permission is missing or denied.

## Manual QA Checklist

Before release, test on real macOS hardware:

1. Confirm the app does not request camera permission until the camera action is explicitly enabled or tested.
2. Confirm the action is disabled by default after a clean install.
3. Confirm no preset enables the action.
4. Confirm snapshots are local-only and appear only in the documented storage location.
5. Confirm `Clear Snapshots` removes local snapshot files.
6. Confirm minimal log mode omits file paths and trigger details.
7. Confirm denied camera permission fails safely without blocking disarm.
8. Confirm the README and Security Policy still avoid surveillance framing.

## Decision For v0.1

Camera snapshot remains out of scope for v0.1. PublicGuard should ship the
local alarm, lock, notification, trigger, and logging loop first. If camera
snapshot is revisited later, this review must be updated before implementation.
