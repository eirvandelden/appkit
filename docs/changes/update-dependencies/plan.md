# Plan: Update all dependencies to their latest stable versions

From `intent.md` (2026-10-06). Status: accepted.

## Context

Appkit is a non-isolated Rails engine (personal project: Minitest, fixtures, `gem.coop`). Its locked gems, Ruby, Bundler and three GitHub Actions are behind their latest stable releases. Its gemspec floors accept versions it is never tested against. This change moves everything appkit controls to its latest stable version and raises the gemspec floors to the tested minors. Only marcel stays behind, because Active Storage holds it at `~> 1.0`.

Baseline on `main` (778080c), measured 2026-10-06 under Ruby 4.0.5 and Bundler 4.0.16:

- `bundle exec rake test`: 103 runs, 0 failures, 0 errors, 0 lines that match `deprecat`.
- `bundle exec rubocop`: 82 files, no offenses.
- Both Brakeman scans: no warnings. `bundler-audit check --update`: no vulnerabilities.
- `bundle outdated`: 23 gems. `bundle outdated --strict` lists 22: every one except marcel is reachable under the current constraints.
- Ruby 4.0.7 is installed through rv. Its default Bundler is 4.0.20, so Bundler 4.0.22 needs the one install the intent approves.
- Latest tags upstream: checkout `v7.0.1`, cache `v6.1.0`, setup-node `v7.0.0`, upload-artifact `v7.0.1`. mvpa.css HEAD is `412cc74`, rubocop-eirvandelden HEAD is `1e2e033`.

## Design decisions

