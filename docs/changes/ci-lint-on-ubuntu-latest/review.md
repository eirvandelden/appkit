# Review: ci-lint-on-ubuntu-latest

## Round 1 — 2026-11-07T09:00Z — 9bfabd2

No `REVIEW.md` or `REVIEW.local.md` exists, so the reviewer's default passes apply. RuboCop: no offenses. Tests: 242 runs, 0 failures. `rails-ci.yml` parses; `scan_js` and `lint` now run on `ubuntu-latest`, `scan_ruby` stays on `ubuntu-slim`.

Compliance: the one acceptance criterion (sticker-app `ci / lint` and `ci / scan_js` pass) has no proof in the diff; `plan.md` defers it to `gh pr checks` on sticker-app after this branch merges, which matches the plan's Proof line.

- [ ] Important: The diff changes `rails-ci.yml` but adds no `CHANGELOG.md` entry. `AGENTS.md` requires one for every pull request that changes `rails-ci.yml`, because apps call it at `@main`. Add a `### Changed` line under `## Unreleased` that says `scan_js` and `lint` now run on `ubuntu-latest`. Apps need not act, so add no `### Upgrading` step. — `CHANGELOG.md:20` → fixed (docs: changelog for lint and scan_js on ubuntu-latest)
- [ ] Important: appkit's own `ci.yml` `lint` job still runs on `ubuntu-slim` and fails on `main` with the same `OPENSSL_3.4.0` LoadError (run 42294981268, head `d106f6b`). This branch's pull request inherits that red `lint` check, so autonomous delivery cannot reach green CI. Playbook rule 25 says to fix it. The intent scopes only `rails-ci.yml`, so Etienne must choose: widen this change's intent, or fix `ci.yml` on a separate branch first and rebase this one onto it. — `.github/workflows/ci.yml:62` → fixed (ci: run appkit's own lint on ubuntu-latest)

## Round 2 — 2026-11-07T09:09Z — 0af8ed5

No `REVIEW.md` or `REVIEW.local.md` exists, so the reviewer's default passes apply. RuboCop: 110 files, no offenses. Tests: 242 runs, 0 failures. Both workflow files parse. `rails-ci.yml` runs `scan_js` and `lint` on `ubuntu-latest`; `scan_ruby` stays on `ubuntu-slim`. `ci.yml` runs `lint` on `ubuntu-latest`; `scan_ruby` and `types` stay on `ubuntu-slim`. Both round 1 findings hold: the `CHANGELOG.md` line is under `## Unreleased` `### Changed` with no `### Upgrading`, and `ci.yml` `lint` moved.

Compliance: "appkit's own `lint` check passes" has no proof yet. `ci.yml` runs only on `pull_request` and on pushes to `main`, so the branch has no run; the plan defers it to `gh pr checks` on this pull request. "sticker-app `ci / lint` and `ci / scan_js` pass" waits for the merge, as the plan's Proof says. Run 42294981268 on `main` confirms the intent's facts: `lint` failed, `scan_ruby` and `types` passed.

Observation, out of scope by the intent: in `ci.yml` the `vendor/bundle` cache key is `gems-$RUNNER_OS-$RUNNER_ARCH-ruby-<version>-<hash>`, the same on `ubuntu-slim` and `ubuntu-latest`. A bundle built on `ubuntu-latest` can restore on the `ubuntu-slim` jobs `scan_ruby` and `types`. That is a likely cause of the LoadError, and those jobs can hit it once they load `openssl`.

No findings.
