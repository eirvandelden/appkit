# Review — rails-8-1-4

## Round 1 — 2026-09-29T09:40Z — ec6e798

Test suite: `bundle exec rake test` 103 runs, 286 assertions, 0 failures. `bundle exec rubocop` 82 files, no offenses. CI (scan_ruby, lint, test) green. Gemspec (`railties >= 8.0`) needs no change.

Compliance (spec.md acceptance):
- Gemfile.lock resolves rails 8.1.4 — `Gemfile.lock` (rails/railties/activesupport 8.1.4); dependency bump, no test required.
- Test suite green — existing suite, 103 runs, 0 failures.
- Linters green — rubocop clean locally and in CI.
- plan.md names no new tests; no existing test weakened, skipped, or deleted.

- [ ] Important: The goal in intent.md (readiness for json 3.x) is not shown. The lock stays on `json (2.21.2)` while json 3.0.2 is released. `activesupport 8.1.3.1` on main already depended on `json` without a version limit, so the Rails version never blocked json 3. The limit in this lock is `rubocop 1.89.0` requiring `json (~> 2.3)` (dev only). In a scratch copy, `bundle update json --conservative` resolves json 3.0.2 and moves rubocop to 1.91.0. Say in the PR body that json 3 is a separate step, or bump json (and rubocop) in a follow-up PR. — `Gemfile.lock:149` →
- [ ] Important: The `appkit (0.1.0.pre.git.<sha>)` entry is out of date as soon as it is committed. It names 2bf0bf8, the parent of the lockfile commit, and every bundle run rewrites it. The worktree already has an uncommitted `Gemfile.lock` change to `ec6e798`. Cause: `lib/appkit/version.rb` builds VERSION from `git rev-parse --short HEAD`. This already happened on main before this branch (main's lock names ed6f302), so it belongs in a separate PR. Ranked Low by the prior review. — `Gemfile.lock:26` →
- [ ] Nit: The PR test plan does not list rubocop, but spec.md requires linters green. Rubocop is clean locally and in CI; only the PR body needs it added. — `docs/changes/rails-8-1-4/spec.md:1` →
