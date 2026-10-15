# Review: appkit-follow-up-nits

## Round 1 — 2026-10-15T12:33:13Z — 9ba05c5

- [ ] Important: Upgrading step 4 tells existing apps to run `bin/rails generate appkit:install --skip`. In an app that first got `create_sessions`, the `sessions` table now exists, so the generator also writes a new `align_sessions_for_appkit` migration (`install_generator.rb:28-29`; `--skip` only skips existing files). The step does not mention it, although `AGENTS.md` "Upgrade instructions" names this exact side effect and its unsafe `down`. An app whose engine pages already load has the include already, so for most upgrading apps that migration is the only effect. Say what the generator also creates and what to do with it, or tell apps to add the include by hand — `CHANGELOG.md:26` → fixed (docs: tell upgrading apps to add the Authentication include by hand)
- [ ] Nit: The tests interpolate `Appkit::Engine.root` unquoted into a backtick shell string, so a checkout path with a space or shell metacharacter breaks them. Pass an argument array instead (for example `IO.popen(["git", "-C", root.to_s, ...])`) — `test/appkit_test.rb:5`, `test/lockfile_test.rb:5`, `test/lockfile_test.rb:9` → fixed (test: pass the engine root to git as an argument, not through a shell)

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

## Round 3 — 2026-10-15T12:39:04Z — 195f935

No findings.

Re-review of the round 1 fixes:

- `CHANGELOG.md:26` Upgrading step 4 now tells apps to add the include by hand and names the `align_sessions_for_appkit` side effect. This matches `install_generator.rb:28-29`: `create_sessions_migration` picks `align_sessions.rb.tt` whenever a `sessions` table exists, and that is a new file name, so `--skip` does not stop it. `plan.md` (Nit 6) still names the `--skip` form of this step; the intent only asks for the generator step to be recorded, so the change still meets it.
- `test/appkit_test.rb:5` and `test/lockfile_test.rb:14` now call git with an argument array through `IO.popen`. No shell is involved.

Bugs: `Appkit::Revision` reads `source.revision` only when the source responds to it. Checked in this bundle: `Bundler::Source::Git` has `revision`; `Path`, `Gemspec` and `Rubygems` do not, so path, gemspec and released-gem installs fall back to `Appkit::VERSION`. The CI cache hash drops only the `appkit (` lines under `PATH` and `CHECKSUMS`. The generator guard uses `destination_root`, and `inject_into_class` resolves the same relative path. Nothing found.

Security: no new input reaches a shell or a query. `bin/bundler-audit` and the `ci.yml` steps add no secret and no untrusted interpolation. Both Brakeman scans report no warnings.

Checks run on `195f935`: `bin/rails test` (137 runs, 403 assertions, green), `bundle exec rubocop` (88 files, no offenses), `bundle exec erb_lint --lint-all` (12 files, no errors), both Brakeman scans (0 warnings), `bin/bundler-audit check --update` (no vulnerabilities). `git status --porcelain` stayed empty after the runs.

Compliance: unchanged from round 1. Every acceptance criterion has its test or check, and every test named in `plan.md` `## Proof` exists. CI green on a push stays missing until the pull request exists, because `ci.yml` runs on `pull_request` and on pushes to `main` only. No existing test was weakened, skipped or deleted.
