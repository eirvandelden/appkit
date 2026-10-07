# Plan: Stop tracking appkit's own Gemfile.lock

From `intent.md` (2026-10-07). Status: accepted.

## Context

`lib/appkit/version.rb` builds the appkit version from the checked-out commit (`0.1.0.pre.git.<short sha>`). The committed `Gemfile.lock` records that version, so it always names the commit before the one it is in, and every `bundle` run changes it. A file cannot name its own commit. The intent chose: the version keeps naming the commit, and appkit stops committing its lockfile. Host apps read only `appkit.gemspec`, so they see no change. Local runs and CI resolve the newest gems that `appkit.gemspec` and `Gemfile` allow.

## Design decisions

- Untrack, do not delete: `git rm --cached Gemfile.lock` and add `/Gemfile.lock` to `.gitignore`. A local lockfile stays on disk, untracked and ignored.
- CI resolves, then installs with rv, with a gem cache. setup-rv's `install-gems: true` runs `rv ci`, and `rv ci` needs a `Gemfile.lock`. So each job in `ci.yml` runs: setup-rv with `ruby-version` only (step `id: ruby`); `bundle lock` (step `id: gems`) to write a fresh lockfile; `actions/cache@v5` on `vendor/bundle`; `BUNDLE_PATH=vendor/bundle rv ci`, then `echo "BUNDLE_PATH=vendor/bundle" >> "$GITHUB_ENV"`. This mirrors setup-rv's own `action.sh`. Etienne chose this over a plain `bundle install` (2026-10-07).
- The gem cache key leaves out the appkit lines. The generated lockfile names the commit (`appkit (0.1.0.pre.git.<sha>)`, under PATH and CHECKSUMS), so a plain `hashFiles('Gemfile.lock')` key would miss on every commit and save a new cache entry every run. The `gems` step writes `hash=$(grep -v '^ *appkit (' Gemfile.lock | sha256sum | cut -d' ' -f1)` to `$GITHUB_OUTPUT`. Key: `gems-${{ runner.os }}-${{ runner.arch }}-ruby-${{ steps.ruby.outputs.ruby-version }}-${{ steps.gems.outputs.hash }}`; restore-key: the same without the hash. The key then changes only when a gem version changes.
- The RuboCop cache key in the `lint` job uses the same hash: `DEPENDENCIES_HASH: ${{ hashFiles('**/.rubocop.yml') }}-${{ steps.gems.outputs.hash }}`. This keeps today's meaning (config plus gem versions) without the per-commit appkit line.
- `bin/bundler-audit` is added (Etienne's choice, 2026-10-07). It follows the Rails 8.1 template (`railties-8.1.4/lib/rails/generators/rails/app/templates/bin/bundler-audit.tt`), but requires `../test/dummy/config/boot` as `bin/rails` does, because the engine root has no `config/boot.rb`. File mode 755. `config/bundler-audit.yml` is added with the Rails template comment and `ignore: []`.
- CI's `scan_ruby` runs `bin/bundler-audit check --update` instead of `bundle exec bundler-audit check --update`, so CI and the hook read the same `config/bundler-audit.yml`.
- The pre-push `bundle-audit` hook is un-skipped in `lefthook-local.yml`. Its glob becomes `Gemfile` and `appkit.gemspec`, because most of appkit's dependencies live in the gemspec. The existing comment there is narrowed to brakeman only.
- The lefthook `migrations` → `bundle` step is overridden in `lefthook-local.yml` to always run `bundle install`, with glob `Gemfile` and `appkit.gemspec`. The shared command runs `rv ci` whenever a `Gemfile.lock` exists, and here that file is untracked and can be stale: `rv ci` would install the stale set and miss what `Gemfile` or the gemspec now need. `bundle install` keeps the local versions and adds what is missing. Before this change, gemspec changes also changed `Gemfile.lock`, which matched `Gemfile*`. Now they change no `Gemfile*` file, so the gemspec must be in the glob.
- An existing checkout keeps its untracked lockfile and its gem versions until someone runs `bundle update`. Fresh clones and CI get the newest gems. Etienne accepted this (2026-10-07). The README says so.
- `rails-ci.yml` does not change. It runs inside host apps, which commit their own `Gemfile.lock`; it never reads appkit's. Etienne confirmed (2026-10-07).

Conflicts flagged against the intent:

- The intent lists `rails-ci.yml` in scope. It needs no change, for the reason above.
- The intent assumes `bin/bundler-audit` exists. It does not; this plan adds it.
- The intent's outcome says local runs install the newest gems. That holds for a fresh clone only. Playbook rule 11 also forbids agents to run a bare `bundle update` without instruction.
- `lefthook-local.yml` skipped bundle-audit because "CI already runs it". Re-enabling it reverses that earlier choice, on Etienne's instruction.

## Integration points

- GitHub Actions: `spinel-coop/setup-rv@main` (outputs `ruby-version`), `actions/cache@v5`, `rv ci`, Bundler 4 `bundle lock`.
- Lefthook 2.1.11, through the global `core.hooksPath` (`~/.config/git/hooks`), which runs the repo's own `lefthook.yml` merged with `lefthook-local.yml`.
- bundler-audit 0.9.3 and the ruby-advisory-db.
- `lib/appkit/version.rb` (read only; no change).

## Files that change

- `.gitignore` — add `/Gemfile.lock`.
- `Gemfile.lock` — removed from the index (`git rm --cached`); stays on disk.
- `test/lockfile_test.rb` — new; proves the lockfile is untracked and ignored.
- `test/appkit_test.rb` — "version is present" becomes "version names the checked-out commit".
- `bin/bundler-audit` — new binstub, mode 755.
- `config/bundler-audit.yml` — new; Rails template comment, `ignore: []`.
- `lefthook-local.yml` — override `migrations.commands.bundle` (`run: bundle install`, gemspec in glob); un-skip `pre-push.commands.bundle-audit` with the wider glob; narrow the comment to brakeman.
- `.github/workflows/ci.yml` — per job: Ruby-only setup-rv, `bundle lock` with the hash output, gem cache, `rv ci`; RuboCop cache key; `bin/bundler-audit`. One short comment above `jobs:` says why.
- `README.md` — new `## Development` section, before `## Continuous Integration`.

## Order of work

Each step is one commit. Run `bin/rails test <file>` for the narrowest check first.

1. Write `test/lockfile_test.rb` with "Gemfile.lock is not tracked by git" (`git -C <engine root> ls-files Gemfile.lock` prints nothing) and "git ignores Gemfile.lock" (`git -C <engine root> check-ignore Gemfile.lock` prints the path). Run it. Watch both fail: the file is tracked, and `check-ignore` never reports a tracked file.
2. Add `/Gemfile.lock` to `.gitignore`. Run `git rm --cached Gemfile.lock`. Run the test: green. Commit with the test. Then check by hand: `bundle install && git status --porcelain` prints nothing.
3. Replace "version is present" in `test/appkit_test.rb` with "version names the checked-out commit": `assert_equal "#{Appkit::BASE_VERSION}.pre.git.#{short sha}", Appkit::VERSION`, the sha from `git -C <engine root> rev-parse --short HEAD`. It passes at once: it pins existing behaviour. Commit.
4. Add `bin/bundler-audit` and `config/bundler-audit.yml`. Run `bin/bundler-audit check --update` and `bin/bundler-audit --config config/bundler-audit.yml` (the hook's form): both exit 0. Run RuboCop on `bin/bundler-audit`. Commit.
5. Edit `lefthook-local.yml`. Run `lefthook dump` and check the merged `migrations.bundle` and `pre-push.bundle-audit` entries (run, glob, no skip). Run `yamllint`. Commit.
6. Edit `.github/workflows/ci.yml`. Run `yamllint` (warnings only, as today). Commit.
7. Add the README `## Development` section. One line per paragraph. Content: appkit does not commit `Gemfile.lock`; why (the version names the commit, so a committed lockfile can never match its own commit; host apps read only `appkit.gemspec`); `bundle install` and CI resolve the newest gems that `appkit.gemspec` and `Gemfile` allow, so two runs on one commit can use different versions; a local lockfile stays untracked, and `bundle update` moves it to newer gems. Commit.
8. Fresh-clone check (Verification below).
9. Full checks in the worktree: `bundle exec rake test`, `bundle exec rubocop`, both Brakeman scans from `ci.yml`, `bin/bundler-audit check --update`.
10. Push, open the PR from the repo template if one exists, and watch CI: `gh pr checks --watch`.

## Verification

Fresh-clone check, in a throwaway clone under the session scratchpad:

```sh
git clone --branch stable-gem-version <worktree path> <scratch>/appkit-clone
cd <scratch>/appkit-clone
test ! -e Gemfile.lock
lefthook run migrations --command bundle --force
git status --porcelain            # prints nothing; Gemfile.lock now exists, ignored
lefthook run pre-push --command bundle-audit --force
bin/bundler-audit check --update
```

If lefthook stops because the clone has no `ORIG_HEAD`, run `git update-ref ORIG_HEAD HEAD~1` in that clone only, then retry.

## Risks

- A new gem release can turn CI red on an unchanged commit. The intent accepts this.
- `actions/cache` jobs share one key; the second and third job to finish log "cache already exists". This is harmless; setup-rv behaves the same.
- Pulling this change into an existing checkout deletes its local `Gemfile.lock`, because git removes a file that stops being tracked. The next `bundle install` (or the post-merge bundle step) writes it again.
- Open branches that still change `Gemfile.lock` get a modify/delete conflict when they rebase onto main. Resolve it with `git rm --cached Gemfile.lock`.
- `config/bundler-audit.yml` ships in the gem, because `spec.files` takes all of `config/**`. It is inert there, as `config/brakeman.ignore` already is.
- The pre-push hook runs `bin/bundler-audit` without `--update`. On a machine without the advisory database, bundler-audit downloads it with git inside the hook, where git exports `GIT_DIR`; that download can fail. Run `bin/bundler-audit update` once by hand. This machine has the database.
- Rejected: a plain `bundle install` in CI (Etienne preferred the cached rv path); hashing the whole generated lockfile for the cache key (misses on every commit); calling setup-rv twice to reuse its cache logic (installs rv twice, depends on its internals); changing `rails-ci.yml` (host apps must stay locked).

## Out of scope

- `rails-ci.yml` and the install generator's CI template.
- Syncing appkit's older `lefthook.yml` copy with the dotfiles one (binstub-free bundle-audit, brakeman guard, `post-rewrite`, migration globs). Propose as a separate branch.
- A CHANGELOG entry, an `AGENTS.md` for appkit, publishing to RubyGems, the dotfiles worktree sweep bug.

## Proof

- After a commit, `bundle install` leaves `git status` clean → `test/lockfile_test.rb` "Gemfile.lock is not tracked by git" and "git ignores Gemfile.lock"; by hand, `bundle install && git status --porcelain` prints nothing (step 2 and the fresh-clone check).
- In a checkout of commit `abc1234`, the version is `0.1.0.pre.git.abc1234` → `test/appkit_test.rb` "version names the checked-out commit".
- On a push, CI installs gems and runs tests, RuboCop, Brakeman and bundler-audit → the `CI` workflow run on the PR: `scan_ruby`, `lint` and `test` green (`gh pr checks --watch`).
- After a fresh clone, the lefthook bundle step installs gems and `bin/bundler-audit` runs → the fresh-clone check under Verification exits 0 at every line.
- The README says appkit does not commit its `Gemfile.lock`, and why → `README.md` `## Development`; checked by reading the diff.

Per changed file, the unit tests expected:

- `.gitignore`, `Gemfile.lock`: `LockfileTest` "Gemfile.lock is not tracked by git", "git ignores Gemfile.lock".
- `test/appkit_test.rb`: `AppkitTest` "version names the checked-out commit".
- `bin/bundler-audit`, `config/bundler-audit.yml`: no unit test; a test would hit the network and fail on any new advisory. Proven by CI's `scan_ruby` step and the fresh-clone check.
- `lefthook.yml`, `lefthook-local.yml`: no unit test; proven by `lefthook dump` and the fresh-clone check.
- `.github/workflows/ci.yml`: proven by the PR's CI run.
- `README.md`: none.

Test setup: none. Both tests shell out to `git -C Appkit::Engine.root`; CI's `actions/checkout` gives a git checkout.

---
Domain skills applied: dependencies (no bare `bundle update`, gem.coop source), new-repo-setup (lefthook rules: never `lefthook install`, never disable hooks).
