# Agent Workflow For PublicGuard

This file is for coding agents and maintainers with write access to the
`tobias6483/PublicGuard` repository. PublicGuard is open source, so external
contributors may use the normal fork-based GitHub pull request workflow instead.

## Branch Protection Facts

- `main` is protected.
- `enforce_admins` is enabled, so branch rules also apply to the owner/admin.
- Direct pushes to `main` should be rejected.
- Force pushes to `main` are disabled.
- Deleting `main` is disabled.
- Pull requests are required before merging to `main`.
- The required GitHub Actions check is `Swift Build and Test`.
- Strict status checks are enabled, so the PR branch must be up to date with
  `main` and CI must pass for the current merge candidate.
- Approving review count is currently `0`, so another person's approval is not
  required before merge.
- GitHub rejects self-approval when the same account opened the PR. That is
  normal and is not a blocker while `required_approving_review_count` remains
  `0`.

## Tooling Rule

Use local `git` for branch, stage, commit, and push operations.

Use the authenticated GitHub CLI (`gh`) as the primary tool for PR creation,
marking PRs ready, and merging in this repo.

The GitHub app connector can be useful for reading PR metadata, issues,
comments, and repository context, but do not use it as the first choice for
write/publish operations in this repo. It previously failed PR creation with
`403 Resource not accessible by integration`, while local `gh` was correctly
authenticated as the maintainer account.

## Required Flow

Do this:

```text
branch -> edit -> test -> stage -> commit -> push -> PR -> CI green -> merge -> delete branch
```

Do not do this:

```text
edit on main -> commit -> push main
```

## Step-By-Step

Start from an up-to-date `main` and create a branch:

```sh
git switch main
git pull --ff-only
git switch -c codex/short-description
```

Before staging, inspect status and diff:

```sh
git status -sb
git diff
```

Stage only files relevant to the current task:

```sh
git add <relevant-files>
```

Run the required local check:

```sh
swift test
```

If app resources, app bundle metadata, packaging, release behavior, or bundled
assets changed, also run:

```sh
scripts/build_app.sh
```

Commit and push the branch:

```sh
git commit -m "Short description"
git push -u origin codex/short-description
```

Open a draft PR against `main`:

```sh
gh pr create --base main --head codex/short-description --draft
```

When the PR is ready and `Swift Build and Test` is green:

```sh
gh pr ready <number>
gh pr merge <number> --squash --delete-branch
```

Clean up locally after merge:

```sh
git switch main
git pull --ff-only
git fetch --prune
```

## Notes For Agents

- Never stage unrelated user changes silently.
- Do not leave a draft PR branch hanging if the user expects the change to be
  shipped and CI is green.
- If CI is still running, report that the PR branch will remain visible until
  the PR is merged and the branch is deleted.
- If a PR needs to stay open for review, leave it as a draft or ready PR and
  clearly tell the user that the extra branch is expected.
- Use PRs even for documentation-only changes.
