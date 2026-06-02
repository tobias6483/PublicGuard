# Issue Triage

PublicGuard uses a lightweight GitHub Actions workflow to label new, edited,
and reopened issues. The goal is faster maintainer routing without sending
issue content to a third-party triage service.

## Automation

The workflow lives at `.github/workflows/issue-triage.yml`.

It reads the issue title and body with `actions/github-script`, creates missing
repository labels when needed, and applies matching labels.

## Labels

- `area:trigger`: charger, Wi-Fi, sleep/wake, Bluetooth, proximity, idle, and other trigger work.
- `area:action`: alarms, silent response, lock screen, notifications, and event logs.
- `area:menu-bar`: menu bar UX, settings, presets, status text, and icon behavior.
- `area:docs`: README, docs, roadmap, release notes, and contributor guidance.
- `area:release`: build, packaging, artifacts, signing, notarization, and distribution work.
- `hardware-qa`: issues that likely need real Mac hardware, charger, Bluetooth, lid-close, or accessory testing.
- `privacy-review`: issues that mention permissions, privacy/security, camera, microphone, location, networking, Bluetooth, Keychain, encryption, tracking, or cloud behavior.
- `needs-triage`: fallback label when no specific routing label matches.

Use the `Privacy review` issue template for proposed camera, microphone,
location, networking, storage, authentication, lock behavior, Bluetooth, or
background-execution changes.

## Maintainer Notes

Labels are hints, not decisions. Maintainers should still review privacy,
permission, and hardware-impacting changes manually before implementation.

The workflow is intentionally local to GitHub Actions and does not add runtime
tracking, app telemetry, or any PublicGuard product dependency.
