# Release Notes

## Local App Bundle

Build a local unsigned app bundle:

```sh
scripts/build_app.sh
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

`Settings > Launch at Login` uses macOS ServiceManagement and should be verified from this app bundle. It is not active when running the executable directly through SwiftPM.

## Future Release Work

- Add a signed Developer ID release workflow.
- Add notarization.
- Add a zipped release artifact.
- Consider a Homebrew cask once the app is stable.
