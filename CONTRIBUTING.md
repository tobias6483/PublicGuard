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

External contributors are welcome to use the standard GitHub fork workflow:

1. Fork the repository.
2. Create a branch in your fork.
3. Push your branch.
4. Open a pull request against `tobias6483/PublicGuard:main`.

Maintainers and project agents with write access should use local `git` plus the authenticated GitHub CLI (`gh`) for the full publish flow. Do not commit or push directly to `main`.

Maintainer flow:

```sh
git switch main
git pull --ff-only
git switch -c codex/short-description
git status -sb
git diff
git add <relevant-files>
swift test
git commit -m "Short description"
git push -u origin codex/short-description
gh pr create --base main --head codex/short-description --draft
```

When CI is green and the PR is ready, a maintainer can merge it:

```sh
gh pr ready <number>
gh pr merge <number> --squash --delete-branch
git switch main
git pull --ff-only
git fetch --prune
```

The GitHub app connector may be useful for reading PR metadata, issues, and comments, but `gh` is the preferred tool for maintainer PR creation and merge operations in this repo.

Please keep pull requests focused and explain:

- What changed
- Why it changed
- How it was tested
- Whether it changes privacy, permissions, or background behavior
