# Review: update-dependencies

## Round 1 — 2026-10-13 08:18 UTC — 34954b8

Checks run at review time on Ruby 4.0.7 and Bundler 4.0.22: `RUBYOPT=-W:deprecated bundle exec rake test` (103 runs, 0 failures, 0 errors, 0 lines that match `deprecat`), `bundle exec rubocop` (82 files, no offenses), both Brakeman scans (no warnings), `bundler-audit check --update` (no vulnerabilities). The scratch Rails 8.0 `bundle lock` fails on appkit and names railties; the Rails 8.1 lock succeeds. No uncommitted changes. No new disable comments; `.rubocop_todo.yml` and the Brakeman ignore files are unchanged.

### Bugs

Nothing found. The new constraints are all `~> major.minor`, and each one admits the locked version. marcel stays at 1.2.1.

### Security

Nothing found. bundler-audit and both Brakeman scans are clean. The workflow changes only move action tags; no permissions, secrets or triggers change.

### Compliance

| Acceptance criterion | Evidence | State |
| --- | --- | --- |
| `bundle outdated` lists only marcel | A1, run at review time | red, see Important below |
| Rails 8.0 cannot resolve appkit; Rails 8.1 can | A2, scratch `bundle lock` | green |
| Suite passes on Ruby 4.0.7 with no deprecation warnings | A3 | green |
| RuboCop, both Brakeman scans, bundler-audit pass; no new disable comments or todo entries | A4 | green |
| appkit's CI green on checkout `@v7` and cache `@v6` | A5 | pending: the branch is not pushed yet (`origin/update-dependencies` is at 0d25b88) and no PR exists |
| `rails-ci.yml` on checkout `@v7`, cache `@v6`, setup-node `@v7`, upload-artifact `@v7` | A6 | green |
| `BUNDLED WITH 4.0.22`, `.ruby-version` reads `ruby-4.0.7` | A7 | green |
| CHANGELOG says appkit requires Rails 8.1 | A8 | green |

The six implementation commits match the plan's order of work, and each one touches only the files the plan names. No existing test changed.

### Findings

- [x] Important: A1 is red. `bundle outdated` now lists json 3.0.2 → 3.1.0, net-imap 0.6.7 → 0.6.8 and rubocop 1.91.0 → 1.92.0 next to marcel. All three released after the last commit (rubocop 2026-10-10, net-imap 2026-10-12, json 2026-10-13), so the intent's first acceptance criterion no longer holds. A named `bundle update json net-imap rubocop` plus a fresh A3 and A4 run closes it; the rubocop minor can bring new cops under `NewCops: enable`. — `Gemfile.lock:149` → fixed (Update json, net-imap and rubocop to their latest versions)
- [x] Nit: The CHANGELOG entry names only the Rails 8.1 floor. Consuming apps that call the reusable `rails-ci.yml` also get checkout `@v7`, cache `@v6` and setup-node `@v7`. The plan's Risks section says checkout v7 breaks a caller that runs it under `pull_request_target` or `workflow_run`. A second `### Changed` line would warn those consumers. — `CHANGELOG.md:22` → fixed (Warn rails-ci.yml callers about the checkout v7 fork rule)

## Round 2 — 2026-10-13 08:56 UTC — 74a54ad

Checks run at review time on Ruby 4.0.7 and Bundler 4.0.22: `RUBYOPT=-W:deprecated bundle exec rake test` (103 runs, 286 assertions, 0 failures, 0 errors, 0 lines that match `deprecat`), `bundle exec rubocop` (82 files, no offenses), both Brakeman scans (no warnings), `bundler-audit check --update` (no vulnerabilities). `bundle outdated` lists only marcel. The scratch Rails 8.0 `bundle lock` exits 6 and names railties; the Rails 8.1 lock succeeds. No uncommitted changes. No new disable comments; `.rubocop_todo.yml`, `config/`, `app/`, `lib/` and `test/` are unchanged.

### Bugs

Nothing found. 7cdf83e moves only json 3.0.2 → 3.1.0, net-imap 0.6.7 → 0.6.8 and rubocop 1.91.0 → 1.92.0, plus the appkit SHA lines the plan allows. rubocop 1.92.0 raises its regexp_parser floor to 2.11.3, and the lock already satisfies it. The new rubocop minor surfaces no offenses.

### Security

Nothing found. bundler-audit and both Brakeman scans are clean. The release notes of checkout v7.0.0, cache v6.0.0 and setup-node v7.0.0 show no change to inputs that `ci.yml` or `rails-ci.yml` use.

### Compliance

| Acceptance criterion | Evidence | State |
| --- | --- | --- |
| `bundle outdated` lists only marcel | A1, run at review time | green |
| Rails 8.0 cannot resolve appkit; Rails 8.1 can | A2, scratch `bundle lock` | green |
| Suite passes on Ruby 4.0.7 with no deprecation warnings | A3 | green |
| RuboCop, both Brakeman scans, bundler-audit pass; no new disable comments or todo entries | A4 | green |
| appkit's CI green on checkout `@v7` and cache `@v6` | A5 | pending: `origin/update-dependencies` is at 0d25b88 before this round's push, and no PR exists |
| `rails-ci.yml` on checkout `@v7`, cache `@v6`, setup-node `@v7`, upload-artifact `@v7` | A6 | green |
| `BUNDLED WITH 4.0.22`, `.ruby-version` reads `ruby-4.0.7` | A7 | green |
| CHANGELOG says appkit requires Rails 8.1 | A8 | green |

Both round 1 findings hold. The new CHANGELOG line about checkout v7 matches the v7.0.0 release note ("block checking out fork pr for pull_request_target and workflow_run"). No existing test changed.

### Findings

Nothing found.
