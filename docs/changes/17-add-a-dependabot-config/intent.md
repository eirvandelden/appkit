# Intent: Add a Dependabot config

Author: Etienne van Delden. Status: accepted. Type: chore.
Delivery: autonomous

## Problem

appkit has no `.github/dependabot.yml`.
Nobody learns that a dependency fell behind, so updates happen only by hand.
PR #16 caught up 23 gems, Ruby, Bundler and three GitHub Actions majors at once.
While it was open, six more releases came out: json, net-imap, rubocop, lefthook and mvpa-css twice.

## Proposed outcome

Dependabot opens pull requests for new releases of Bundler gems and GitHub Actions.
The config follows the `dependencies` skill: minimal, all ecosystems, all update types, cooldown of one week.

## Affected users and systems

- Etienne, who reviews and merges the Dependabot pull requests.
- Apps that call `.github/workflows/rails-ci.yml` at `@main`: an action bump merged there reaches every app's CI at once.
- `Gemfile`, `Gemfile.lock`, `.github/workflows/ci.yml`, `.github/workflows/rails-ci.yml`.

## Constraints

- Approved permission: add the new file `.github/dependabot.yml` (outside rule 13's workflow list). No gems, migrations or workflow edits are needed.
- Config stays minimal: no groups, labels, reviewers or ignore rules unless a verified problem needs one.
- `rails-ci.yml` gets the same treatment as `ci.yml`. The pull request is the review gate; merging stays Etienne's decision.
- `lib/appkit/version.rb` and `Gemfile.lock` handling stay as they are. A Dependabot-caused lockfile noise is documented, not worked around in code.
- Dependabot behaviour is checked against its documentation, not assumed from memory (playbook rule 22).

## In scope

- `.github/dependabot.yml` with the `bundler` ecosystem at `/` and the `github-actions` ecosystem at `/`.
- A cooldown of one week and all update types (major, minor, patch) in both ecosystems.
- Checking, from Dependabot's documentation, how it treats: the git gems `mvpa-css` and `rubocop-eirvandelden` (locked revisions); marcel, held at 1.2.1 by Active Storage's `~> 1.0`; the SHA in the `appkit` lines of `Gemfile.lock`.
- Recording each finding where a later reader finds it (CHANGELOG entry or `CLAUDE.md` gotcha, whichever fits the surrounding convention).

## Out of scope

- Changing any dependency version.
- Changing `rails-ci.yml` or `ci.yml`.
- Changing `lib/appkit/version.rb` or how `Gemfile.lock` is written.
- Auto-merge, grouping, labels, assignees, or security-only update rules.
- Other ecosystems (npm, docker): the repository has none.

## Acceptance criteria

- `.github/dependabot.yml` is valid: GitHub's Dependabot parser accepts it, and the repository's Dependabot page lists both ecosystems without a config error.
- A new gem release opens a bundler pull request only after it is a week old.
- A new action release, for example a new `actions/checkout` major, opens a github-actions pull request that touches `ci.yml` and `rails-ci.yml`.
- A major gem update is proposed, not skipped.
- A release that the constraints block, such as a marcel release above `~> 1.0`, produces no broken pull request.
- The three checks in Scope (git gems, marcel, `appkit` SHA lines) each have a recorded answer, with a documentation link.
- `bundle exec rubocop` and the test suite stay green.

## Open questions

None.
