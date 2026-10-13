# Plan: appkit follow-up nits from readme-app-name-callable

From `intent.md` (2026-10-13, amended in commit `8c30f85`). Status: accepted.

## Context

appkit is a non-isolated Rails engine. Host apps install it with `gem "appkit", github: "eirvandelden/appkit"`. `test/dummy` is the host app the Minitest suite runs against. This change fixes six unrelated nits on branch `appkit-follow-up-nits`, one commit (or a few small commits) per nit, so each nit can be reverted alone. Facts below were checked on `8ffa328` and `45d788b` in scratch clones.

PR #14 merged into `main` (`4415186`) after the intent was written. It adds `AGENTS.md` and `CLAUDE.md`. Its "Upgrade instructions" section is now the rule for `### Upgrading`. This branch is still based on `0bc4f57` and must be rebased before work starts (Order of work step 0).

Gem installs: agents install gems with `bi` (playbook rule 11); a guard refuses `bundle install`. `bi` runs `bundle lock`, then `rv ci`, then `bin/rails app:update:bin`. That last step writes an untracked `test/dummy/bin/` in this repository (checked on `45d788b`, before and after the nit 3 change). Where a step below needs a clean `git status`, install with `bundle lock && rv ci` instead, which is `bi` without the binstub step.

## Design decisions

### Nit 5: keep the SHA version, stop tracking `Gemfile.lock`

This follows the accepted `stable-gem-version` plan (branch `stable-gem-version`, `docs/changes/stable-gem-version/plan.md`, commit `947b1b7`), adjusted to the amended intent.

- `lib/appkit/version.rb` does not change. It keeps `VERSION = "0.1.0.pre.git.<short sha>"`, or `BASE_VERSION` when git finds no commit.
- Untrack, do not delete: `git rm --cached Gemfile.lock`, and add `/Gemfile.lock` to `.gitignore`. A local lockfile stays on disk, untracked and ignored. Checked in a scratch clone: after `bundle lock && rv ci`, an empty commit and `bundle exec ruby -Itest test/appkit_test.rb`, `git status --porcelain` prints nothing, `git check-ignore Gemfile.lock` prints the path, and `bundle exec bundler-audit check --update` reports no vulnerabilities.
- The service worker cache name reads a new `Appkit.revision` instead of `Appkit::VERSION`, so it rotates per SHA in Dockerized hosts too. Today it does not: the Rails 8.1 `Dockerfile` template deletes `bundler/gems/*/.git` after `bundle install` (`railties-8.1.3/lib/rails/generators/rails/app/templates/Dockerfile.tt`, the `RUN bundle install && rm -rf ...` line), so `version.rb`'s `git rev-parse` finds nothing there, `VERSION` is `0.1.0`, and the cache name never changes. The intent requires a new cache name whenever a host moves to a new appkit SHA, so stale PWA caches are cleared.
- A new PORO, `Appkit::Revision` (`lib/appkit/revision.rb`), takes the loaded gem spec as an injected `spec:` argument. `#to_s` returns the spec source's `revision` when the spec is present and its source responds to `revision` (Bundler `Source::Git`, the full 40-character SHA from the host's `Gemfile.lock`, no `.git` needed); else `Appkit::VERSION`. Checked on `8ffa328`: `Gem.loaded_specs["mvpa-css"].source` is a `Bundler::Source::Git` and `.revision` returns the full SHA. In appkit's own repository the source is `Bundler::Source::Gemspec` (no `revision`), so the `VERSION` fallback applies and still names the commit through git.
- `Appkit.revision` in `lib/appkit.rb` memoizes `Revision.new(spec: Gem.loaded_specs["appkit"]).to_s`; `lib/appkit.rb` requires `appkit/revision`. `app/views/appkit/pwa/service_worker.js.erb:1` becomes `const CACHE_NAME = 'appkit-<%= Appkit.revision %>';`.
- `Appkit::VERSION` itself does not change; nothing else reads `Appkit.revision`.
- CI (`.github/workflows/ci.yml`) resolves, then installs with rv, with a gem cache. setup-rv's `install-gems: true` runs `BUNDLE_PATH=vendor/bundle rv ci` (`spinel-coop/setup-rv` `action.sh`, `install_gems`), and `rv ci` needs a `Gemfile.lock`. So each of the three jobs (`scan_ruby`, `lint`, `test`) runs:
  1. setup-rv with `ruby-version: current` only, step `id: ruby`.
  2. A `Resolve gems` step, `id: gems`: `bundle lock`, then `echo "hash=$(grep -v '^ *appkit (' Gemfile.lock | sha256sum | cut -d' ' -f1)" >> "$GITHUB_OUTPUT"`.
  3. `actions/cache@v5` on `vendor/bundle`, key `gems-${{ runner.os }}-${{ runner.arch }}-ruby-${{ steps.ruby.outputs.ruby-version }}-${{ steps.gems.outputs.hash }}`, restore-key the same without the hash.
  4. An `Install gems` step: `BUNDLE_PATH=vendor/bundle rv ci`, then `echo "BUNDLE_PATH=vendor/bundle" >> "$GITHUB_ENV"`. This mirrors setup-rv's own `install_gems`.
