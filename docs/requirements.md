# Product Requirement Coverage

This document tracks PublicGuard against the current product brief: an open-source macOS security and privacy utility for developers, students, creators, and maintainers working in public spaces.

## Positioning

| Requirement | Status | Notes |
| --- | --- | --- |
| Open-source macOS security/privacy utility | Implemented | Native Swift/AppKit menu bar app with MIT license, contribution docs, security policy, and local-first positioning. |
| Audience: developers, students, founders, designers, OSS maintainers | Implemented | README positions the app around people who build in public. |
| Protect local development environments, code, tokens, and devices | Implemented | README explains the security motivation without adding cloud tracking. |
| Local-first, no account, no cloud, no analytics | Implemented | Privacy principles are documented; app behavior is local. |

## MVP Features

| Requirement | Status | Notes |
| --- | --- | --- |
| macOS menu bar app | Implemented | `PublicGuardController` owns the status item and menu. |
| Arm / Disarm | Implemented | Menu bar flow with armed state. |
| Loud alarm | Implemented | `AlarmPlayer` loops bundled or system sounds. |
| Alarm if lid closes while armed | Implemented with OS limits | `NSWorkspace.willSleepNotification` starts the configured response while armed when macOS gives the app time before suspension. |
| Alarm if charger is removed | Implemented | `PowerMonitor` detects power adapter disconnects while armed. |
| Alarm if Mac wakes from sleep while armed | Implemented | `NSWorkspace.didWakeNotification` starts the configured response after wake. |
| Touch ID/password protected disarm | Implemented | `DeviceAuthenticator` protects disarm and alarm stop. |
| Event log: armed time | Implemented | `armed` log event. |
| Event log: lid/sleep event | Implemented | `system_will_sleep` and `system_did_wake slept_seconds=...` log events. |
| Event log: charger removed | Implemented | `charger_disconnected` log event. |
| Event log: alarm triggered | Implemented | `alarm_triggered` or `silent_response_triggered` log events. |
| Event log: alarm stopped | Implemented | `alarm_stopped` log event. |
| Encrypted event logs | Implemented | Optional AES-GCM event log storage uses a local macOS Keychain-backed key. |
| Event log retention | Implemented | User can keep logs forever, 7 days, or 30 days, and manually prune old entries with local `log_pruned` audit logging. |

## Stronger Features

| Requirement | Status | Notes |
| --- | --- | --- |
| iPhone / phone proximity trigger | Configurable, needs hardware QA | BLE learning, configurable out-of-range timeout, and out-of-range trigger exist, but iPhone stability requires device QA. |
| Charger disconnect action: alarm, lock, notification | Implemented | Response pipeline supports alarm/silent, optional lock, and optional notification. Lock command fallback is unit-tested, but manual app-bundle lock behavior still needs hardware QA. |
| Motion signal | Covered by proxies | Modern MacBook motion sensors are not assumed; PublicGuard uses sleep/wake, charger, Bluetooth, Wi-Fi, and configurable idle signals. |
| Network/location change trigger | Implemented | Wi-Fi SSID changes are monitored locally with CoreWLAN events and fast polling fallback. |
| Silent mode | Implemented | Silent response logs, notifies if enabled, and locks if enabled without alarm audio. |
| Camera snapshot | Privacy review designed, not implemented | Out of scope for v0.1. `docs/camera-snapshot-privacy-review.md` defines the opt-in, local-only, retention, logging, testing, and permission-copy gate required before implementation. |
| Panic/grace delay | Implemented | Configurable 0, 1, 5, 10, 15, or 30 second grace period. |
| Per-trigger grace tuning | Implemented | Individual triggers can use the default grace period or override it up to 2 minutes. |
| Public session mode: café | Implemented | Aggressive loud mode with all triggers and maximum app playback volume. |
| Public session mode: library | Implemented | Silent mode with all triggers and longer grace/idle timing. |
| Public session mode: school | Implemented | Loud mode with moderate grace/idle timing and all triggers. |
| Public session mode: office | Implemented | Silent mode with Wi-Fi change disabled to reduce false alarms on roaming office networks. |

## OSS Project Readiness

| Requirement | Status | Notes |
| --- | --- | --- |
| GitHub Actions | Implemented | `Swift Build and Test` is required on protected `main`. |
| Tests | Implemented | Unit coverage exists for settings, presets, state, and logs. |
| Docs | Implemented | README, development notes, release notes, roadmap, QA docs, and this matrix. |
| Security policy | Implemented | `SECURITY.md` covers sensitive areas and reporting. |
| Contributor onboarding | Implemented | `CONTRIBUTING.md` and development docs exist. |
| Release automation | Partial | Local release check script, unsigned app bundle build, bundle validation, GitHub Actions unsigned zipped app artifact, and SHA-256 checksum exist; signing and notarization are roadmap. |
| Issue triage / maintainer automation | Implemented | GitHub Actions labels issues by area, hardware QA need, and privacy-review signals while keeping triage inside GitHub. |