- Proof by command, not by a committed test. No Ruby behaviour changes, so there is no unit to test. The `rails-testing` skill forbids meta-tests that assert configuration or repo plumbing, and a test that reads `appkit.gemspec` and checks `satisfied_by?` is exactly that. The real behaviour is "Bundler refuses to resolve appkit next to Rails 8.0". A scratch `bundle lock` proves that end to end. This matches how the earlier `rails-8-1-4` and `remove-cspell` changes were proven. Conflict flagged: playbook rule 3 ("never generate code without a corresponding test") against `rails-testing` ("no meta-tests"). Chosen side: `rails-testing`, because the change is configuration only.
- Name the gems in `bundle update`. The `dependencies` skill and playbook rule 11 forbid an unnamed `bundle update`. Each `bundle update` below names its gems, so marcel is never asked to move.
- Floors versus "do not pin". The `dependencies` skill says "do not pin gem versions by default". That advice is for an app's Gemfile. A gemspec floor is the engine's promise to consuming apps, and the intent already chose `~> major.minor` floors. No conflict to resolve here, only noted.
- Order: the gemspec floors come first, right after the walking skeleton, so the one red acceptance check turns green early. The Ruby and Bundler bumps follow, so every gem update after them runs on the final toolchain.
- The `appkit (0.1.0.pre.git.<sha>)` lines in `Gemfile.lock` change on every bundle command, because `lib/appkit/version.rb` embeds the short HEAD SHA. That is existing behaviour. In a commit that changes `Gemfile.lock` for its own reason, keep the SHA lines as Bundler writes them. In any other commit, restore `Gemfile.lock` first (`git checkout -- Gemfile.lock`) so a SHA-only diff never lands.
- Commits: one logical change each (playbook rule 18). Seven commits are expected; offense or deprecation fixes add one commit per cop or per deprecation.
- Findings appkit cannot fix in its own code (Etienne's choice, 2026-10-06): document them in the PR description and continue. That covers a deprecation raised inside a third-party gem and a Brakeman false positive. Never patch the gem, never silence the warning, never add an ignore-file entry. Consequence: a Brakeman warning makes the scan exit non-zero, so A4 and A5 stay red and the change is not done until Etienne decides on that warning in the PR.

## Integration points

- Consuming apps resolve appkit through the gemspec. After this change an app on Rails 8.0 cannot install appkit.
- Consuming apps call `.github/workflows/rails-ci.yml` as a reusable workflow. They get checkout `@v7`, cache `@v6` and setup-node `@v7` on their next CI run after merge.
- `spinel-coop/setup-rv@main` with `ruby-version: current` reads `.ruby-version`, so CI moves to Ruby 4.0.7 through that file alone. It stays on `@main` (out of scope).
- `rubocop-eirvandelden` sets `NewCops: enable`, so new cops in rubocop-rails 2.38, rubocop-performance 1.27 and rubocop-minitest 0.41 fire immediately.
- lefthook pre-commit runs RuboCop on staged `*.rb` files and yamllint on staged `*.yml` files. Pre-push skips Brakeman and bundler-audit (`lefthook-local.yml`), so run both by hand (playbook §4).

## Files that change

- `appkit.gemspec` — runtime floors: railties `>= 8.0` → `~> 8.1`, turbo-rails `>= 2.0` → `~> 2.0`, importmap-rails `>= 1.0` → `~> 2.2`, web-push `~> 3.0` → `~> 3.1`, rqrcode `~> 3.0` → `~> 3.2`, okcomputer `~> 1.19` → `~> 1.20`. Development floor: rails `>= 8.0` → `~> 8.1`.
- `CHANGELOG.md` — new `### Changed` section under `## Unreleased`, after `### Added`, with one single-line entry (playbook rule 26): appkit now requires Rails 8.1, and the gemspec floors are railties `~> 8.1`, turbo-rails `~> 2.0`, importmap-rails `~> 2.2`, web-push `~> 3.1`, rqrcode `~> 3.2` and okcomputer `~> 1.20`, so apps on Rails 8.0 can no longer install appkit. No Ruby requirement in the entry.
- `.ruby-version` — `ruby-4.0.5` → `ruby-4.0.7`.
- `Gemfile.lock` — PATH block floors, `rails (~> 8.1)` in DEPENDENCIES, every outdated gem except marcel, both GIT revisions, the bundler checksum line and `BUNDLED WITH 4.0.22`.
- `.github/workflows/ci.yml` — `actions/checkout@v6.0.3` → `@v7` (3 places), `actions/cache@v5` → `@v6` (1 place).
- `.github/workflows/rails-ci.yml` — `actions/checkout@v6.0.3` → `@v7` (5 places), `actions/cache@v5` → `@v6` (1 place), `actions/setup-node@v6` → `@v7` (1 place). `actions/upload-artifact@v7` stays.
- `app/`, `lib/`, `test/` Ruby files — only if a new RuboCop offense or a deprecation warning forces a fix. None is known yet.

## Acceptance checks

These are the commands the Proof section points to. Run them from the worktree root. `$SCRATCH` is the session's scratchpad directory, never the repository.

- A1 `bundle outdated`: the table holds exactly one row, marcel. Then restore SHA-only lockfile churn.
- A2 Rails resolution. Write `$SCRATCH/rails-8-0/Gemfile` with `source "https://gem.coop"`, `gem "rails", "~> 8.0.0"` and `gem "appkit", path: "<worktree root>"`. Run `BUNDLE_GEMFILE=$SCRATCH/rails-8-0/Gemfile bundle lock`: it must exit non-zero with a resolution error that names railties. Do the same in `$SCRATCH/rails-8-1` with `"~> 8.1.0"`: it must exit 0.
- A3 `ruby -v` prints 4.0.7. `set -o pipefail; RUBYOPT=-W:deprecated bundle exec rake test 2>&1 | tee $SCRATCH/test.log`: exit 0, 0 failures, 0 errors. `grep -ci deprecat $SCRATCH/test.log` prints 0. A line whose source is a third-party gem's own file counts as documented, not as a failure, once the PR description lists it.
- A4 `bundle exec rubocop`: no offenses. `bundle exec brakeman -p test/dummy --no-pager --ignore-config config/brakeman.ignore` and `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`: no warnings. `bundle exec bundler-audit check --update`: no vulnerabilities. `git diff main -- .rubocop_todo.yml config/brakeman.ignore config/brakeman.gem.ignore` is empty. `git diff main | grep -E '^\+.*(rubocop:(disable|todo))'` is empty.
- A5 After the PR is open: `gh pr checks --watch` reports scan_ruby, lint and test as pass.
- A6 `grep -hn 'uses: actions/' .github/workflows/*.yml | sort | uniq -c`: only `checkout@v7`, `cache@v6`, `setup-node@v7`, `upload-artifact@v7`.
- A7 `tail -1 Gemfile.lock` prints `   4.0.22` under `BUNDLED WITH`. `cat .ruby-version` prints `ruby-4.0.7`.
- A8 `sed -n '/^## Unreleased/,$p' CHANGELOG.md` shows a `### Changed` section whose entry says appkit requires Rails 8.1.

## Order of work

1. Walking skeleton. On the unchanged tree, run A2 and watch it fail: the Rails 8.0 lock succeeds today. Run A1, A6 and A7 too and record them red. Restore SHA-only lockfile churn.
2. Gemspec floors. Edit `appkit.gemspec`. Run `bundle install`; okcomputer must move to 1.20.0 because the floor forces it. If Bundler refuses, run `bundle update okcomputer --conservative`. Run A2: now green. Add the CHANGELOG entry; A8 green. Run A3 (on Ruby 4.0.5 still) and A4. Commit `appkit.gemspec`, `Gemfile.lock` and `CHANGELOG.md`: "Require Rails 8.1 and the tested dependency minors".
3. Ruby 4.0.7. Set `.ruby-version` to `ruby-4.0.7`. In a new shell, `ruby -v` must print 4.0.7. If it does not, stop and report (playbook rule 8); do not fix rv. Run `bundle install`, then A3 and A4. Restore SHA-only lockfile churn. Commit `.ruby-version` alone: "Use Ruby 4.0.7".
4. Bundler 4.0.22. Under Ruby 4.0.7, run `gem install bundler -v 4.0.22` (the one install the intent approves). Run `bundle update --bundler=4.0.22`. Check the diff: only `BUNDLED WITH`, the bundler checksum line and the appkit SHA lines change. `bundle -v` prints 4.0.22. A7 green. Commit `Gemfile.lock`: "Lock Bundler 4.0.22".
5. Registry gems. Run `bundle update bigdecimal brakeman et-orbi fugit io-console jwt lefthook net-imap net-protocol net-smtp parallel rdoc regexp_parser rubocop-minitest rubocop-performance rubocop-rails solid_queue unicode-display_width unicode-emoji`. Check the diff: marcel stays 1.2.1, nothing else regresses. Commit `Gemfile.lock`: "Update locked gems to their latest versions". Then run A4. Fix each new RuboCop offense in code, one commit per cop: "Fix <Cop> offenses". Fix each new Brakeman warning in code, one commit each. A Brakeman false positive goes into the PR description and the work continues (see Design decisions).
6. Personal git gems. Run `bundle update mvpa-css rubocop-eirvandelden`. The GIT revisions must read `412cc74…` and `1e2e033…`, or a newer HEAD if one landed since 2026-10-06; name a newer SHA in the PR description. Run A3 and A4. Commit `Gemfile.lock`: "Update mvpa-css and rubocop-eirvandelden to their latest commits".
7. GitHub Actions. Edit both workflow files as listed above. yamllint runs in pre-commit. Run A6. Commit both files: "Bump GitHub Actions to their latest majors".
8. Deprecation sweep. Run A3 on the final tree. Fix each deprecation that comes from appkit's own code, one commit each. Record each deprecation that comes from inside a third-party gem, with gem, version and message, for the PR description, and continue.
9. Final check. Run A1 to A4 and A6 to A8; all green. Restore SHA-only lockfile churn. Re-read `git diff main` hunk by hunk (playbook rule 21). Push, open the PR against origin (no PR template exists), run A5.

## Risks

- New cops. `NewCops: enable` plus three RuboCop plugin minors can surface offenses in `app/`, `lib/` and `test/`. They must be fixed in code: no disable comments, no `.rubocop_todo.yml` entries. A cop that demands a public-API rename (like the `SessionExpiryJob` case already in `.rubocop_todo.yml`) is a stop-and-ask.
- New Brakeman checks. Brakeman 8.0 → 8.1 can add warnings. Fix in code. A false positive goes into the PR description, never into an ignore file, and it keeps CI red until Etienne decides.
- Third-party deprecations. A warning raised inside a gem cannot be fixed in appkit. List it in the PR description and continue; never patch or silence it.
- Consumer CI. checkout v7 refuses to check out fork PRs under `pull_request_target` and `workflow_run`. appkit's CI uses `pull_request` and `push`, so it is unaffected. A consuming app that calls `rails-ci.yml` from one of those triggers breaks. setup-node v7 and upload-artifact only run in consuming apps, so their CI proves them, not appkit's.
- Bundler in CI. Ruby 4.0.7 ships Bundler 4.0.20. With `BUNDLED WITH 4.0.22`, Bundler may install 4.0.22 and restart on each CI job. That costs seconds, not correctness; A5 proves it.
- Okcomputer floor. `~> 1.20` forces okcomputer 1.20.0 in step 2, before the bulk update. That is intended: the floor and the lock move together.
- Lockfile SHA churn. Forgetting to restore `Gemfile.lock` lands a SHA-only diff. The rule in Design decisions covers it.
- Rejected: a `test/gemspec_test.rb` that asserts the floors (meta-test, see Design decisions). Rejected: making Rails deprecations raise in the dummy app's test environment (a guard beyond this intent's scope).

