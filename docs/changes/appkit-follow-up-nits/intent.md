# Intent: appkit follow-up nits from readme-app-name-callable

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-13). Type: chore. Delivery: autonomous.

## Problem

The readme-app-name-callable delivery (PR #15, merged) left six unrelated nits. Each one was verified on `0bc4f57`:

1. A host app that follows the README Installation section gets a `NoMethodError` on every engine page. Engine controllers call `allow_unauthenticated_access`, which only exists when the host `ApplicationController` includes `Appkit::Authentication`. Neither the README nor `bin/rails generate appkit:install` says or does this.
2. The engine's ERB views (12 files under `app/`) are never linted. `lefthook.yml` calls `erb_lint`, but `erb_lint` is not in the bundle, and the tracked `lefthook-local.yml` skips the hook so it does not fail.
3. `bin/rails test` does not run the suite. It fails with `cannot load such file -- test_helper (LoadError)`, raised inside Minitest's argument parsing, with or without a path argument. Only `rake test` works. The pre-push `minitest` hook is skipped in `lefthook-local.yml`.
4. `CHANGELOG.md` lines 9–19 and much of `README.md` are hard-wrapped, against playbook rule 26 (one line per paragraph and list item).
5. Every `bundle exec` in a fresh commit modifies `Gemfile.lock`: the gem version embeds the current git SHA (`0.1.0.pre.git.<sha>`), so the `appkit` entry under `PATH` and `CHECKSUMS` drifts and the working tree is dirty. The same `Appkit::VERSION` names the service worker cache (`app/views/appkit/pwa/service_worker.js.erb:1`).
6. The #15 `CHANGELOG.md` entry puts the steps host apps must take under `### Fixed`. PR #14 (AGENTS.md, still open) asks for those steps in a separate `### Upgrading` subsection.

## Proposed outcome

- A host app that follows the README Installation section, or runs `bin/rails generate appkit:install`, has `include Appkit::Authentication` in its `ApplicationController`, and engine pages load.
- ERB views are linted by `erb_lint` in the pre-commit and pre-push hooks, and the current views pass.
- `bin/rails test` runs the suite (all tests, a directory or a single file), and the pre-push `minitest` hook runs.
- `CHANGELOG.md` and `README.md` prose follows rule 26.
- `bundle exec` leaves `Gemfile.lock` unchanged, while a host app that moves to a new appkit SHA still gets a new service worker cache name.
- `CHANGELOG.md` keeps the upgrade steps in a `### Upgrading` subsection, following PR #14's rules.

## Affected users and systems

- Host apps that install or upgrade appkit: the README, the install generator, the CHANGELOG, the gem version and the service worker cache name.
- Appkit contributors and agents: `bin/rails test`, lefthook hooks, `Gemfile.lock` hygiene.
- Not affected: CI workflows, deploy files, migrations.

## Constraints

- Ship as one pull request on branch `appkit-follow-up-nits`, with one commit per nit (or more small commits per nit), so each nit can be reverted alone.
- Approved permission (rule 11): add the `erb_lint` gem as a development dependency. No other dependency change is approved.
- Not approved: edits to `.github/workflows/` (rule 13), migrations, system tooling.
- The service worker cache name must still change when a host app moves to a different appkit SHA, so stale PWA caches are cleared.
- `rake test` keeps working.
- The `### Upgrading` subsection follows PR #14's rules, even though #14 is not merged yet. This change does not wait for #14.
- Personal repository: Minitest, fixtures (playbook rule 15).

## In scope

1. README Installation shows `include Appkit::Authentication` in the host `ApplicationController`, and `bin/rails generate appkit:install` adds it when it is missing.
2. Add `erb_lint` as a development dependency, configure it, remove the `erb_lint` skips from `lefthook-local.yml`, and fix any offenses in the engine's ERB files.
3. Make `bin/rails test` run the suite, and remove the `minitest` skip from `lefthook-local.yml`.
4. Unwrap the hard-wrapped prose in `CHANGELOG.md` and `README.md` (code blocks and tables unchanged).
5. Stop `bundle exec` from modifying `Gemfile.lock`, keeping per-SHA service worker cache rotation.
6. Move the #15 host-app steps from `### Fixed` into a `### Upgrading` subsection of `## Unreleased`, and record this change's own host-facing steps there too (for example the generator change), per PR #14's rules.

## Out of scope

- CI workflow changes, including running `erb_lint` in CI.
- Unwrapping markdown files other than `CHANGELOG.md` and `README.md`.
- Re-enabling other skipped hooks (stylelint, browserslist, eslint, rspec, brakeman, bundle-audit).
- Merging or changing PR #14.
- Any change to authentication behaviour itself.

## Acceptance criteria

- A host app whose `ApplicationController` lacks the include gets it after `bin/rails generate appkit:install`, and its sign-in page loads.
- Running `bin/rails generate appkit:install` twice leaves exactly one `include Appkit::Authentication` in the host `ApplicationController`.
- The README Installation snippet shows `include Appkit::Authentication` inside `class ApplicationController`.
- `bundle exec erb_lint --lint-all` exits 0 on the engine's ERB views, and an ERB file with an offense staged for commit makes the pre-commit hook fail.
- `bin/rails test`, `bin/rails test test/controllers` and `bin/rails test test/appkit_test.rb` each run their tests and pass; `bundle exec rake test` still passes.
- Pushing a change to `app/controllers/appkit/pwa_controller.rb` runs `test/controllers/appkit/pwa_controller_test.rb` in the pre-push hook.
- Every paragraph and list item in `CHANGELOG.md` and `README.md` prose sits on one line.
- After a new commit, `bundle exec rake test` leaves `git status` clean.
- Two appkit commits with different SHAs produce different service worker cache names.
- `## Unreleased` in `CHANGELOG.md` has one `### Upgrading` subsection after `### Added`, `### Changed` and `### Fixed`, with one instruction per step; `### Fixed` no longer holds upgrade steps.

## Open questions

None.
