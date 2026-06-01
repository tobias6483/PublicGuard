# Contributing to PublicGuard

Thanks for helping make PublicGuard better.

## Development

Build the project:

```sh
swift build
```

Run the app:

```sh
swift run PublicGuard
```

## Project Direction

PublicGuard should stay:

- Local-first
- Privacy-first
- User controlled
- Transparent about permissions
- Small enough to audit

## Good First Issues

- Add unit tests around new triggers and actions
- Improve menu bar copy
- Run and document manual hardware QA
- Research reliable macOS lid-close behavior
- Tune bundled alarm sound loudness after hardware testing
- Improve release packaging documentation

## Pull Requests

The `main` branch is protected. Changes should go through a pull request, and the `Swift Build and Test` GitHub Actions check must pass before merging.

Please keep pull requests focused and explain:

- What changed
- Why it changed
- How it was tested
- Whether it changes privacy, permissions, or background behavior
