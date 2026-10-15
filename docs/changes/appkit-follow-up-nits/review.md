# Review: appkit-follow-up-nits

## Round 1 — 2026-10-15T12:33:13Z — 9ba05c5

- [ ] Important: Upgrading step 4 tells existing apps to run `bin/rails generate appkit:install --skip`. In an app that first got `create_sessions`, the `sessions` table now exists, so the generator also writes a new `align_sessions_for_appkit` migration (`install_generator.rb:28-29`; `--skip` only skips existing files). The step does not mention it, although `AGENTS.md` "Upgrade instructions" names this exact side effect and its unsafe `down`. An app whose engine pages already load has the include already, so for most upgrading apps that migration is the only effect. Say what the generator also creates and what to do with it, or tell apps to add the include by hand — `CHANGELOG.md:26` →
- [ ] Nit: The tests interpolate `Appkit::Engine.root` unquoted into a backtick shell string, so a checkout path with a space or shell metacharacter breaks them. Pass an argument array instead (for example `IO.popen(["git", "-C", root.to_s, ...])`) — `test/appkit_test.rb:5`, `test/lockfile_test.rb:5`, `test/lockfile_test.rb:9` →

Checks run on `9ba05c5`: `bin/rails test` (137 runs, green), `bin/rails test test/controllers` (31), `bin/rails test test/appkit_test.rb` (2), `bundle exec rubocop` (no offenses), `bundle exec erb_lint --lint-all` (no errors, 12 files), both Brakeman scans (no warnings), `bin/bundler-audit check --update` (no vulnerabilities). `git status --porcelain` stayed empty after the runs.

Compliance (intent acceptance criteria → proof):

- Generator adds the include, sign-in page loads → `install_generator_test.rb` "adds include Appkit::Authentication to an ApplicationController that lacks it"; `sessions_controller_test.rb` "login layout actually loads JavaScript".
- Two runs leave one include → "running the generator twice leaves one include Appkit::Authentication".
- README snippet shows the include → `README.md` `## Installation` (read in the diff).
- `erb_lint --lint-all` exits 0; a staged offense fails pre-commit → ran `--lint-all`; hook wiring read in `lefthook-local.yml` (the offense check itself was not re-run in this review).
- `bin/rails test` variants and `rake test` pass → ran the three `bin/rails test` forms; `rake test` not re-run separately.
- pre-push runs the PWA controller test → `minitest` skip removed; shared hook runs `bin/rails test "$test_file"`.
- Prose on one line → read both files; no wrapped prose found outside fences and tables.
- `git status` clean after install and tests → `LockfileTest` both tests; clean status observed.
- Version names the commit → `AppkitTest` "version names the checked-out commit".
- `Gemfile.lock` untracked and ignored → `LockfileTest` "Gemfile.lock is not tracked by git", "git ignores Gemfile.lock".
- CI green on a push → missing until the pull request exists (`ci.yml` runs on `pull_request` and pushes to `main` only).
- Fresh clone: hook bundle step and `bin/bundler-audit` run → manual check per plan step 10; not re-run here.
- README explains the missing lockfile → `README.md` `## Development`.
- Different SHAs give different cache names → `Appkit::RevisionTest` (four tests), `PwaControllerTest` "service worker cache name includes the appkit revision".
- `AGENTS.md` updated → read in the diff; commands named there were run above.
- One `### Upgrading` after `### Fixed`; `### Fixed` holds no step → read `CHANGELOG.md`.

Every test named in `plan.md` `## Proof` exists. No existing test was weakened, skipped or deleted: "version is present" became a stricter assertion, and the PWA cache test now asserts the full `CACHE_NAME` line.

## Round 2 — 2026-10-15T12:31:22Z — 9ba05c5 (codex)

No findings. `codex review --base origin/main`: "I found no actionable regressions in the changes relative to the specified merge base."
