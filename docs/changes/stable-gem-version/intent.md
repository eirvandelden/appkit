# Intent: Stop tracking appkit's own Gemfile.lock

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore.

## Problem

The appkit version number comes from the git commit that is checked out when the gemspec loads (`lib/appkit/version.rb`). Every new commit gives a new version. So the appkit line in the committed `Gemfile.lock` changes on each `bundle` run, and it always names the commit before the one it is in. A file cannot name the hash of its own commit, so the committed lockfile can never agree with its commit. This was seen while reviewing PR #12 (Rails 8.1.4) and also happens on `main`.

Host apps never read appkit's `Gemfile.lock`; they read only the dependencies in `appkit.gemspec`. The lockfile serves appkit's own development: tests, linters and security checks, locally and in CI.

## Proposed outcome

Every commit keeps its own version, and that version names the commit. appkit no longer keeps a `Gemfile.lock` in git. Running `bundle` never leaves a lockfile change to commit. Local runs and CI install the newest gem versions that `appkit.gemspec` and `Gemfile` allow, and still pass.

## Affected users and systems

- appkit development, locally and in CI: tests, RuboCop, Brakeman and bundler-audit run against freshly resolved gems instead of a pinned set.
- Host apps that use appkit: no change. Their own lockfile records the appkit commit and a version that names it.

## Constraints

- Changing `.github/workflows/ci.yml` and `.github/workflows/rails-ci.yml` is part of this change. It was approved by choosing "CI works without it" as in scope.

## In scope

- Remove `Gemfile.lock` from git and ignore it.
- CI works without a committed lockfile, including the places in `ci.yml` and `rails-ci.yml` that rely on it.
- Local hooks work without a committed lockfile: the lefthook bundle step and `bin/bundler-audit`.
- The README explains that appkit does not commit its lockfile, and why.

## Out of scope

- Publishing appkit to RubyGems.
- The dotfiles worktree sweep bug that deleted the earlier `intent.md`.

## Acceptance criteria

- After a commit, `bundle install` leaves `git status` clean.
- In a checkout of commit `abc1234`, the appkit version is `0.1.0.pre.git.abc1234`.
- On a push, CI installs gems and runs the tests, RuboCop, Brakeman and bundler-audit successfully.
- After a fresh clone, the lefthook bundle step installs gems and `bin/bundler-audit` runs.
- The README says that appkit does not commit its `Gemfile.lock`, and why.

## Flagged concerns

- The version names the commit, and a committed lockfile must match its commit. Both cannot hold, because a file cannot name its own commit. Chosen side: the version keeps naming the commit, and appkit stops committing its lockfile.
- Without a lockfile, two runs on the same commit can test against different gem versions. Chosen side: accept this. Tests and CI run against the newest gems that are allowed.

## Open questions

None.
