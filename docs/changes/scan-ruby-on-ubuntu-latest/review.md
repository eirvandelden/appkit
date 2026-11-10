# Review: Run scan_ruby on ubuntu-latest

## Round 1 — 2026-11-10T20:47Z — 623a344

No findings.

The repository has no `REVIEW.md` or `REVIEW.local.md`, so the default Bugs, Security, Compliance and Design passes ran.

- Bugs: none. `scan_ruby` now uses the same runner as `scan_js` and `lint`, which run the same `spinel-coop/setup-rv@main` step and pass in Clocky.
- Security: none. No permissions, secrets, actions or inputs change.
- Compliance, criterion 1 (`runs-on: ubuntu-latest`): met. `ruby -ryaml -e '…["jobs"]["scan_ruby"]["runs-on"]'` prints `ubuntu-latest`.
- Compliance, criterion 2 (only that line plus one `CHANGELOG.md` entry): met. `git diff --numstat origin/main...HEAD -- . ':(exclude)docs/changes'` prints `1 1 .github/workflows/rails-ci.yml` and `1 0 CHANGELOG.md`. The entry sits under `## Unreleased` / `### Changed`, keeps "Apps need not act." and adds no `### Upgrading` step, as the plan amendment requires.
- Compliance, criterion 3 (Clocky `scan_ruby` no longer fails with `OpenSSL is not available`): deferred to after the merge, by Etienne's Path 1 decision in the plan amendment. It is not checkable before the merge.
- Compliance, criterion 4 (workflow checks green): `actionlint` is not installed, so it did not run. The YAML parses. appkit's `ci.yml` runs on `pull_request` only, so its checks run once `deliver` opens the pull request.
- Compliance, tests: configuration only, so the plan names no tests. No existing test changed. `bin/rails test` passes (242 runs, 0 failures). `bundle exec rubocop` reports no offenses.
- Design: none. The two existing `ubuntu-slim` comments stay, as `## Design decisions` records. No Ruby, signatures, queries or glossary terms change.
