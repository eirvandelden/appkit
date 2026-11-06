# Plan: Upgrade RuboCop and Ruby so CI lint goes green

From `intent.md` (2026-11-06). Status: accepted.

## Design

### Domain terms

Not affected: no domain terms. `Gemfile` constraint and `.ruby-version` only.

### Diagrams

Not affected: no objects change.

### Signatures

Not affected: no Ruby code changes.

Checked by: steep check

### Complexity

Not affected: no runtime path changes.

### Invariants

Not affected: the constraint is development-only, so host apps resolve nothing new.

### Alternatives

- Add a floor in `rubocop-eirvandelden`'s gemspec: rejected, needs a second repository and merge.
- Commit `Gemfile.lock`: rejected, reverts the 2026-10-13 decision and fights `version.rb`.
- Set `TargetRubyVersion` to 3.4: rejected, hides the real Ruby version.

## Design decisions

- Floor `>= 1.92` (the version already locked locally and known to support Ruby 4.0), declared in the `Gemfile` next to the other tooling gems, with `require: false`.
- No conflict with `intent.md` `## Decisions`.

## Integration points

- CI `lint` job resolves gems with `bundle lock`, so it picks up the `Gemfile` constraint.
- `.ruby-version` feeds `rv` locally and `ruby-version: current` in CI follows the latest release.

## Files that change

- `Gemfile` — add `gem "rubocop", ">= 1.92", require: false` with a one-line comment saying why.
- `.ruby-version` — `ruby-4.0.7` to `ruby-4.0.9`.
- Any file RuboCop 1.92 newly flags — fix in code, no disable comments.

## Order of work

1. Change `Gemfile` and `.ruby-version`.
2. Run `bundle lock --update rubocop` and `bundle exec rubocop`. Fix new offences.
3. Run `bundle exec rake test`, `rake rbs:check`, `rake steep`, `erb_lint --lint-all`, Brakeman and Bundler Audit.
4. Prove the fresh resolve in a clean clone of the branch: `bundle lock` gives RuboCop 1.92 or newer.
5. Re-read the diff, commit, push the branch to `origin`.

## Risks

- RuboCop 1.92 flags new offences in untouched code. Fix them in code in the same branch, or split if large.
- Ruby 4.0.9 changes behaviour in a gem. The test run on 4.0.9 shows it.

## Proof

- A fresh `bundle lock` in a clone resolves RuboCop 1.92 or newer → check: in a clean clone of the branch, run `bundle lock` and `grep -E '^    rubocop \(' Gemfile.lock`.
- `bundle exec rubocop` passes locally on Ruby 4.0.9 → check: `bundle exec rubocop`.
- Tests, `steep` and `rbs:check` pass on Ruby 4.0.9 → check: `bundle exec rake test`, `bundle exec rake rbs:check`, `bundle exec rake steep`.
- CI `lint` is green on the pull request → check: `gh run list --branch upgrade-rubocop-ruby-4-0-9`.

Per changed file, the unit tests expected: none. This is configuration.

Test setup: none.

---
Domain skills applied: dependencies.
