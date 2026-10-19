# Plan: Finish the untracked-lockfile follow-ups in CI and lefthook

From `intent.md` (2026-10-16). Status: accepted.

## Context

PR #18 (`d837929`) stopped tracking appkit's `Gemfile.lock`. This branch keeps four follow-ups that `main` lacks: a read-only CI token, short gem cache lines in `ci.yml`, `no_auto_install: true` in `lefthook-local.yml`, and a running pre-push `bundle-audit` hook. The branch is based on `origin/main` (`e47907f`). Its non-docs diff against `main` touches only `.github/workflows/ci.yml` and `lefthook-local.yml`, and those hunks already implement the first four in-scope items. The one item left is `AGENTS.md`, which still says the bundler-audit pre-push hook is skipped.

State checked on 2026-10-19 at `49db101`:

- `ci.yml` has `permissions: contents: read` and the `gems` step writes `hash`, `cache-prefix` and `cache-key`; the cache steps use the last two.
- `yamllint .github/workflows/ci.yml` reports only `1:1 document-start` and `107:121 line-length (163)`, the RuboCop cache key that the intent leaves out of scope. Both are on `main` too.
- `lefthook dump` shows top-level `no_auto_install: true`, and `pre-push.bundle-audit` with `glob: ['{Gemfile,appkit.gemspec}']`, no `skip`, `run: bin/bundler-audit --config config/bundler-audit.yml`.
- `bin/bundler-audit` and `config/bundler-audit.yml` are tracked on `main`.
- `~/.config/git/hooks/*` are all symlinks into `~/Developer/dotfiles/git/.config/git/hooks/`.
- `AGENTS.md:37` says "skips … the Brakeman and bundler-audit pre-push hooks".
- `ci.yml` runs on `pull_request` and on push to `main` only, so a branch push alone runs no CI. No pull request exists for `stable-gem-version`.

## Design decisions

- Keep the committed `ci.yml` and `lefthook-local.yml` hunks as they are. They match the intent; this plan only re-verifies them.
- `AGENTS.md:37` becomes: `lefthook-local.yml` skips the CSS and JS hooks and the Brakeman pre-push hook. The bundler-audit pre-push hook runs `bin/bundler-audit` when `Gemfile` or `appkit.gemspec` changes. On a machine without the advisory database, run `bin/bundler-audit update` once first, because the download can fail inside a git hook. The rest of the line (ERB lint, per-file test hook, CI scope, CSS/JS by hand) stays unchanged. The third sentence records the intent's flagged concern where a developer meets it.
- Edit `AGENTS.md` only. `CLAUDE.md` is a tracked symlink to it; `agents.md` is the same file on the case-insensitive file system.
- No `CHANGELOG.md` entry and no `### Upgrading`: `ci.yml` and `lefthook-local.yml` are appkit-only, and AGENTS.md lists "changes to the engine's own `.github/workflows/ci.yml`" as needing none.
- `docs/changes/stable-gem-version/review.md` holds rounds 1–3 against the pre-narrowing scope. Leave it; the next `review` run appends a new round.

## Integration points

- GitHub Actions token permissions, `actions/cache@v6`, `spinel-coop/setup-rv@main` (`ruby-version` output).
- Lefthook 2.2.2 through the global `core.hooksPath` (`~/.config/git/hooks`), merging `lefthook.yml` and `lefthook-local.yml`.
- bundler-audit through `bin/bundler-audit` and `config/bundler-audit.yml`.

## Files that change

- `AGENTS.md` — line 37, as in Design decisions.

Already changed on this branch, re-verified only: `.github/workflows/ci.yml`, `lefthook-local.yml`.

## Order of work

1. Run the AGENTS.md check from Proof. Watch it fail: `AGENTS.md:37` still names the bundler-audit hook as skipped.
2. Edit `AGENTS.md:37`. One line, as the file has it. Run the check: green. Commit (`Say that the bundler-audit pre-push hook runs`).
3. Run the yamllint check from Proof: no `line-length` warning on the gem cache lines (only line 107 remains).
4. Run the two `lefthook dump` checks from Proof.
5. Run the hook-symlink check from Proof: record `ls -l ~/.config/git/hooks`, run `lefthook run pre-commit -f` in the worktree with nothing staged, then confirm every entry is still a symlink into the dotfiles. Do not pass `--no-auto-install`: the point is that the config key alone prevents the sync. Run it against the real global hooks, not a scratch clone (Etienne's choice, 2026-10-19).
6. Run the full local checks: `bundle exec rake test`, `bundle exec rubocop`, `bundle exec erb_lint --lint-all`, both Brakeman scans from `ci.yml`, `bin/bundler-audit check --update`.
7. Push the branch (`git push origin HEAD`). The CI criterion is proven when `deliver` opens the draft pull request and `gh pr checks --watch` shows `scan_ruby`, `lint` and `test` green.

## Risks

- `lefthook run pre-commit -f` in step 5 with a missing or stale `no_auto_install` would rewrite the global hooks. The key is confirmed in `lefthook dump` in step 4 first. If the hooks still change, stop and report; restoring them is out of scope (rule 12).
- The pre-push hook downloads the advisory database where it is missing and can fail inside the hook (`GIT_DIR` is exported). Accepted in the intent; the AGENTS.md line says how to avoid it.
- `permissions: contents: read` could starve a step that needs more. Checked in review round 2: `actions/cache` uses the runtime token and `rubocop -f github` writes annotations to stdout. The PR's CI run confirms it.
- Rejected: shortening the RuboCop cache key line too (out of scope per the intent); a Minitest test that parses `AGENTS.md` or the YAML files (it would pin prose and config, not behaviour).

## Out of scope

- Everything PR #18 delivered.
- `rails-ci.yml` and the install generator's CI template.
- The RuboCop cache `key` line (`ci.yml:107`, 163 characters).
- Restoring global hooks that an earlier run replaced.
- Rewording the pre-narrowing commit messages.

## Proof

- `ci.yml` declares `permissions: contents: read`, and the PR's CI run passes → check: `grep -A1 '^permissions:' .github/workflows/ci.yml` prints `contents: read`; `gh pr checks --watch` on the draft PR shows `scan_ruby`, `lint`, `test` green.
- No `line-length` warning on the gem cache lines → check: `yamllint .github/workflows/ci.yml | grep line-length` prints only the line-107 warning.
- `no_auto_install: true`, and the global hooks stay symlinks after a run → check: `lefthook dump | grep '^no_auto_install: true'`; then step 5: `find ~/.config/git/hooks -mindepth 1 ! -type l` prints nothing before and after `lefthook run pre-commit -f`.
- `pre-push.bundle-audit` runs without `skip`, glob `{Gemfile,appkit.gemspec}` → check: `lefthook dump | sed -n '/^    bundle-audit:/,/^    [a-z_]*:$/p'` shows the glob and no `skip:` line.
- `AGENTS.md` no longer says the bundler-audit hook is skipped → check: `! grep -n 'Brakeman and bundler-audit pre-push hooks' AGENTS.md && grep -n 'bundler-audit pre-push hook runs' AGENTS.md`.

Per changed file, the unit tests expected:

- `AGENTS.md`: none; documentation, proven by the grep check.
- `.github/workflows/ci.yml`: none; proven by yamllint and the PR's CI run.
- `lefthook-local.yml`: none; proven by `lefthook dump` and the hook-symlink check.

Test setup: none. No Ruby code changes, so `bundle exec rake test` must stay at its current count with 0 failures.

---
Domain skills applied: dependencies (no gem changes), new-repo-setup (lefthook: never `lefthook install`, never disable hooks).
