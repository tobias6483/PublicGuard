# Support

PublicGuard is in MVP beta development. It is open source and best suited for
technical users, contributors, and early testers who are comfortable with
unsigned macOS builds.

## Before Asking For Help

- Read [README.md](README.md) for the current feature set and run commands.
- Read [docs/development.md](docs/development.md) if you are cloning, building,
  or testing the repo.
- Read [docs/release.md](docs/release.md) if you are downloading a release
  artifact.
- Check [docs/roadmap.md](docs/roadmap.md) for planned work and known scope.
- Check [docs/hardware-qa-results.md](docs/hardware-qa-results.md) for current
  manual device test coverage.

## Bug Reports

Use the GitHub bug report template when PublicGuard crashes, fails to build,
logs an unexpected event, behaves differently from the README, or has a
reproducible trigger problem.

Please include:

- macOS version.
- PublicGuard version, tag, commit, or release artifact name.
- Whether you used `swift run PublicGuard`, `dist/PublicGuard.app`, or a GitHub
  release download.
- Steps to reproduce.
- Expected behavior.
- Actual behavior.
- Relevant local log entries with private details removed.

## Feature Requests

Use the GitHub feature request template for product ideas, new triggers, new
actions, or packaging improvements.

Permission-sensitive proposals should use the privacy review template before
implementation. This includes camera, microphone, location, Bluetooth,
networking, authentication, encryption, local logs, background execution, and
cloud behavior.

## Security Reports

Use [SECURITY.md](SECURITY.md) for security-sensitive reports. Do not publish
private vulnerability details in a public issue if that would put users at risk.

## What Is Out Of Scope For Support

- Recovering a lost macOS password.
- Bypassing macOS security controls.
- Guaranteeing theft prevention.
- Guaranteeing alarm playback while a MacBook is fully asleep with the lid
  closed.
- Supporting modified forks that changed security-sensitive behavior without
  documenting the change.
