# Plan: appkit follow-up nits from readme-app-name-callable

From `intent.md` (2026-10-13). Status: draft.

Revision needed: `intent.md` was amended on 2026-10-13 (commit `8c30f85`). Nit 5 now keeps the commit SHA in the gem version, untracks and ignores `Gemfile.lock`, and makes CI (`ci.yml`, `rails-ci.yml`) and the local hooks work without a lockfile, as the accepted plan on branch `stable-gem-version` (`docs/changes/stable-gem-version/plan.md`) describes. Rework nit 5, the `### Changed` CHANGELOG line, the commit order, the lockfile steps and the Proof list to match, and run a new critique round.

## Context

appkit is a non-isolated Rails engine. Host apps install it with `gem "appkit", github: "eirvandelden/appkit"`. `test/dummy` is the host app the Minitest suite runs against. This change fixes six unrelated nits on branch `appkit-follow-up-nits`, one commit (or a few small commits) per nit, so each nit can be reverted alone. Facts below were checked on `8ffa328` in a scratch clone.

## Design decisions

### Nit 5: stable gem version, revision-based cache name

- `lib/appkit/version.rb` becomes `VERSION = "0.1.0"`, with no git shell-out. `Gemfile.lock` then records `appkit (0.1.0)` under `PATH` and `CHECKSUMS`, and no later commit changes it.
- `BASE_VERSION` goes away; nothing outside `version.rb` reads it (`grep -rn BASE_VERSION` finds only `version.rb`).
- A new PORO, `Appkit::Revision` (`lib/appkit/revision.rb`), names the appkit commit at runtime. It takes the loaded gem spec and the engine root as injected arguments. `#to_s` returns, in order: the spec source's `revision` when the source responds to it (Bundler `Source::Git`, full 40-char SHA); else `git -C <root> rev-parse HEAD` (full SHA) when that succeeds; else `Appkit::VERSION`.
- `Appkit.revision` (in `lib/appkit.rb`) memoizes `Revision.new(spec: Gem.loaded_specs["appkit"], root: <gem root>).to_s`. The gem root is `File.expand_path("..", __dir__)` from `lib/appkit.rb`, so it works before `Appkit::Engine` loads.
- `app/views/appkit/pwa/service_worker.js.erb:1` becomes `const CACHE_NAME = 'appkit-<%= Appkit.revision %>';`.
- Why Bundler first: in a host, Bundler loads appkit from a `Source::Git` whose `revision` comes from the host's `Gemfile.lock`. It does not need a `.git` directory. The Rails 8.1 `Dockerfile` template removes `bundler/gems/*/.git` after `bundle install` (`railties-8.1.4/lib/rails/generators/rails/app/templates/Dockerfile.tt:68`). So today's `git rev-parse` in `version.rb` returns nothing in a Dockerized host, `VERSION` falls back to `0.1.0`, and the cache name never changes there. The Bundler revision fixes that too. Checked in the scratch clone: `Gem.loaded_specs["mvpa-css"].source` is a `Bundler::Source::Git` and `.revision` returns `"cdc83559ce5ece2815d684594c694a93efcb5b22"`. In appkit's own repo the source is `Bundler::Source::Gemspec` (no `revision`), so the git fallback applies.
- Rejected: untracking `Gemfile.lock` (the unmerged `stable-gem-version` branch's approach). It needs `.github/workflows/ci.yml` changes, which this intent does not approve, and it keeps the per-commit version.
- Rejected: a content digest of the engine files as the cache name. Two commits that change only `test/` would share a name, against the acceptance criterion.

### Nit 3: `bin/rails test`

- Add `ENGINE_ROOT = File.expand_path("..", __dir__)` to `bin/rails`, after `APP_PATH`, before the `require_relative`. `Rails::Command.root` returns `ENGINE_ROOT` when it is defined, else `test/dummy` (`railties-8.1.4/lib/rails/command.rb:102`). `rails test` appends `Rails::Command.root.join("test")` to `$LOAD_PATH` (`rails/commands/test/test_command.rb:29`), so today it adds `test/dummy/test` and misses `test/test_helper.rb`. Checked in the scratch clone: with the line, `bin/rails test` (126 runs), `bin/rails test test/controllers` (31 runs) and `bin/rails test test/appkit_test.rb` (2 runs) all pass.
- Keep `require_relative "../test/dummy/config/boot"` and `require "rails/commands"`; do not switch to the full plugin template (`rails/engine/commands`). One line is the smallest change that works.
- Side effect: `bin/rails generate` now targets the engine root, not `test/dummy`, as in a generated Rails plugin. No hook or workflow calls the engine's `bin/rails generate`. The README's `bin/rails generate appkit:install` is a host-app command and uses the host's own binstub, so this change does not touch it.
- Remove `minitest: skip: true` from `pre-push` in `lefthook-local.yml`. The shared hook already maps `app/controllers/appkit/pwa_controller.rb` to `test/controllers/appkit/pwa_controller_test.rb` and runs `bin/rails test` on it.

### Nit 2: erb_lint

- Add `spec.add_development_dependency "erb_lint"` to `appkit.gemspec`, after `solid_cache`, matching the other development dependencies (no version constraint, like them). Approved in the intent. In the scratch clone it resolved to 0.9.0.
- New `.erb_lint.yml`: `EnableDefaultLinters: true`; `glob: "app/**/*.erb"`, so `--lint-all` covers exactly the 12 engine ERB files under `app/` (the two non-HTML ones too) and never reaches `.worktrees/`, `tmp/` or `test/dummy`. Enable the `Rubocop` linter with `rubocop_config: inherit_from: [.rubocop.yml]` and the cops erb_lint's README turns off for ERB: `Layout/InitialIndentation`, `Layout/LineLength`, `Layout/TrailingEmptyLines`, `Layout/TrailingWhitespace`, `Naming/FileName`, `Style/FrozenStringLiteralComment`, `Lint/UselessAssignment`, `Rails/OutputSafety`.
- Why include the two non-HTML files: in the scratch clone, erb_lint on `service_worker.js.erb` and `manifest.json.erb` raised only RuboCop offenses (`Layout/SpaceInsideArrayLiteralBrackets` on `service_worker.js.erb:2`), no false positives from the HTML linters.
- Known offenses to fix (scratch clone, config above): `Layout/SpaceInsideArrayLiteralBrackets` in `app/views/appkit/preferences/edit.html.erb` lines 22, 36, 41, 45 and `app/views/appkit/pwa/service_worker.js.erb:2`; `Style/StringLiterals` in `app/views/appkit/shared/_confirm_dialog.html.erb` lines 4 and 5. Fix them in the views; never add a disable comment or relax `.erb_lint.yml` to pass.
- `lefthook-local.yml`: drop `erb_lint: skip: true` from both hooks and override `run`; keep the inherited globs (`*.{erb}`, `*.erb`), which match nested files (checked in the scratch clone: `lefthook run pre-commit --no-auto-install --command erb_lint --file app/views/appkit/shared/_skip_link.html.erb -f` runs the command). Override `run` to `bundle exec erb_lint {staged_files}` (pre-commit) and `bundle exec erb_lint {push_files}` (pre-push). Why `bundle exec`: the RuboCop linter inherits `rubocop-eirvandelden`, a git-sourced gem that only Bundler can load. The shared `lefthook.yml` stays untouched; it is a copy of the dotfiles one.

### Nit 1: `include Appkit::Authentication`

- New generator step `add_authentication_to_application_controller` in `lib/generators/appkit/install/install_generator.rb`, after `create_push_subscriptions_migration`. It calls `inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include Appkit::Authentication\n"`.
- Guard clauses: return when the host file does not exist (the existing generator tests run without one, and a host without that file has nothing to fix), and return when the file already matches `/^\s*include\s+Appkit::Authentication\b/`. The second guard makes a second run a no-op even when the host wrote the include with different spacing. Thor's own duplicate check only matches the exact string.
- README `## Installation`: ordered steps after the Gemfile lines: run `bundle install`, run `bin/rails generate appkit:install`, run `bin/rails db:migrate`. Put `include Appkit::Authentication` inside the existing `class ApplicationController` snippet, above `allow_browser`. Say in one line why: most engine controllers inherit the host's `::ApplicationController` and call `allow_unauthenticated_access` or `require_unauthenticated_access` as class methods, and `Appkit::Authentication` defines both, plus the default `require_authentication` filter (`app/controllers/concerns/appkit/authentication.rb`).
- No change to authentication behaviour itself (out of scope).

### Nit 4: unwrap prose

- Join hard-wrapped lines in `CHANGELOG.md` and `README.md` prose so each paragraph, list item and block quote sits on one line. Code fences and tables stay byte-for-byte. A line break inside inline code (README: `` `bundle\ninstall` ``) becomes a space.
- Do this as one commit with no wording change, so the diff is reviewable with `git diff --word-diff`.

### Nit 6: `### Upgrading`

- Follow PR #14's rules (branch `agents-md-with-upgrade-instructions`, `AGENTS.md` "Upgrade instructions"): one `### Upgrading` subsection in `## Unreleased`, after `### Added`, `### Changed` and `### Fixed`; a numbered list, one instruction per step, an exact command where one exists, in the order an app runs them; only steps read in the code.
- The #15 `### Fixed` entry keeps its description of what changed. Its host instruction ("check that none of them redirects or blocks these two endpoints") moves to `### Upgrading` as: "Check that no `before_action` in your `ApplicationController` redirects or blocks `GET /manifest` or `GET /service-worker`; both now inherit it." Paths from `config/routes.rb`.
- This change's own entries:
  - `### Changed` (new subsection, between `### Added` and `### Fixed`), nit 5: the gem version is `0.1.0` without the git SHA; the service worker cache name now uses the appkit commit SHA from Bundler, so it also changes in hosts whose Docker build deletes `.git`. No host action: a host's next `bundle update appkit` rewrites its lockfile.
  - `### Fixed`, nit 1: following the README or running the install generator no longer leaves engine pages raising `NoMethodError` for `allow_unauthenticated_access`.
  - `### Upgrading`, nit 1: "Run `bin/rails generate appkit:install --skip` to add `include Appkit::Authentication` to `ApplicationController` when it is missing." Before writing it, verify in a generator test that `--skip` still runs the inject step (Thor's `--skip` only skips file collisions).
- Nits 2, 3 and 4 are contributor-only and get no CHANGELOG line (PR #14: test-only and lint changes add no upgrade step).

## Integration points

- Bundler 4.0.16 runtime API: `Gem.loaded_specs`, `Bundler::Source::Git#revision`.
- Rails 8.1.4 command root resolution (`Rails::Command.root`, `rails test`).
- Thor's `inject_into_class` through `Rails::Generators::Base`.
- erb_lint 0.9.0 with RuboCop and `rubocop-eirvandelden` (git-sourced).
- Lefthook 2.2.0 through the global `core.hooksPath`; `lefthook-local.yml` merges over `lefthook.yml`. Always pass `--no-auto-install` to `lefthook run`: a plain run overwrites the stow-managed global hooks.
- Host apps: README, install generator, CHANGELOG, service worker cache name, the appkit version in their `Gemfile.lock`.

## Files that change

- `lib/appkit/version.rb` — `VERSION = "0.1.0"`, no git call.
- `lib/appkit/revision.rb` — new `Appkit::Revision` PORO.
- `lib/appkit.rb` — `require "appkit/revision"`; `Appkit.revision`.
- `app/views/appkit/pwa/service_worker.js.erb` — cache name from `Appkit.revision`; erb_lint fix on line 2.
- `Gemfile.lock` — `appkit (0.1.0)` under `PATH` and `CHECKSUMS` (nit 5); `erb_lint` and its dependencies (nit 2). Only `bundle install` writes it.
- `test/appkit_test.rb` — "version is present" becomes "has a stable package version".
- `test/appkit/revision_test.rb` — new unit tests for `Appkit::Revision`.
- `test/controllers/appkit/pwa_controller_test.rb` — "service worker cache name includes the engine version" becomes "service worker cache name includes the appkit revision".
- `bin/rails` — `ENGINE_ROOT`.
- `appkit.gemspec` — `erb_lint` development dependency.
- `.erb_lint.yml` — new.
- `app/views/appkit/preferences/edit.html.erb`, `app/views/appkit/shared/_confirm_dialog.html.erb` — erb_lint fixes only.
- `lefthook-local.yml` — erb_lint skips removed and `run` overridden with `bundle exec`; `minitest` skip removed.
- `lib/generators/appkit/install/install_generator.rb` — `add_authentication_to_application_controller`.
- `test/generators/appkit/install_generator_test.rb` — new tests for the inject.
- `README.md` — Installation (nit 1); unwrap (nit 4).
- `CHANGELOG.md` — unwrap (nit 4); `### Changed`, `### Fixed`, `### Upgrading` entries (nits 5, 6, 1).

## Order of work

Run the narrowest test first. Use `bin/rails test <file>` once nit 3 has landed; before it, use `bundle exec ruby -Itest <file>`. Before nit 5 lands, any `bundle exec` rewrites the `appkit (0.1.0.pre.git.<sha>)` lines in `Gemfile.lock`: run `git checkout -- Gemfile.lock` before each commit until then, and never commit that drift.

1. Nit 5, walking skeleton. Replace `test/appkit_test.rb` "version is present" with "has a stable package version": `assert_match(/\A\d+\.\d+\.\d+\z/, Appkit::VERSION)`, so no commit SHA can be in it. Run it; watch it fail (`0.1.0.pre.git.<sha>`).
2. Write `test/appkit/revision_test.rb` (names under Proof). Fake specs are `Struct`s or `Data` with a `source`; the git case points `root:` at the engine root and compares with `git -C <root> rev-parse HEAD`; the no-git case uses a `Dir.mktmpdir`. Change the pwa controller test to assert `"appkit-#{Appkit.revision}"`. Run; watch them fail (`uninitialized constant Appkit::Revision`, `undefined method revision`).
3. Implement `lib/appkit/revision.rb`, `Appkit.revision`, the new `version.rb` and the service worker line. Run `bundle install` once to rewrite `Gemfile.lock` to `appkit (0.1.0)`. Run the three test files, then `bundle exec rake test` and `bundle exec rubocop`. Add the `### Changed` CHANGELOG line (one line, not wrapped). Commit as nit 5.
4. Nit 5 by hand, the required proof for the lockfile criterion. In a fresh scratch clone of the branch (outside the worktree): `bundle install`, `git commit --allow-empty -m tmp`, `bundle exec rake test`, then `git status --porcelain` prints nothing.
5. Nit 3. Run `bin/rails test test/appkit_test.rb`; watch it fail with `cannot load such file -- test_helper`. Add `ENGINE_ROOT` to `bin/rails`. Run `bin/rails test test/appkit_test.rb`, `bin/rails test test/controllers`, `bin/rails test`, `bundle exec rake test`: all pass. Remove the `minitest` skip from `lefthook-local.yml`. Check: `lefthook dump` shows `pre-push.minitest` without `skip`; `yamllint lefthook-local.yml`. Commit as nit 3.
6. Nit 3 hook check: `lefthook run pre-push --no-auto-install --command minitest --file app/controllers/appkit/pwa_controller.rb --force` prints "Running minitest for app/controllers/appkit/pwa_controller.rb..." and passes.
7. Nit 2. Add `erb_lint` to `appkit.gemspec`; `bundle install`. Write `.erb_lint.yml`. Run `bundle exec erb_lint --lint-all`; watch it report the known offenses listed under Design decisions. Fix the three views. Run `bundle exec erb_lint --lint-all`: exit 0. Run `bin/rails test test/controllers` and `bin/rails test test/integration` (the views render there). Edit `lefthook-local.yml`; `lefthook dump`; `yamllint lefthook-local.yml`. Commit as nit 2 (the view fixes may be their own commit).
8. Nit 2 hook check: copy `app/views/appkit/shared/_skip_link.html.erb` to a scratch-named file in the worktree, add `<%= foo 'x' %>`, then `lefthook run pre-commit --no-auto-install --command erb_lint --file <that file> --force`: it fails. Delete the file. Then the same command on `app/views/appkit/shared/_skip_link.html.erb` passes.
9. Nit 4. Unwrap `CHANGELOG.md` and `README.md` prose. Check: `git diff --word-diff=porcelain` shows only joined lines; no line inside a fence or table changed. Commit as nit 4.
10. Nit 6. Move the #15 host step into a new `### Upgrading` at the end of `## Unreleased`. Commit as nit 6.
11. Nit 1. Write the generator tests (names under Proof); run `bin/rails test test/generators/appkit/install_generator_test.rb`; watch the inject tests fail. Implement the generator step. Run the file, then `bin/rails test`. Edit the README Installation section and add the `### Fixed` and `### Upgrading` lines (one line each). Commit as nit 1.
12. Full checks: `bin/rails test`, `bundle exec rake test`, `bundle exec rubocop`, `bundle exec erb_lint --lint-all`, `yamllint lefthook-local.yml .erb_lint.yml`, both Brakeman scans from `.github/workflows/ci.yml` (`bundle exec brakeman -p test/dummy --no-pager --ignore-config config/brakeman.ignore`, `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`), `bundle exec bundler-audit check --update`. Then `git status --porcelain` prints nothing.
13. Re-read the full diff against `main`; every hunk serves one of the six nits.

## Risks

- A host on a `path:` or released-gem install has neither a Bundler git revision nor a `.git`; its cache name becomes `appkit-0.1.0` and stops rotating. Today such a host gets the same name. Hosts install from GitHub (README), so this is no regression.
- Hosts see a one-time cache rotation: the cache name changes format from `appkit-0.1.0.pre.git.<short sha>` to `appkit-<full sha>`. The service worker's `activate` handler deletes old caches, so this is harmless.
- `Gem.loaded_specs["appkit"]` is `nil` when appkit is loaded without RubyGems or Bundler knowing it (for example `-Ilib`). `Revision` must treat a `nil` spec as "no Bundler revision" and fall through to git.
- `bin/rails generate` now writes into the engine root instead of `test/dummy`. A contributor who relied on the old target must pass paths by hand.
- erb_lint 0.9.0 prints a `parser/ruby33` warning on Ruby 4.0.5. It is noise from the `parser` gem, not an offense; do not silence it with config.
- The unmerged `stable-gem-version` branch takes the opposite approach to nit 5 (untrack `Gemfile.lock`, keep the SHA in the version). Once this lands, that branch conflicts with it and its intent no longer holds.
- PR #14's `AGENTS.md` describes the `Gemfile.lock` drift, the `bin/rails test` failure and the skipped ERB and test hooks as gotchas. This change makes those lines stale. Changing PR #14 is out of scope.
- Unwrapping touches most README lines, so open branches that edit the README get rebase conflicts.

## Out of scope

- `.github/workflows/` (CI and `rails-ci.yml`), including running erb_lint in CI.
- Migrations and system tooling.
- Unwrapping markdown other than `CHANGELOG.md` and `README.md`.
- Re-enabling the stylelint, browserslist, eslint, rspec, brakeman and bundle-audit hooks.
- Merging or editing PR #14 and the `stable-gem-version` branch.
- Authentication behaviour itself, and the other host includes (`Appkit::VersionHeaders`, `Appkit::Authorization`).
- Editing the shared `lefthook.yml`.

## Proof

- A host app whose `ApplicationController` lacks the include gets it after `bin/rails generate appkit:install`, and its sign-in page loads → `test/generators/appkit/install_generator_test.rb` "adds include Appkit::Authentication to an ApplicationController that lacks it"; sign-in page: `test/controllers/appkit/sessions_controller_test.rb` "login layout actually loads JavaScript", against `test/dummy`, whose `ApplicationController` has the same include.
- Running the generator twice leaves exactly one include → `test/generators/appkit/install_generator_test.rb` "running the generator twice leaves one include Appkit::Authentication".
- The README Installation snippet shows the include inside `class ApplicationController` → check: read `README.md` `## Installation` in the diff.
- `bundle exec erb_lint --lint-all` exits 0, and a staged ERB offense fails pre-commit → check: `bundle exec erb_lint --lint-all` exits 0; Order of work step 8.
- `bin/rails test`, `bin/rails test test/controllers`, `bin/rails test test/appkit_test.rb` pass; `bundle exec rake test` passes → check: run all four (Order of work step 5).
- Pushing a change to `app/controllers/appkit/pwa_controller.rb` runs its test in pre-push → check: Order of work step 6.
- Every paragraph and list item in `CHANGELOG.md` and `README.md` prose sits on one line → check: `git diff --word-diff=porcelain` in step 9, and read both files outside fences and tables.
- After a new commit, `bundle exec rake test` leaves `git status` clean → check: Order of work step 4 (fresh clone, empty commit, `bundle exec rake test`, clean `git status`); regression guard: `test/appkit_test.rb` "has a stable package version".
- Two appkit commits with different SHAs produce different service worker cache names → `test/appkit/revision_test.rb` "two Bundler revisions give two different values"; `test/controllers/appkit/pwa_controller_test.rb` "service worker cache name includes the appkit revision".
- `## Unreleased` has one `### Upgrading` after `### Added`, `### Changed` and `### Fixed`, one instruction per step, and `### Fixed` holds no upgrade step → check: read `CHANGELOG.md` in the diff.

Per changed file, the unit tests expected:

- `lib/appkit/revision.rb`: `Revision#to_s` "returns the Bundler git revision when the spec has one", "two Bundler revisions give two different values", "falls back to the git HEAD of the root when the source has no revision", "falls back to the git HEAD when there is no spec", "falls back to Appkit::VERSION when the root is not a git checkout".
- `lib/appkit/version.rb`: `AppkitTest` "has a stable package version".
- `Gemfile.lock`: no unit test; proven by Order of work step 4.
- `app/views/appkit/pwa/service_worker.js.erb`: `Appkit::PwaControllerTest` "service worker cache name includes the appkit revision".
- `lib/generators/appkit/install/install_generator.rb`: "adds include Appkit::Authentication to an ApplicationController that lacks it", "running the generator twice leaves one include Appkit::Authentication", "leaves an ApplicationController that already includes Appkit::Authentication unchanged", "skips the include when the host has no ApplicationController", "adds the include when run with --skip".
- `bin/rails`, `lefthook-local.yml`, `.erb_lint.yml`, `appkit.gemspec`, the three views, `README.md`, `CHANGELOG.md`: no unit test; proven by the checks above.

Test setup: Minitest, no fixtures needed. `Revision` tests inject fake spec objects (a value object with `source`, the source with or without `revision`) and a root path; Minitest 6 ships without `minitest/mock`, so use injection, not stubs. Generator tests write `app/controllers/application_controller.rb` into the generator's destination with `File.write` before `run_generator`.

---
Domain skills applied: rails-architecture (behaviour on a small PORO, no service object), object-oriented-design (dependency injection for `Revision`), rails-testing (Minitest, test first), ruby-style (guard clauses), dependencies (erb_lint approved in intent; no other gem change), new-repo-setup (lefthook: never `lefthook install`, `--no-auto-install` on `lefthook run`).

## Critique

### Round 1 (codex exec -p terra)

- The inherited lefthook ERB glob `*.{erb}` matches only root files, so the hook skips nested views; override it with `app/**/*.erb` → dismissed: checked in the scratch clone, `lefthook run pre-commit --no-auto-install --command erb_lint --file app/views/appkit/shared/_skip_link.html.erb -f` with the inherited glob ran the command on that nested file, in both hooks.
- The `--lint-all` glob `**/*.erb` reaches `test/dummy` beyond the intent's 12 engine views, and the `.worktrees/**/*` exclude may not match absolute paths → fixed (`.erb_lint.yml` uses `glob: "app/**/*.erb"` with no excludes)
- The README sequence runs the generator before `bundle install` → fixed (README steps are now `bundle install`, the generator, `bin/rails db:migrate`)
- The README explanation that every engine controller calls `allow_unauthenticated_access` is false (`PreferencesController`, `PushSubscriptionsController`, `SessionsController`) → fixed (the README line now names both class methods and the default filter that `Appkit::Authentication` defines)
- The lockfile test is a brittle meta-test, and an exact `"0.1.0"` assertion cannot observe a new commit → fixed (`test/lockfile_test.rb` removed; version test is "has a stable package version" with a format match; the fresh-clone empty-commit check is the required proof)
- The README already documents `bin/rails generate appkit:install`, so the claim that no doc calls `bin/rails generate` is wrong → fixed (the rationale now says the README command is a host-app command that the engine binstub change does not touch)
