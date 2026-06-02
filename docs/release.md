# Release Notes

Use [v0.1-release-checklist.md](v0.1-release-checklist.md) before tagging or
publishing the first beta release. It defines the local verification commands,
manual hardware QA gate, README media prep, artifact dry run, and release notes
template.

Use [v0.1-release-notes.md](v0.1-release-notes.md) as the working GitHub Release
body draft. Update its hardware QA section with actual results before
publishing.

## Local App Bundle

Build a local unsigned app bundle:

```sh
scripts/build_app.sh
scripts/validate_app_bundle.sh
```

The generated app is written to:

```text
dist/PublicGuard.app
```

Run it with:

```sh
open dist/PublicGuard.app
```

The bundle is intentionally local and unsigned for now. It includes:

- `CFBundleIdentifier`: `dev.publicguard.PublicGuard`
- `CFBundleIconFile`: `PublicGuard`, backed by `Sources/PublicGuard/Resources/PublicGuard.icns`
- `LSUIElement`: enabled, so PublicGuard appears as a menu bar app without a Dock icon
- `LSMinimumSystemVersion`: macOS 14.0
- `NSBluetoothAlwaysUsageDescription`: explains local Bluetooth proximity detection
- SwiftPM resource bundles, including bundled alarm sounds

`scripts/validate_app_bundle.sh` verifies the generated executable, Info.plist
values, icon, SwiftPM resource bundle, and bundled alarm files before manual QA
or artifact upload.

`Settings > Launch at Login` uses macOS ServiceManagement and should be verified from this app bundle. It is not active when running the executable directly through SwiftPM.

## GitHub App Artifact

The `App Artifact` workflow builds the same unsigned bundle on GitHub Actions,
validates the app bundle, zips it, writes a SHA-256 checksum, and uploads both
files as a workflow artifact named `PublicGuard-unsigned-app`.

Run it manually from GitHub Actions, or push a version tag such as:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The artifact is useful for maintainer QA and release dry runs. It is still
unsigned and not notarized, so it is not a polished public distribution build.

## Future Release Work

- Add a signed Developer ID release workflow.
- Add notarization.
- Consider a Homebrew cask once the app is stable.
