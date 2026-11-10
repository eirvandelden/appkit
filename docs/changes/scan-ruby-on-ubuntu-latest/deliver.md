# Delivery account: scan-ruby-on-ubuntu-latest

## Behaviour delivered

The `scan_ruby` job of the reusable `rails-ci.yml` runs on `ubuntu-latest` instead of `ubuntu-slim`. `CHANGELOG.md` has one entry under `## Unreleased`, "Apps need not act."

## Evidence

- Cause, from Clocky's CI log: `bin/brakeman` crashes on `ubuntu-slim` with `OpenSSL is not available` during `--ensure-latest`. The `lint` and `scan_js` jobs pass on `ubuntu-latest` with the same `setup-rv` step.
- A YAML parse of the job prints `ubuntu-latest`.
- `git diff --numstat` (excluding `docs/changes`) lists only `rails-ci.yml` (1/1) and `CHANGELOG.md` (1/0).
- RuboCop: 110 files, no offenses. No Ruby changed, so no tests apply.

## Review

One Claude round, no findings.

## Not verified before the merge

- Clocky's `scan_ruby` result. Clocky calls the workflow at `@main`, so the fix reaches it only after the merge. Etienne chose to verify it from Clocky's next CI run, with no Clocky change.
- `actionlint` is not installed, and was not installed (rule 8).

## Follow-up

appkit's own `ci.yml` still runs two jobs on `ubuntu-slim` (lines 14 and 116).
