# Intent: Upgrade RuboCop and Ruby so CI lint goes green

Author: Etienne van Delden. Status: accepted (2026-11-06). Type: chore. Delivery: step-by-step.

## Problem

CI is red on `main` since at least 2026-10-26. The `lint` job fails with "RuboCop found unknown Ruby version 4.0 in `TargetRubyVersion`". Appkit commits no `Gemfile.lock`, so CI resolves gems fresh. A fresh resolve picks RuboCop 1.74.0, which supports Ruby up to 3.4. Ruby is also behind: `.ruby-version` says 4.0.7, and 4.0.9 is the latest stable release.

## Proposed outcome

CI `lint` passes on the newest RuboCop that resolves, and the project runs on Ruby 4.0.9.

## Affected users and systems

- Appkit's own CI (`lint` job) and local lint.
- Appkit contributors, through `.ruby-version`.
- Host apps are not affected: the new constraint is a development-only line in the `Gemfile`, not in `appkit.gemspec`.

## Constraints

- Etienne approved raising RuboCop to a newer version (2026-11-06). Newer is allowed.
- Ruby 4.0.9 is already installed through `rv`. No tool install is needed.
- Ruby 4.1.0-preview1 is a preview and out of scope.

## In scope

- Add a `rubocop` floor (`>= 1.92`) to the `Gemfile` so a fresh resolve gets a RuboCop that knows Ruby 4.0.
- Bump `.ruby-version` to `ruby-4.0.9`.
- Fix any new RuboCop offence the upgrade produces, in code, with no disable comments.

## Out of scope

- Other gem updates, and Dependabot config.
- Changing `TargetRubyVersion` or the shared `rubocop-eirvandelden` rules.
- Committing `Gemfile.lock`.

## Acceptance criteria

- A fresh `bundle lock` in a clone resolves RuboCop 1.92 or newer.
- `bundle exec rubocop` passes locally on Ruby 4.0.9.
- Tests, `steep` and `rbs:check` pass on Ruby 4.0.9.
- The CI `lint` job on the pull request is green.

## Decisions

- Raise RuboCop with a `Gemfile` constraint — Etienne said "upgrade rubocop, its allowed to be newer".

## Open questions

None.
