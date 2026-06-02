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
- Validate Bluetooth proximity behavior with real devices
- Run and document lid-close hardware QA
- Tune bundled alarm sound loudness after hardware testing
- Verify launch at login behavior from local app bundle builds
- Improve local event log privacy and retention controls
- Improve release packaging documentation

## Pull Requests

The `main` branch is protected. Changes should go through a pull request, and the `Swift Build and Test` GitHub Actions check must pass before merging.

External contributors are welcome to use the standard GitHub fork workflow:

1. Fork the repository.
2. Create a branch in your fork.
3. Push your branch.
4. Open a pull request against `tobias6483/PublicGuard:main`.

Maintainers and project agents with write access should follow [AGENTS.md](AGENTS.md). In short: work on a branch, stage only relevant files, run `swift test`, run `scripts/release_check.sh` when release packaging, app bundle metadata, or bundled assets changed, create a PR with `gh`, wait for `Swift Build and Test`, then squash-merge and delete the branch. Do not commit or push directly to `main`.

Please keep pull requests focused and explain:

- What changed
- Why it changed
- How it was tested
- Whether it changes privacy, permissions, or background behavior

## Issue Triage

New and edited issues are labeled automatically by GitHub Actions based on the
issue title/body and issue-form fields. See [docs/triage.md](docs/triage.md)
for the current label set and privacy/security review signals.

Permission-sensitive proposals should use the `Privacy review` issue template
before implementation. Camera snapshot proposals must also satisfy
[docs/camera-snapshot-privacy-review.md](docs/camera-snapshot-privacy-review.md).