- Why the cache key drops the appkit lines: the resolved lockfile names the commit (`appkit (0.1.0.pre.git.<sha>)` under `PATH` and `CHECKSUMS`). A plain `hashFiles('Gemfile.lock')` key misses on every commit and saves a new cache entry each run. Without those lines the key changes only when a gem version changes.
- The `lint` job's RuboCop cache key becomes `DEPENDENCIES_HASH: ${{ hashFiles('**/.rubocop.yml') }}-${{ steps.gems.outputs.hash }}`. Same meaning as today (config plus gem versions), without the per-commit appkit line.
- One short comment above `jobs:` in `ci.yml` says why: appkit does not commit `Gemfile.lock`, so each job resolves one first.
- `bin/bundler-audit` is added (criterion: "after a fresh clone, `bin/bundler-audit` runs"; it does not exist today). It follows the Rails 8.1 template (`railties-8.1.4/lib/rails/generators/rails/app/templates/bin/bundler-audit.tt`) with a `#!/usr/bin/env ruby` shebang, but requires `../test/dummy/config/boot` as `bin/rails` does, because the engine root has no `config/boot.rb`. File mode 755. `config/bundler-audit.yml` is added with the Rails template comment and `ignore: []` (not the template's placeholder CVE).
- CI's `scan_ruby` runs `bin/bundler-audit check --update` instead of `bundle exec bundler-audit check --update`, so CI and a local run read the same `config/bundler-audit.yml`.
- `.github/workflows/rails-ci.yml` does not change. It runs inside host apps, which commit their own `Gemfile.lock`; it never reads appkit's. `AGENTS.md` also forbids making it need anything new from apps. The intent approves editing it "so CI works without a committed lockfile"; nothing there depends on appkit's lockfile, so the approval is unused. This matches the `stable-gem-version` plan, which Etienne confirmed on 2026-10-07.
- The lefthook `migrations` → `bundle` step is overridden in `lefthook-local.yml`: `run: bundle lock && rv ci`, `glob: ["Gemfile", "appkit.gemspec"]`. The shared command runs `rv ci` whenever a `Gemfile.lock` exists, and here that file is untracked and can be stale: `rv ci` alone would install the stale set and miss what `Gemfile` or the gemspec now need. `bundle lock` keeps the locked versions and adds what is missing, and `rv ci` installs the result. This is the same pair `bi` and CI run. The gemspec joins the glob because a gemspec change no longer changes any tracked `Gemfile*` file.
- The pre-push `bundle-audit` hook stays skipped: re-enabling it is out of scope in the amended intent. This differs from the `stable-gem-version` plan, which un-skipped it. The comment above the brakeman and bundle-audit skips is reworded, because `bin/bundler-audit` now exists: brakeman has no binstub, and CI already runs bundler-audit.
- README gets a `## Development` section, before `## Continuous Integration`: appkit does not commit `Gemfile.lock`; why (the version names its commit, and a committed lockfile can never name its own commit; host apps read only `appkit.gemspec`); a fresh clone and every CI run resolve the newest gems that `appkit.gemspec` and `Gemfile` allow, so two runs on one commit can use different gem versions; an existing local lockfile stays untracked and keeps its versions, and `bundle update` moves it to newer gems.
- Conflict flagged against the intent: its outcome says local runs install the newest allowed gems. That holds for a fresh clone and CI only. An existing checkout keeps its untracked lockfile, because `bundle lock` (in the hook and in `bi`) keeps locked versions, and playbook rule 11 forbids agents a bare `bundle update`. Etienne accepted this for the `stable-gem-version` plan (2026-10-07); this plan keeps it.
- CHANGELOG, nit 5: one `### Fixed` line: the service worker cache name now changes with every appkit commit, also in hosts whose Docker build deletes the gem's `.git` directory. No upgrade step: the name changes by itself. The lockfile and `ci.yml` changes are contributor-only and get no line (`AGENTS.md`).
- Rejected: a stable `VERSION = "0.1.0"` (this plan's previous nit 5). The amended intent keeps the SHA in the version. Rejected: a git fallback inside `Revision`; `VERSION` already runs it.

### Nit 3: `bin/rails test`

- Add `ENGINE_ROOT = File.expand_path("..", __dir__)` to `bin/rails`, after `APP_PATH`, before the `require_relative`. `Rails::Command.root` returns `ENGINE_ROOT` when it is defined, else `test/dummy` (`railties-8.1.4/lib/rails/command.rb:102`). `rails test` appends `Rails::Command.root.join("test")` to `$LOAD_PATH` (`rails/commands/test/test_command.rb:29`), so today it adds `test/dummy/test` and misses `test/test_helper.rb`. Checked in scratch clones: with the line, `bin/rails test` (126 runs), `bin/rails test test/controllers` (31 runs) and `bin/rails test test/appkit_test.rb` (2 runs) all pass.
- Keep `require_relative "../test/dummy/config/boot"` and `require "rails/commands"`; do not switch to the full plugin template (`rails/engine/commands`). One line is the smallest change that works.
- Side effect: `bin/rails generate` now targets the engine root, not `test/dummy`, as in a generated Rails plugin. No hook or workflow calls the engine's `bin/rails generate`. The README's `bin/rails generate appkit:install` is a host-app command and uses the host's own binstub, so this change does not touch it. `bin/rails app:update:bin` (run by `bi`) still writes into `test/dummy/bin/`, before and after the change (checked).
- Remove `minitest: skip: true` from `pre-push` in `lefthook-local.yml`. The shared hook already maps `app/controllers/appkit/pwa_controller.rb` to `test/controllers/appkit/pwa_controller_test.rb` and runs `bin/rails test` on it.

### Nit 2: erb_lint

- Add `spec.add_development_dependency "erb_lint"` to `appkit.gemspec`, after `solid_cache`, matching the other development dependencies (no version constraint, like them). Approved in the intent. In a scratch clone it resolved to 0.9.0. Nit 5 lands first, so this commit has no `Gemfile.lock` change.
- New `.erb_lint.yml`: `EnableDefaultLinters: true`; `glob: "app/**/*.erb"`, so `--lint-all` covers exactly the 12 engine ERB files under `app/` (the two non-HTML ones too) and never reaches `.worktrees/`, `tmp/` or `test/dummy`. Enable the `Rubocop` linter with `rubocop_config: inherit_from: [.rubocop.yml]` and the cops erb_lint's README turns off for ERB: `Layout/InitialIndentation`, `Layout/LineLength`, `Layout/TrailingEmptyLines`, `Layout/TrailingWhitespace`, `Naming/FileName`, `Style/FrozenStringLiteralComment`, `Lint/UselessAssignment`, `Rails/OutputSafety`.
- Why include the two non-HTML files: in a scratch clone, erb_lint on `service_worker.js.erb` and `manifest.json.erb` raised only RuboCop offenses (`Layout/SpaceInsideArrayLiteralBrackets` on `service_worker.js.erb:2`), no false positives from the HTML linters.
- Known offenses to fix (scratch clone, config above): `Layout/SpaceInsideArrayLiteralBrackets` in `app/views/appkit/preferences/edit.html.erb` lines 22, 36, 41, 45 and `app/views/appkit/pwa/service_worker.js.erb:2`; `Style/StringLiterals` in `app/views/appkit/shared/_confirm_dialog.html.erb` lines 4 and 5. Fix them in the views; never add a disable comment or relax `.erb_lint.yml` to pass.
- `lefthook-local.yml`: drop `erb_lint: skip: true` from both hooks and override `run`; keep the inherited globs (`*.{erb}`, `*.erb`), which match nested files (checked: `lefthook run pre-commit --no-auto-install --command erb_lint --file app/views/appkit/shared/_skip_link.html.erb -f` runs the command). Override `run` to `bundle exec erb_lint {staged_files}` (pre-commit) and `bundle exec erb_lint {push_files}` (pre-push). Why `bundle exec`: the RuboCop linter inherits `rubocop-eirvandelden`, a git-sourced gem that only Bundler can load. The shared `lefthook.yml` stays untouched; it is a copy of the dotfiles one.

### Nit 1: `include Appkit::Authentication`

- New generator step `add_authentication_to_application_controller` in `lib/generators/appkit/install/install_generator.rb`, after `create_push_subscriptions_migration`. It calls `inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include Appkit::Authentication\n"`.
- Guard clauses: return when the host file does not exist (the existing generator tests run without one, and a host without that file has nothing to fix), and return when the file already matches `/^\s*include\s+Appkit::Authentication\b/`. The second guard makes a second run a no-op even when the host wrote the include with different spacing. Thor's own duplicate check only matches the exact string.
- README `## Installation`: ordered steps after the Gemfile lines: run `bundle install`, run `bin/rails generate appkit:install`, run `bin/rails db:migrate`. These are host-app commands for humans; the agent install guard does not apply to README text. Put `include Appkit::Authentication` inside the existing `class ApplicationController` snippet, above `allow_browser`. Say in one line why: most engine controllers inherit the host's `::ApplicationController` and call `allow_unauthenticated_access` or `require_unauthenticated_access` as class methods, and `Appkit::Authentication` defines both, plus the default `require_authentication` filter (`app/controllers/concerns/appkit/authentication.rb`).
- No change to authentication behaviour itself (out of scope).

### Nit 4: unwrap prose

- Join hard-wrapped lines in `CHANGELOG.md` and `README.md` prose so each paragraph, list item and block quote sits on one line. Code fences and tables stay byte-for-byte. A line break inside inline code (README: `` `bundle\ninstall` ``) becomes a space.
- Do this as one commit with no wording change, so the diff is reviewable with `git diff --word-diff`.
- Nit 4 runs after nit 5 and before nit 1, so the new README `## Development` text and the Installation edit are written on one line from the start, and the unwrap commit stays wording-free.

### Nit 6: `### Upgrading`

- Follow `AGENTS.md` "Upgrade instructions" (merged from PR #14): one `### Upgrading` subsection in `## Unreleased`, after `### Added`, `### Changed` and `### Fixed`; a numbered list, one instruction per step, an exact command where one exists, in the order an app runs them; only steps read in the code.
- The #15 `### Fixed` entry keeps its description of what changed. Its host instruction ("check that none of them redirects or blocks these two endpoints") moves to `### Upgrading` as: "Check that no `before_action` in your `ApplicationController` redirects or blocks `GET /manifest` or `GET /service-worker`; both now inherit it." Paths from `config/routes.rb`.
- Nit 5 adds one `### Fixed` line (above). Nit 1 adds:
  - `### Fixed`: following the README or running the install generator no longer leaves engine pages raising `NoMethodError` for `allow_unauthenticated_access`.
  - `### Upgrading`: "Run `bin/rails generate appkit:install --skip` to add `include Appkit::Authentication` to `ApplicationController` when it is missing." Before writing it, prove in a generator test that `--skip` still runs the inject step (Thor's `--skip` only skips file collisions).
- Nits 2, 3 and 4 are contributor-only and get no CHANGELOG line (`AGENTS.md`: test-only and lint changes add no upgrade step).

## Integration points

- GitHub Actions: `spinel-coop/setup-rv@main` (output `ruby-version`), `actions/cache@v5`, `rv ci`, Bundler 4 `bundle lock`.
- Bundler 4 runtime API: `Gem.loaded_specs`, `Bundler::Source::Git#revision`.
- Bundler-audit and the ruby-advisory-db, through the new `bin/bundler-audit`.
- Rails 8.1.4 command root resolution (`Rails::Command.root`, `rails test`).
- Thor's `inject_into_class` through `Rails::Generators::Base`.
- erb_lint 0.9.0 with RuboCop and `rubocop-eirvandelden` (git-sourced).
- Lefthook 2.2 through the global `core.hooksPath`; `lefthook-local.yml` merges over `lefthook.yml`. Always pass `--no-auto-install` to `lefthook run`: a plain run overwrites the stow-managed global hooks.
- `bi` (`~/.local/bin/bi`), the agents' gem installer.
- Host apps: README, install generator, CHANGELOG, service worker cache name. Their gem version format stays the same.

## Files that change

- `.gitignore` — add `/Gemfile.lock`.
- `Gemfile.lock` — removed from the index (`git rm --cached`); stays on disk, ignored.
- `test/lockfile_test.rb` — new; proves the lockfile is untracked and ignored.
- `test/appkit_test.rb` — "version is present" becomes "version names the checked-out commit".
- `test/controllers/appkit/pwa_controller_test.rb` — "service worker cache name includes the engine version" becomes "service worker cache name includes the appkit revision".
- `lib/appkit/revision.rb` — new `Appkit::Revision` PORO.
- `lib/appkit.rb` — `require "appkit/revision"`; `Appkit.revision`.
- `test/appkit/revision_test.rb` — new unit tests for `Appkit::Revision`.
- `bin/bundler-audit` — new binstub, mode 755.
- `config/bundler-audit.yml` — new; Rails template comment, `ignore: []`.
- `.github/workflows/ci.yml` — per job: Ruby-only setup-rv, `bundle lock` with the hash output, gem cache, `rv ci`; RuboCop cache key; `bin/bundler-audit`; one comment above `jobs:`.
- `bin/rails` — `ENGINE_ROOT`.
- `appkit.gemspec` — `erb_lint` development dependency.
- `.erb_lint.yml` — new.
- `app/views/appkit/pwa/service_worker.js.erb` — cache name from `Appkit.revision` (nit 5); erb_lint fix on line 2 (nit 2).
- `app/views/appkit/preferences/edit.html.erb`, `app/views/appkit/shared/_confirm_dialog.html.erb` — erb_lint fixes only.
- `lefthook-local.yml` — `migrations.bundle` override (nit 5), skip comment reworded (nit 5), erb_lint skips removed and `run` overridden with `bundle exec` (nit 2), `minitest` skip removed (nit 3).
- `lib/generators/appkit/install/install_generator.rb` — `add_authentication_to_application_controller`.
- `test/generators/appkit/install_generator_test.rb` — new tests for the inject.
- `README.md` — `## Development` (nit 5); unwrap (nit 4); Installation (nit 1).
- `CHANGELOG.md` — nit 5 `### Fixed` line; unwrap (nit 4); `### Upgrading` (nit 6); nit 1 `### Fixed` and `### Upgrading` lines.

## Order of work

Run the narrowest test first. Use `bin/rails test <file>` once nit 3 has landed; before it, use `bundle exec ruby -Itest <file>`. Until nit 5's untrack commit lands, any `bundle exec` rewrites the `appkit (0.1.0.pre.git.<sha>)` lines in `Gemfile.lock`: run `git checkout -- Gemfile.lock` before each commit until then, and never commit that drift. Delete an untracked `test/dummy/bin/` left by `bi` before every `git status` check.

0. Rebase onto `origin/main` with the `sync` skill (`git fetch origin`, `git rebase origin/main`, `git push --force-with-lease`). `main` gained `AGENTS.md` and `CLAUDE.md` from PR #14; no conflict is expected.
1. Nit 5, walking skeleton. Write `test/lockfile_test.rb`: "Gemfile.lock is not tracked by git" (`git -C <engine root> ls-files Gemfile.lock` prints nothing) and "git ignores Gemfile.lock" (`git -C <engine root> check-ignore Gemfile.lock` prints the path). Run it; watch both fail (the file is tracked, and `check-ignore` never reports a tracked file).
2. Add `/Gemfile.lock` to `.gitignore`; `git rm --cached Gemfile.lock`. Run the test: green. Commit both with the test.
3. Replace "version is present" with "version names the checked-out commit": `assert_equal "#{Appkit::BASE_VERSION}.pre.git.#{sha}", Appkit::VERSION`, `sha` from `git -C <engine root> rev-parse --short HEAD`. It passes at once: it pins existing behaviour that this change must keep. Commit.
4. Write `test/appkit/revision_test.rb` (names under Proof). Fake specs are `Data` or `Struct` values with a `source`; the source has a `revision` or not. Change the PWA test to "service worker cache name includes the appkit revision": `assert_includes response.body, "const CACHE_NAME = 'appkit-#{Appkit.revision}'"`. Run both; watch them fail (`uninitialized constant Appkit::Revision`, `undefined method 'revision'`).
5. Implement `lib/appkit/revision.rb`, `Appkit.revision` and the service worker line 1. Run both files, then `bundle exec rake test` and `bundle exec rubocop`. Add the nit 5 `### Fixed` line to `CHANGELOG.md` (one line). Commit.
6. Add `bin/bundler-audit` (mode 755) and `config/bundler-audit.yml`. Run `bin/bundler-audit check --update` and `bin/bundler-audit --config config/bundler-audit.yml` (the shared hook's form): both exit 0. `bundle exec rubocop bin/bundler-audit`. Commit.
7. Edit `lefthook-local.yml`: the `migrations.bundle` override and the reworded skip comment. Check: `lefthook dump` shows `migrations.commands.bundle` with the new `run` and glob, and `pre-push.bundle-audit` still skipped; `yamllint lefthook-local.yml`. Commit.
8. Edit `.github/workflows/ci.yml` as under Design decisions. `yamllint .github/workflows/ci.yml` (warnings only, as today). Commit.
9. Add the README `## Development` section, one line per paragraph. Commit.
10. Nit 5 fresh-clone check (Proof). In the session scratchpad: `git clone --branch appkit-follow-up-nits <worktree path> <scratch>/clone`, `cd` there, `test ! -e Gemfile.lock`, `lefthook run migrations --no-auto-install --command bundle --force`, `git status --porcelain` (prints nothing; `Gemfile.lock` now exists, ignored), `bin/bundler-audit check --update`, `git commit --allow-empty -m tmp --no-verify`, `bundle exec rake test`, `git status --porcelain` (prints nothing). If lefthook stops because the clone has no `ORIG_HEAD`, run `git update-ref ORIG_HEAD HEAD~1` in that clone only, then retry.
11. Nit 3. Run `bin/rails test test/appkit_test.rb`; watch it fail with `cannot load such file -- test_helper`. Add `ENGINE_ROOT` to `bin/rails`. Run `bin/rails test test/appkit_test.rb`, `bin/rails test test/controllers`, `bin/rails test`, `bundle exec rake test`: all pass. Remove the `minitest` skip from `lefthook-local.yml`. Check: `lefthook dump` shows `pre-push.minitest` without `skip`; `yamllint lefthook-local.yml`. Commit.
12. Nit 3 hook check: `lefthook run pre-push --no-auto-install --command minitest --file app/controllers/appkit/pwa_controller.rb --force` prints "Running minitest for app/controllers/appkit/pwa_controller.rb..." and passes.
13. Nit 2. Add `erb_lint` to `appkit.gemspec`; `bundle lock && rv ci`. Write `.erb_lint.yml`. Run `bundle exec erb_lint --lint-all`; watch it report the known offenses listed under Design decisions. Fix the three views. Run `bundle exec erb_lint --lint-all`: exit 0. Run `bin/rails test test/controllers` and `bin/rails test test/integration` (the views render there). Edit `lefthook-local.yml`; `lefthook dump`; `yamllint lefthook-local.yml .erb_lint.yml`. Commit (the view fixes may be their own commit).
14. Nit 2 hook check: copy `app/views/appkit/shared/_skip_link.html.erb` to a scratch-named file in `app/views/appkit/shared/`, add `<%= foo 'x' %>`, then `lefthook run pre-commit --no-auto-install --command erb_lint --file <that file> --force`: it fails. Delete the file. Then the same command on `app/views/appkit/shared/_skip_link.html.erb` passes.
15. Nit 4. Unwrap `CHANGELOG.md` and `README.md` prose. Check: `git diff --word-diff=porcelain` shows only joined lines; no line inside a fence or table changed. Commit.
16. Nit 6. Move the #15 host step into a new `### Upgrading` at the end of `## Unreleased`. Commit.
17. Nit 1. Write the generator tests (names under Proof); run `bin/rails test test/generators/appkit/install_generator_test.rb`; watch the inject tests fail. Implement the generator step. Run the file, then `bin/rails test`. Edit the README Installation section and add the `### Fixed` and `### Upgrading` lines (one line each). Commit.
18. Full checks: `bin/rails test`, `bundle exec rake test`, `bundle exec rubocop`, `bundle exec erb_lint --lint-all`, `yamllint lefthook-local.yml .erb_lint.yml .github/workflows/ci.yml config/bundler-audit.yml`, both Brakeman scans from `ci.yml` (`bundle exec brakeman -p test/dummy --no-pager --ignore-config config/brakeman.ignore`, `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`), `bin/bundler-audit check --update`. Then `git status --porcelain` prints nothing.
19. Re-read the full diff against `origin/main`; every hunk serves one of the six nits.
20. After `finish` opens the pull request: `gh pr checks --watch`; `scan_ruby`, `lint` and `test` are green. The pull request description names the `AGENTS.md` lines this change makes stale (see Risks).

## Risks

- A new gem release can turn CI red on an unchanged commit. The intent accepts this.
- Hosts that install from GitHub see a one-time cache rotation: the name changes format from `appkit-0.1.0.pre.git.<short sha>` (or `appkit-0.1.0` in Docker) to `appkit-<full sha>`. The service worker's `activate` handler deletes old caches, so this is harmless.
- A host on a `path:` or released-gem install has no Bundler git revision; its cache name stays `appkit-<VERSION>`, as today.
- `Gem.loaded_specs["appkit"]` is `nil` when appkit loads without RubyGems or Bundler knowing it (for example `-Ilib`). `Revision` treats a `nil` spec as "no Bundler revision" and returns `VERSION`.
- Pulling this change into an existing checkout deletes its local `Gemfile.lock`, because git removes a file that stops being tracked. The next `bi`, or the post-merge bundle step, writes it again.
- Open branches that still change `Gemfile.lock` (`update-dependencies`, `update-mvpa` and others) get a modify/delete conflict when they rebase onto main. Resolve it with `git rm --cached Gemfile.lock`.
- The three CI jobs share one gem cache key; the second and third to finish log "cache already exists". This is harmless; setup-rv behaves the same.
- `config/bundler-audit.yml` ships in the gem, because `spec.files` takes all of `config/**`. It is inert there, as `config/brakeman.ignore` already is.
- `bi` writes an untracked `test/dummy/bin/` (pre-existing). The `git status` checks above delete it first. Ignoring it in `.gitignore` is a separate change.
- `bin/rails generate` now writes into the engine root instead of `test/dummy`. A contributor who relied on the old target must pass paths by hand.
- erb_lint 0.9.0 prints a `parser/ruby33` warning on Ruby 4.0.5. It is noise from the `parser` gem, not an offense; do not silence it with config.
- `AGENTS.md` (now on main) describes the `Gemfile.lock` drift, the `bin/rails test` failure, the `bundle exec bundler-audit` command and the skipped ERB and test hooks. This change makes those lines stale. The intent keeps `AGENTS.md` out of this change and asks only that the pull request description name them.
- The unmerged `stable-gem-version` branch is superseded. Its plan differs in two points: it un-skips the bundle-audit hook, and its bundle step runs `bundle install`.
- Unwrapping touches most README lines, so open branches that edit the README get rebase conflicts.
- Rejected: a stable `VERSION = "0.1.0"` (the amended intent keeps the SHA); hashing the whole resolved lockfile for the CI cache key (misses on every commit); calling setup-rv twice to reuse its cache logic (installs rv twice, depends on its internals); changing `rails-ci.yml` (host apps keep their lockfiles); `bi` as the lefthook bundle command (not in the repository, and it writes `test/dummy/bin/`).

## Out of scope

- `.github/workflows/rails-ci.yml`, and every `ci.yml` change beyond gem resolution, its cache keys and `bin/bundler-audit`; running erb_lint in CI.
- Migrations and system tooling.
- `AGENTS.md` and `CLAUDE.md`.
- Unwrapping markdown other than `CHANGELOG.md` and `README.md`.
- Re-enabling the stylelint, browserslist, eslint, rspec, brakeman and bundle-audit hooks.
- Closing or editing the `stable-gem-version` branch.
- Authentication behaviour itself, and the other host includes (`Appkit::VersionHeaders`, `Appkit::Authorization`).
- Editing the shared `lefthook.yml`.
- Publishing appkit to RubyGems.

## Proof

- A host app whose `ApplicationController` lacks the include gets it after `bin/rails generate appkit:install`, and its sign-in page loads → `test/generators/appkit/install_generator_test.rb` "adds include Appkit::Authentication to an ApplicationController that lacks it"; sign-in page: `test/controllers/appkit/sessions_controller_test.rb` "login layout actually loads JavaScript", against `test/dummy`, whose `ApplicationController` has the same include.
- Running the generator twice leaves exactly one include → `test/generators/appkit/install_generator_test.rb` "running the generator twice leaves one include Appkit::Authentication".
- The README Installation snippet shows the include inside `class ApplicationController` → check: read `README.md` `## Installation` in the diff.
- `bundle exec erb_lint --lint-all` exits 0, and a staged ERB offense fails pre-commit → check: `bundle exec erb_lint --lint-all` exits 0; Order of work step 14.
- `bin/rails test`, `bin/rails test test/controllers`, `bin/rails test test/appkit_test.rb` pass; `bundle exec rake test` passes → check: run all four (Order of work step 11).
- Pushing a change to `app/controllers/appkit/pwa_controller.rb` runs its test in pre-push → check: Order of work step 12.
- Every paragraph and list item in `CHANGELOG.md` and `README.md` prose sits on one line → check: `git diff --word-diff=porcelain` in step 15, and read both files outside fences and tables.
- After a commit, installing gems and `bundle exec rake test` leave `git status` clean → `test/lockfile_test.rb` "Gemfile.lock is not tracked by git" and "git ignores Gemfile.lock"; check: Order of work step 10.
- In a checkout of commit `abc1234`, the appkit version is `0.1.0.pre.git.abc1234` → `test/appkit_test.rb` "version names the checked-out commit".
- `Gemfile.lock` is not in git, and a new one is ignored → `test/lockfile_test.rb` "Gemfile.lock is not tracked by git", "git ignores Gemfile.lock".
- On a push, CI installs gems and runs the tests, RuboCop, Brakeman and bundler-audit → check: the `CI` workflow run on the pull request, `scan_ruby`, `lint` and `test` green (Order of work step 20).
- After a fresh clone, the lefthook bundle step installs gems and `bin/bundler-audit` runs → check: Order of work step 10 exits 0 at every line.
- The README says that appkit does not commit its `Gemfile.lock`, and why → check: read `README.md` `## Development` in the diff.
- Two appkit commits with different SHAs produce different service worker cache names → `test/appkit/revision_test.rb` "two Bundler revisions give two different values" (Dockerized and other git-installed hosts); `test/appkit_test.rb` "version names the checked-out commit" with `test/appkit/revision_test.rb` "falls back to Appkit::VERSION when the source has no revision" (a git checkout); `test/controllers/appkit/pwa_controller_test.rb` "service worker cache name includes the appkit revision".
- `## Unreleased` has one `### Upgrading` after `### Added`, `### Changed` and `### Fixed`, one instruction per step, and `### Fixed` holds no upgrade step → check: read `CHANGELOG.md` in the diff.

Per changed file, the unit tests expected:

- `.gitignore`, `Gemfile.lock`: `LockfileTest` "Gemfile.lock is not tracked by git", "git ignores Gemfile.lock".
- `lib/appkit/version.rb` (unchanged, pinned): `AppkitTest` "version names the checked-out commit".
- `lib/appkit/revision.rb`: `Revision#to_s` "returns the Bundler git revision when the spec has one", "two Bundler revisions give two different values", "falls back to Appkit::VERSION when the source has no revision", "falls back to Appkit::VERSION when there is no spec".
- `app/views/appkit/pwa/service_worker.js.erb`: `Appkit::PwaControllerTest` "service worker cache name includes the appkit revision".
- `lib/generators/appkit/install/install_generator.rb`: "adds include Appkit::Authentication to an ApplicationController that lacks it", "running the generator twice leaves one include Appkit::Authentication", "leaves an ApplicationController that already includes Appkit::Authentication unchanged", "skips the include when the host has no ApplicationController", "adds the include when run with --skip".
- `bin/rails`, `bin/bundler-audit`, `config/bundler-audit.yml`, `.github/workflows/ci.yml`, `lefthook-local.yml`, `.erb_lint.yml`, `appkit.gemspec`, the three views, `README.md`, `CHANGELOG.md`: no unit test; proven by the checks above. A `bin/bundler-audit` test would hit the network and fail on any new advisory.

Test setup: Minitest, no fixtures needed. `Revision` tests inject fake spec objects; no stubs. The lockfile and version tests shell out to `git -C Appkit::Engine.root`; CI's `actions/checkout` gives a git checkout. Generator tests write `app/controllers/application_controller.rb` into the generator's destination with `File.write` before `run_generator`. Minitest 6 ships without `minitest/mock`; use no stubs.

---
Domain skills applied: rails-architecture (no service object; the revision lives on a small PORO), object-oriented-design (dependency injection for `Revision`), rails-testing (Minitest, test first), ruby-style (guard clauses), dependencies (erb_lint approved in intent; no other gem change; installs with `bi` or `bundle lock && rv ci`, never a bare `bundle update`), new-repo-setup (lefthook: never `lefthook install`, `--no-auto-install` on `lefthook run`).

## Critique

### Round 1 (codex exec -p terra)

- The inherited lefthook ERB glob `*.{erb}` matches only root files, so the hook skips nested views; override it with `app/**/*.erb` → dismissed: checked in the scratch clone, `lefthook run pre-commit --no-auto-install --command erb_lint --file app/views/appkit/shared/_skip_link.html.erb -f` with the inherited glob ran the command on that nested file, in both hooks.
- The `--lint-all` glob `**/*.erb` reaches `test/dummy` beyond the intent's 12 engine views, and the `.worktrees/**/*` exclude may not match absolute paths → fixed (`.erb_lint.yml` uses `glob: "app/**/*.erb"` with no excludes)
- The README sequence runs the generator before `bundle install` → fixed (README steps are now `bundle install`, the generator, `bin/rails db:migrate`)
- The README explanation that every engine controller calls `allow_unauthenticated_access` is false (`PreferencesController`, `PushSubscriptionsController`, `SessionsController`) → fixed (the README line now names both class methods and the default filter that `Appkit::Authentication` defines)
- The lockfile test is a brittle meta-test, and an exact `"0.1.0"` assertion cannot observe a new commit → fixed (the lockfile-content test was removed; the version assertion was a format match)
  - Superseded by the intent amendment of `8c30f85`: nit 5 now untracks `Gemfile.lock`. The new `test/lockfile_test.rb` checks git state (tracked, ignored), not lockfile content.
- The README already documents `bin/rails generate appkit:install`, so the claim that no doc calls `bin/rails generate` is wrong → fixed (the rationale now says the README command is a host-app command that the engine binstub change does not touch)

### Round 2 (codex exec -p terra)

- Dockerized git installs keep a static cache name, because `VERSION` falls back to `0.1.0` without `.git`, against the intent's per-SHA rotation → fixed (new `Appkit::Revision` reads Bundler's `Source::Git#revision` first and falls back to `Appkit::VERSION`; the service worker uses `Appkit.revision`; unit tests inject specs, so no `.git` is needed)
- The plan no longer proves that a literal `bundle install` leaves the tree clean → dismissed: playbook rule 11 and its guard refuse `bundle install` for agents, who install with `bi`. The `/Gemfile.lock` ignore rule and `test/lockfile_test.rb` make the result the same whichever command writes `Gemfile.lock`, and the fresh-clone check runs `bundle lock && rv ci`, the path `bi`, the hook and CI share.
- The README claim that local runs resolve the newest allowed gems is false when a local lockfile exists, because `bundle lock` keeps locked versions → fixed (the README text now says a fresh clone and CI resolve the newest gems, and an existing local lockfile keeps its versions until `bundle update`; the conflict with the intent's outcome is flagged under Design decisions)

### Round 3 (codex exec -p terra)

- The README fix still conflicts with the intent's outcome that local runs install the newest allowed gems; amend the intent or refresh an existing local lockfile → dismissed: refreshing an existing lockfile on every hook run is an implicit `bundle update` of all gems, which playbook rule 11 forbids without instruction, and Etienne accepted the same limit for the `stable-gem-version` plan on 2026-10-07. The plan keeps it and reports it to Etienne as an open decision, so he can amend the intent instead.
