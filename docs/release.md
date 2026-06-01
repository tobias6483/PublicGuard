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
- `LSUIElement`: enabled, so PublicGuard appears as a menu bar app without a Dock icon
- `LSMinimumSystemVersion`: macOS 14.0
- SwiftPM resource bundles, including the default alarm sound

## Future Release Work

- Add a signed Developer ID release workflow.
- Add notarization.
- Add an icon.
- Add a zipped release artifact.
- Consider a Homebrew cask once the app is stable.
