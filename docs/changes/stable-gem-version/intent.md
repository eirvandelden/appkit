# Intent: Finish the untracked-lockfile follow-ups in CI and lefthook

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore.

## Problem

This change first set out to stop tracking appkit's own `Gemfile.lock`. PR #18 (merged as `d837929`) delivered that outcome: `Gemfile.lock` is ignored, CI resolves gems with `bundle lock`, `bin/bundler-audit` exists, and a test pins that the version names the checked-out commit. Etienne chose on 2026-10-16 to narrow this change to the four items that this branch has and `main` does not:

- `.github/workflows/ci.yml` has no `permissions:` block. The repository default token is read-only today, but a change to that setting would give every CI job write access.
- The gem cache `key` and `restore-keys` lines in `ci.yml` are about 130 characters long, so yamllint warns `line-length` on them.
- `lefthook-local.yml` does not set `no_auto_install: true`. `core.hooksPath` is the global `~/.config/git/hooks`, and `lefthook.yml` runs a nested `lefthook run migrations` without `--no-auto-install`. So a hook run in appkit can replace the stowed global hooks with generated files.
- The pre-push `bundle-audit` hook is skipped, so a gem with a known advisory reaches the remote before CI reports it.

## Proposed outcome

CI jobs get a read-only token whatever the repository default is. The gem cache lines in `ci.yml` stay under 120 characters, and the cache keys keep their meaning. No lefthook run in appkit rewrites the global git hooks. A push that follows a change to `Gemfile` or `appkit.gemspec` runs `bin/bundler-audit` first.

## Affected users and systems

- appkit's own CI (`.github/workflows/ci.yml`).
- appkit development on Etienne's machine: lefthook and the global git hooks.
- Host apps: no change. `rails-ci.yml` does not change.

## Constraints

- Changing `.github/workflows/ci.yml` is part of this change. Etienne approved it when he accepted the first version of this intent, and again by choosing "Narrow and deliver" on 2026-10-16.
- Keep `main`'s newer choices: `actions/checkout@v7`, `actions/cache@v6`, and the `bundle lock && rv ci` bundle step.

## In scope

- `permissions: contents: read` at the top of `ci.yml`.
- The `gems` step writes `cache-key` and `cache-prefix` outputs, and the cache steps use them.
- `no_auto_install: true` in `lefthook-local.yml`.
- The pre-push `bundle-audit` hook runs when `Gemfile` or `appkit.gemspec` changes.
- `AGENTS.md` says that the bundler-audit pre-push hook runs.

## Out of scope

- Everything that PR #18 delivered.
- `rails-ci.yml` and the install generator's CI template.
- Restoring global hooks that an earlier run already replaced.

## Acceptance criteria

- `ci.yml` declares `permissions: contents: read`, and the PR's CI run passes: `scan_ruby`, `lint` and `test`.
- yamllint reports no `line-length` warning for the gem cache lines in `ci.yml`. The RuboCop cache `key` line is 163 characters on `main` too and stays out of scope.
- `lefthook dump` in appkit shows `no_auto_install: true`. After a `lefthook run` in appkit, the files in `~/.config/git/hooks` are still symlinks into the dotfiles.
- `lefthook dump` shows `pre-push.bundle-audit` without `skip`, with glob `{Gemfile,appkit.gemspec}`.
- `AGENTS.md` no longer says that the bundler-audit pre-push hook is skipped.

## Flagged concerns

- The bundler-audit pre-push hook downloads the advisory database on a machine that lacks it. That download runs inside a git hook, where git exports `GIT_DIR`, and can fail. Chosen side: accept it; run `bin/bundler-audit update` once by hand.
- Commit messages from before the narrowing describe work that PR #18 already merged; the rebase dropped those hunks.

## Open questions

None.
