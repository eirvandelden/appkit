# Review: upgrade-rubocop-ruby-4-0-9

## Round 1 — 2026-11-06T13:56Z — 8626301

No REVIEW.md or REVIEW.local.md exists, so the default Bugs, Security, Compliance and Design passes ran. Bugs: none. Security: none; `bin/bundler-audit check` finds no vulnerabilities. Design: the one new method signature (`GeneratedSignatures.copy`) is correct; no Demeter, N+1 or glossary issue.

Compliance, per acceptance criterion in `intent.md`:

- Fresh `bundle lock` resolves RuboCop 1.92 or newer: verified in a clean clone of the branch, `rubocop (1.92.2)`.
- `bundle exec rubocop` passes on Ruby 4.0.9: verified, 108 files, no offenses.
- Tests, `steep` and `rbs:check` pass on Ruby 4.0.9: verified, 174 runs, 0 failures; `rbs:check` clean; steep finds no type error.
- CI `lint` green on the pull request: pending. CI runs on `pull_request` only, and no pull request exists yet.

No test was weakened, skipped or deleted.

- [ ] Nit: The `rubocop` floor `">= 1.92"` lets a fresh resolve take RuboCop 2.x, a major release, with no review. The `dependencies` skill asks for major.minor (`~> 1.92`), which every other constraint in `Gemfile` and `appkit.gemspec` uses and which still allows any newer 1.x. The plan chose `>=` but gives no reason to differ from the skill. — `Gemfile:16` → fixed (Cap the RuboCop floor at the 1.x series)
- [ ] Nit: The untracked `test/dummy/bin/` (brakeman, bundler-audit, ci, dev, rails, rake, rubocop, setup) is outside this change's scope. It was never tracked on any branch. Keep it out of every commit, or remove it. — `test/dummy/bin/` → dismissed: untracked and never staged; no commit holds it, and it is not part of this change.

## Round 2 — 2026-11-06T14:01Z — 4917b97

No REVIEW.md or REVIEW.local.md exists, so the default Bugs, Security, Compliance and Design passes ran again on the full branch diff. No uncommitted change exists outside `review.md` and the untracked `test/dummy/bin/` that round 1 dismissed.

Both round 1 findings are closed. `Gemfile:16` now reads `gem "rubocop", "~> 1.92", require: false`, which keeps a floor of 1.92 and stops at 2.0.

Bugs: none. Security: none; `bin/bundler-audit check` finds no vulnerabilities, and both Brakeman scans report 0 security warnings. Design: none; the change touches no domain object.

Compliance, per acceptance criterion in `intent.md`:

- Fresh `bundle lock` resolves RuboCop 1.92 or newer: verified in a clean clone of 4917b97, `rubocop (1.92.2)`.
- `bundle exec rubocop` passes on Ruby 4.0.9: verified, 108 files, no offenses. `erb_lint --lint-all` finds no errors.
- Tests, `steep` and `rbs:check` pass on Ruby 4.0.9: verified, 174 runs, 593 assertions, 0 failures; `rbs:check` clean; steep finds no type error.
- CI `lint` green on the pull request: pending. CI runs on `pull_request` only, and no pull request exists yet.

`intent.md` and `plan.md` still name `>= 1.92`. `~> 1.92` meets the intent's floor, and round 1 records why it changed, so this round raises no finding for it. No test was weakened, skipped or deleted. No `CHANGELOG.md` entry is needed: the change is development-only and reaches no host app.

No findings.