## Out of scope

- marcel 1.2.1 → 2.1.0 (Active Storage holds it at `~> 1.0`).
- `spinel-coop/setup-rv@main` (no releases).
- A Dependabot config.
- Any engine behaviour change beyond what an update forces.
- `config.active_support.deprecation = :raise` in the dummy app.
- The SHA embedded in `Appkit::VERSION`, which churns `Gemfile.lock`. Propose it as a separate change if wanted.
- The local machine's duplicate rdoc installs that print "already initialized constant" warnings under `gem env`. Machine state, not repository state.

## Proof

- `bundle outdated` lists only marcel → A1.
- An app on Rails 8.0 cannot resolve appkit; an app on Rails 8.1 can → A2 (scratch `bundle lock`, Rails 8.0 fails, Rails 8.1 succeeds).
- The engine test suite passes on Ruby 4.0.7 with no deprecation warnings → A3 (`test/**/*_test.rb` through `bundle exec rake test`).
- RuboCop, both Brakeman scans and bundler-audit pass, with no new disable comments or todo entries → A4.
- appkit's CI on the pull request is green on checkout `@v7` and cache `@v6` → A5.
- `rails-ci.yml` references checkout `@v7`, cache `@v6`, setup-node `@v7` and upload-artifact `@v7` → A6.
- `Gemfile.lock` reads `BUNDLED WITH 4.0.22`, and `.ruby-version` reads `ruby-4.0.7` → A7.
- A reader of CHANGELOG.md learns under Unreleased that appkit now requires Rails 8.1 → A8.

Per changed file, the unit tests expected:

- `appkit.gemspec`, `Gemfile.lock`, `.ruby-version`, `CHANGELOG.md`, both workflow files: none; configuration only, proven by A1–A8.
- Any `app/`, `lib/` or `test/` file changed for an offense or a deprecation: the existing tests that cover it stay green. A fix that changes behaviour gets a failing test first, in the existing test file for that class.

Test setup: none new. The existing dummy app and fixtures run A3. A2 uses two throwaway Gemfiles in the scratchpad; nothing is committed.

---
Domain skills applied: dependencies, rails-testing.
