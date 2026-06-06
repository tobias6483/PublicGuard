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

## Downloading A Public Artifact

Early PublicGuard artifacts are for technical testers. Unless a release says
otherwise, they are unsigned and not notarized.

Download both files from the GitHub release:

```text
PublicGuard.app.zip
PublicGuard.app.zip.sha256
```

Verify the downloaded ZIP bytes before opening the app:

```sh
shasum -a 256 -c PublicGuard.app.zip.sha256
```

Then unzip the app:

```sh
unzip PublicGuard.app.zip
```

Move `PublicGuard.app` to `/Applications`, for example by dragging it there in
Finder. From Terminal, you can also copy it:

```sh
cp -R PublicGuard.app /Applications/
open /Applications/PublicGuard.app
```

Running the app from `Downloads` is acceptable for a one-off smoke test, but
release users should keep it in `/Applications`. That matches normal macOS app
placement, gives launch-at-login and app identity behavior a more stable path,
and gives future update instructions one stable app location.

The checksum confirms that the ZIP matches the published digest. It does not
prove developer identity, replace code signing, or remove macOS Gatekeeper
warnings. Review the release notes for current hardware QA status, known limits,
and whether the artifact is signed or notarized.

## Local Release Check

Run the full local release check before opening a v0.1 release PR or tagging a
release:

```sh
scripts/release_check.sh
```

The script runs `swift build`, `swift test`, builds and validates
`dist/PublicGuard.app`, then creates an unsigned artifact dry run at:

```text
dist/artifacts/PublicGuard.app.zip
dist/artifacts/PublicGuard.app.zip.sha256
```

Record the commit and command result in the release PR or release notes.

## GitHub App Artifact

The `App Artifact` workflow builds the same unsigned bundle on GitHub Actions,
runs the release check, validates the app bundle, zips it, writes a SHA-256
checksum, and uploads both files as a workflow artifact named
`PublicGuard-unsigned-app`.

Run it manually from GitHub Actions, or push a version tag such as:

```sh
git tag v0.1.2
git push origin v0.1.2
```

The artifact is useful for maintainer QA and release dry runs. It is still
unsigned and not notarized, so it is not a polished public distribution build.

## Future Release Work

- Add a signed Developer ID release workflow.
- Add notarization.
- Consider a Homebrew cask once the app is stable.
