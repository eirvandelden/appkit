# Plan: appkit gets an AGENTS.md with upgrade instructions

From `intent.md` (2026-10-12). Status: accepted.

## Context

appkit is a non-isolated Rails engine (auth, PWA/push, theme/preferences, health checks) used by several personal apps. It has no `AGENTS.md` and no `CLAUDE.md`. `~/Developer/mvpa.css/AGENTS.md` is the model: four sections (What this is, Domain, Commands, Gotchas), and `CLAUDE.md` there is a symlink to `AGENTS.md`. This change adds both files to appkit, plus a rule for `### Upgrading` subsections in `CHANGELOG.md`. Documentation only: no Ruby, JavaScript, CSS, YAML or test file changes.

## Design decisions

- `CLAUDE.md` is a relative symlink to `AGENTS.md` (`ln -s AGENTS.md CLAUDE.md`), exactly as in mvpa.css. Claude Code reads the same bytes; there is no second copy to drift.
- `AGENTS.md` has five `##` sections: What this is, Domain, Commands, Gotchas, Upgrade instructions. The first four match mvpa.css by name and order. The fifth holds the new rule and its example.
- Where the `### Upgrading` subsection goes. `intent.md` says "its dated CHANGELOG.md entry", but appkit's `CHANGELOG.md` has no dated entries today: it has one `## Unreleased` heading with `### Added` under it. The intent also says "the changelog keeps its current format". So the rule says: put `### Upgrading` inside the same `##` entry that records the change, after that entry's `### Added`/`### Changed`/`### Fixed` subsections. Today that entry is `## Unreleased`; once dated `## YYYY-MM-DD` headings exist, it is the dated one. The rule does not introduce dated headings itself. This reconciles the intent's two constraints; it is decided here, not left open.
- What "requires apps to act" means, listed in the rule so an agent can decide without guessing. Each item is grounded in the code or README:
  - a new migration template in `lib/generators/appkit/install/templates/`. A schema change that apps must apply always ships as a new, uniquely named template; never change a template that apps already copied, because `--skip` leaves the app's old copy in place;
  - a new, renamed or removed `Appkit.config` option that an app must set (`lib/appkit/configuration.rb`);
  - a new Stimulus controller pin in `config/importmap.rb` that apps must register in their own `controllers/index.js` (README "JavaScript controllers");
  - a renamed or removed public class, concern, helper, partial, route or job that apps reference by name (for example `Appkit::SessionExpiryJob` in an app's `config/recurring.yml`);
  - new credentials (for example `web_push`), a new co-gem line in the app's `Gemfile` (as with `mvpa-css`), or a new layout requirement (as with `javascript_importmap_tags` in the `login` layout);
  - a new required input on `.github/workflows/rails-ci.yml`.
- What does not require apps to act: internal method changes, test-only changes, engine CI changes, lint fixes. Those add no `### Upgrading` subsection.
- The example in `AGENTS.md` uses a real past case, not an invented one: the `create_appkit_push_subscriptions` migration that the install generator copies. It shows the commands an app runs: `bin/rails generate appkit:install --skip`, then `bin/rails db:migrate`.
- Why `--skip` in the example. Verified in `railties-8.1.4/lib/rails/generators/actions/create_migration.rb`: a re-run of `migration_template` with an existing migration of the same name but different content raises "Another migration is already named …" unless `--force` or `--skip` is given; identical content is reported as `identical` and left alone; with `--skip` a changed template is skipped, so the app keeps its old copy. That is why the rule forbids changing a copied template. `--skip` also stops Thor from prompting on the error pages and CI workflow the app already has. Every step in an Upgrading subsection must be a command the agent ran or read in the code, not a guess.
- No automated test. The intent scopes the change to two documentation files and puts code changes out of scope. A test that parses `AGENTS.md` would be a third file and new code. Proof is by checks: run every documented command, inspect the symlink, and read the rule against each acceptance criterion.

## Integration points

- `CHANGELOG.md` — read by the rule; not edited by this change.
- `lib/generators/appkit/install/install_generator.rb` — the only way migrations, error pages and the CI caller reach apps; the rule and example refer to it.
- `.github/workflows/rails-ci.yml` — apps call it at `@main`, not at their pinned SHA; documented as a gotcha.
- `~/Developer/mvpa.css/AGENTS.md` — section model only; not edited (out of scope per intent).

## Files that change

- `AGENTS.md` — new. Contents, all taken from the code, README and changelog:
  - **What this is**: non-isolated Rails engine (`Appkit::Engine`, no `isolate_namespace`) providing session-based auth (login, FirstRun bootstrap, session transfer/QR magic link), PWA manifest/service worker with web push, theme/preferences, `VersionHeaders`, `Authorization`, okcomputer health checks, static error pages and a reusable CI workflow. Apps install it with `gem "appkit", github: "eirvandelden/appkit"` and pin a SHA (`CHANGELOG.md` note). Requires Rails >= 8.0 (`appkit.gemspec`).
  - **Domain**: host apps own `User` and `Session`; appkit reaches them through `Appkit.config.user_class`/`session_class`/`user_scope` and the concerns `Appkit::Authenticatable`, `Appkit::SessionBehavior`, `Appkit::Transferable`, `Appkit::UserTheming`, `Appkit::Authorization`, and the controller concerns `Appkit::Authentication` and `Appkit::VersionHeaders`. Engine-owned model: `Appkit::PushSubscription` (`appkit_push_subscriptions` table). `config/routes.rb` draws straight into `Rails.application.routes` (`/session`, `/first_run`, `/preferences`, `/qr_code/:id`, `/manifest`, `/service-worker`, `/push_subscription`). Jobs: `Appkit::PushNotificationJob`, `Appkit::SessionExpiryJob`. Locales `en`, `nl`, `it` in `config/locales/`. `test/dummy` is the host app used by the tests. Configuration source of truth: `lib/appkit/configuration.rb`.
  - **Commands**: `bundle install` (Ruby from `.ruby-version` via `rv`); `bundle exec rake test` (Minitest, `test/**/*_test.rb`, against `test/dummy`); one file: `bin/rails test test/models/appkit/push_subscription_test.rb`; `bundle exec rubocop`; `bundle exec brakeman -p test/dummy --no-pager --ignore-config config/brakeman.ignore` and `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`; `bundle exec bundler-audit check --update`; `bin/rails appkit:vapid_keys` (generates a VAPID key pair and prints both keys plus a `credentials.yml.enc` snippet that holds the private key; documented from `lib/tasks/appkit.rake`, never run while writing this file). CI is `.github/workflows/ci.yml` and runs the same scans, RuboCop and tests.
  - **Gotchas** (each verified in the files named):
    - No `isolate_namespace`: engine routes and helpers live in the host's namespace, so an app route with the same path collides (`lib/appkit/engine.rb`, `config/routes.rb`).
    - `mvpa-css` is a git co-gem declared in `Gemfile`, not `appkit.gemspec`; apps add it themselves (`Gemfile`, README).
    - Apps register appkit's Stimulus controllers by hand; a missing `auto-submit` registration or a missing `javascript_importmap_tags` in the `login` layout breaks the magic-link flow silently (README).
    - `lib/appkit/version.rb` appends the short git SHA to the version, so `Gemfile.lock`'s self-reference `appkit (0.1.0.pre.git.<sha>)` changes after commits. Any `bundle exec` or `bin/rails` command rewrites it to the current SHA (seen while writing this plan). Do not commit that rewrite with an unrelated change; past history has separate "refresh lockfile self-reference" commits.
    - `test/dummy/db/schema.rb` is hand-written (no `db/migrate` in the dummy) and loaded by `test/test_helper.rb` on every run; a new migration template needs the matching schema edit there too.
    - `test/test_helper.rb` clears `Rails.cache` before each test because the `sessions#create` rate limiter counts attempts in the cache.
    - `Appkit::SessionExpiryJob` keeps its name although it breaks `Obsession/Rails/ServiceName`: apps schedule it by name (`.rubocop_todo.yml`).
    - Apps call `.github/workflows/rails-ci.yml` at `@main`, not at their pinned SHA, so a change there reaches every app's CI at merge; the repo must stay public (README).
    - Brakeman runs twice with two ignore files: `config/brakeman.ignore` for the dummy app, `config/brakeman.gem.ignore` for the gem root (`ci.yml`).
    - `lefthook-local.yml` skips the CSS/JS/ERB hooks, the per-file Minitest/RSpec hooks and the Brakeman/bundler-audit pre-push hooks; CI is the gate for those.
    - Re-running `bin/rails generate appkit:install` in an app that already ran it: use `--skip`, or an existing migration with changed content raises a conflict (railties `create_migration.rb`). The generator also picks `align_sessions_for_appkit` over `create_sessions` whenever a `sessions` table exists.
    - Ruby version comes from `.ruby-version` via `rv`; do not use mise/asdf/rbenv/rvm.
  - **Upgrade instructions**: the rule, the "requires apps to act" list and its negative list from Design decisions, and this example of an entry (Markdown fenced block):

    ```markdown
    ## Unreleased

    ### Added
    - Web push subscriptions, stored in `appkit_push_subscriptions`.

    ### Upgrading
    1. Run `bin/rails generate appkit:install --skip` to copy the `create_appkit_push_subscriptions` migration.
    2. Run `bin/rails db:migrate`.
    ```

    One instruction per step, an exact command where one exists, steps in the order an app runs them.
- `CLAUDE.md` — new symlink to `AGENTS.md`.

Prose follows playbook rule 26: one line per paragraph and per list item.

## Order of work

1. Run the first check and watch it fail: `test -L CLAUDE.md && test "$(readlink CLAUDE.md)" = AGENTS.md && test -f AGENTS.md` exits non-zero.
2. Write `AGENTS.md` sections What this is, Domain, Commands from the list above. Before writing each command, run it from the worktree root and confirm it works (`bundle exec rake test`, `bin/rails test test/models/appkit/push_subscription_test.rb`, `bundle exec rubocop`, both Brakeman scans, `bundle exec bundler-audit check --update`). A command that fails is reported, not documented as working. `bundle install` is run only if the bundle is incomplete (`bundle check` fails). `bin/rails appkit:vapid_keys` is never run: it prints a private key; describe it from `lib/tasks/appkit.rake`.
3. Write the Gotchas section. Re-open each file named in a gotcha and confirm the claim before writing it.
4. Write the Upgrade instructions section with the rule, both lists and the example.
5. `ln -s AGENTS.md CLAUDE.md`. Re-run the step 1 check; it passes.
6. Walk each acceptance criterion against the file (Proof below). Check every line against rule 26 and the STE rules (sentences of at most 20 words, active voice).
7. Check `git diff Gemfile.lock`. If the only change is the `appkit (0.1.0.pre.git.<sha>)` self-reference that step 2's commands wrote, restore it with `git checkout -- Gemfile.lock`; it is not part of this change. Any other lockfile change: stop and report it, do not restore it.
8. Re-read the full diff: only `AGENTS.md` and `CLAUDE.md` are added. Commit in one commit.

## Risks

- A documented command or gotcha that is wrong misleads every later agent. Mitigation: steps 2 and 3 run or re-read each one.
- The Upgrading placement under `## Unreleased` may not be what Etienne meant by "dated". Mitigation: the rule names both cases, so it stays right once dated headings arrive; the plan report flags the reading for Etienne to see.
- Symlink on a checkout that does not support symlinks (Windows without the setting). Accepted: mvpa.css already does this, and all users are on macOS/Linux.
- Rejected: a Minitest test asserting the `AGENTS.md` headings and the symlink (out of scope: code change, third file). Rejected: `CLAUDE.md` as a file containing `@AGENTS.md` (differs from mvpa.css, which the intent names as the model). Rejected: adding dated headings to `CHANGELOG.md` (intent keeps the format).

## Out of scope

- Any change to `CHANGELOG.md`, `README.md`, code, tests, configuration or CI.
- mvpa.css and journal_administration.
- Rewriting older changelog entries.

## Proof

- An agent new to appkit finds in `AGENTS.md` what the engine provides, how to run its tests and linters, and its known gotchas → check: `grep -c '^## \(What this is\|Domain\|Commands\|Gotchas\)$' AGENTS.md` prints `4`, and each test, lint and scan command listed under Commands was run in step 2 and passed (`bundle install` and `appkit:vapid_keys` are checked by reading, see step 2).
- An agent that adds a migration that apps must copy adds a `### Upgrading` subsection with the generator command to run → check: the Upgrade instructions section lists "a new migration template" as requiring action and forbids changing a copied template, and its example contains `bin/rails generate appkit:install --skip` under `### Upgrading`.
- An agent that changes an internal method with no effect on apps adds no `### Upgrading` subsection → check: the Upgrade instructions section names "internal method changes" in its list of changes that add no `### Upgrading` subsection.
- Claude Code reads the same content through `CLAUDE.md` → check: `test -L CLAUDE.md && test "$(readlink CLAUDE.md)" = AGENTS.md && cmp CLAUDE.md AGENTS.md`.

Per changed file, the unit tests expected:
- `AGENTS.md`: none (documentation; checks above).
- `CLAUDE.md`: none (symlink; check above).

Test setup: none. The existing suite runs once in step 2 to prove the documented test command works.

---
Domain skills applied: rails-architecture (engine structure read only), dependencies (co-gem and gemspec facts read only).

## Critique

### Round 1 (codex exec -p terra)

- Changed migration templates cannot be upgraded with `--skip`: Rails skips an existing changed migration, so the app keeps its old copy → fixed (the rule now requires a new, uniquely named template and forbids changing a copied one; the `--skip` design note and the Proof line say so)
- The QR-code route is `GET /qr_code/:id`, not `/qr_code` → fixed (Domain route list now says `/qr_code/:id`)
- `appkit:vapid_keys` does more than print keys and prints a private key, so it must not be run to validate it → fixed (Commands describes the credentials snippet; step 2 says never run it, document it from `lib/tasks/appkit.rake`)
- Proof claims every documented command ran, but `bundle install` and `appkit:vapid_keys` are not in step 2 → fixed (step 2 runs `bundle install` only when `bundle check` fails and never runs `vapid_keys`; the Proof line names which commands run and which are read)
- Step 7 blindly restores `Gemfile.lock`, which was already modified in the worktree → fixed (step 7 restores only a self-reference-only diff and stops otherwise)
  - The modification the critic saw was this plan session's own `bundle exec` rewriting the self-reference SHA; it was restored before commit. The gotcha now records that every `bundle exec` does this.
- The plan defers whether `## Unreleased` satisfies the intent's "dated entry" wording, so it cannot auto-accept → fixed (the decision is made in Design decisions: the `##` entry that records the change, today `## Unreleased`; no longer deferred)
