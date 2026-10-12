# Review: agents-md-with-upgrade-instructions

## Round 1 — 2026-10-12T15:15:17Z — cc14877

Checks run at cc14877: `bundle exec rake test` (103 runs, 0 failures), `bundle exec ruby -Itest test/models/appkit/push_subscription_test.rb` (3 runs, 0 failures), `bundle exec rubocop` (no offenses), both Brakeman scans (no warnings), `bundle exec bundler-audit check --update` (no vulnerabilities). `bin/rails test <file>` fails with `cannot load such file -- test_helper`, as documented. `appkit:vapid_keys` was not run.

Compliance:

- An agent new to appkit finds what the engine provides, its test and lint commands and its gotchas → `AGENTS.md` sections What this is, Domain, Commands, Gotchas (`grep -c` prints `4`); commands run green above. Partly undermined by the false claims below.
- A migration that apps must copy gets a `### Upgrading` subsection with the generator command → `AGENTS.md:42` and the example at `AGENTS.md:59-61`.
- An internal method change adds no `### Upgrading` subsection → `AGENTS.md:49`.
- Claude Code reads the same content through `CLAUDE.md` → `test -L CLAUDE.md && readlink = AGENTS.md && cmp` passes.
- Plan `## Proof` names no tests, only checks; all four checks pass. No existing test is weakened, skipped or deleted (the diff adds only `AGENTS.md` and `CLAUDE.md`).

Findings:

- [x] Important: `bin/rails appkit:vapid_keys` is listed under appkit's own Commands, but it does not run in this repository. `bin/rails` in the repo root loads the gem `Rakefile`, which defines no Rails app tasks and does not load `lib/tasks`. `bin/rails -T` and `bundle exec rake -T` list no `appkit:*` task, so Rails raises an unrecognized-command error. The task only exists inside a host app. Say that it is a host-app command, or move it out of the appkit Commands list. — `AGENTS.md:18` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Important: The `lefthook-local.yml` gotcha says "CI is the gate for those", but `.github/workflows/ci.yml` runs no stylelint, browserslist, ERB lint or ESLint. CI gates only the tests, Brakeman and bundler-audit. The CSS, JS and ERB checks run nowhere. — `AGENTS.md:32` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Important: Domain says host models include `Appkit::Authorization`. It is a controller concern: it defines `ensure_can_administer`/`ensure_current_user` with `head :forbidden`, and the dummy app includes it in `AdminController` (`test/dummy/app/controllers/admin_controller.rb:2`). The file lives in `app/models/concerns/`, which is easy to misread. Move it to the controller list, and name the host's `User#can_administer?` it needs. — `AGENTS.md:9` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Important: The engine ships the `login` layout itself, and it already renders `javascript_importmap_tags` (`app/views/layouts/login.html.erb:12`, fixed in 29314b7). The gotcha implies apps must add the tag to their login layout, and the upgrade list cites it as an example of an app-side layout requirement. Neither holds: an app only needs it when it overrides that layout. The README wording is ambiguous; `AGENTS.md` repeats it as fact. — `AGENTS.md:25`, `AGENTS.md:46` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Important: The rule lists "a new required input on `rails-ci.yml`" as something an `### Upgrading` step handles. The gotcha two sections up says apps call that workflow at `@main`, so a new required input breaks every app's CI at merge, before any app upgrades. An upgrade step cannot fix that. The rule should say: add new inputs as optional with a default, or update the callers first. — `AGENTS.md:47` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Nit: The example's step 1 (`bin/rails generate appkit:install --skip`) also creates a new `align_sessions_for_appkit` migration in any app that first got `create_sessions`, because the sessions table now exists (`install_generator.rb:25-29`). The template is idempotent, so it is harmless, but an agent following the example gets an unexpected migration. Line 33 states the table check without that consequence. — `AGENTS.md:33`, `AGENTS.md:60` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Nit: The example is introduced as "from the push subscriptions migration", but `CHANGELOG.md` has no push subscriptions entry. The migration is real; the changelog text is constructed. Call it an illustration, to meet the intent's "nothing is invented" constraint. — `AGENTS.md:51` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Nit: All upgrade steps pile up under one `## Unreleased` entry, and apps pin SHAs. An app on SHA X cannot tell which steps are new to it. One sentence would close the gap: read `git diff <pinned-sha>..<new-sha> -- CHANGELOG.md` for the new steps. — `AGENTS.md:38` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Nit: The `Appkit.config` item reads "a new, renamed or removed option that an app must set". An app does not set a removed option; it must stop setting it, because `attr_accessor` is gone and the call raises `NoMethodError`. — `AGENTS.md:43` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Nit: Domain omits that host apps must define `Current` with `user` and `session` attributes. The engine references `Current` directly, not through `Appkit.config` (`authentication.rb`, `authorization.rb`, `theme_helper.rb`, two controllers). — `AGENTS.md:9` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Nit: Some sentences exceed the playbook's 20-word STE limit, which plan step 6 says was checked. Examples: the "It provides …" sentence (about 39 words), the credentials/co-gem/layout item (about 29 words) and the renamed-or-removed item (about 23 words). — `AGENTS.md:5`, `AGENTS.md:45`, `AGENTS.md:46` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)
- [x] Nit: "Any `bundle exec` or `bin/rails` command rewrites the self-reference" holds only when HEAD's short SHA differs from the locked one. That is true after every commit, so it is close enough, but "whenever HEAD moved since the last lock" is exact. — `AGENTS.md:26` → fixed (Close review round 1 findings for agents-md-with-upgrade-instructions)

## Round 2 — 2026-10-12T15:16:07Z — cc14877 (codex)

- [x] Important: The diff still holds `docs/changes/agents-md-with-upgrade-instructions/` (intent and plan), which the workflow removes before finishing — `docs/changes/agents-md-with-upgrade-instructions/plan.md:1` → dismissed: the finish step removes the change folder in its own commit before the PR opens; the folder must stay until then for review and closure

## Round 3 — 2026-10-12T15:21:10Z — 627b89f

Checks run at 627b89f: `bundle exec rake test` (103 runs, 286 assertions, 0 failures), `bundle exec ruby -Itest test/models/appkit/push_subscription_test.rb` (3 runs, 0 failures), `bundle exec rubocop` (82 files, no offenses), both Brakeman scans (0 warnings), `bundle exec bundler-audit check --update` (no vulnerabilities). `bin/rails test <file>` fails with `cannot load such file -- test_helper`, as documented. `bin/rails -T` lists no `appkit:*` task. `appkit:vapid_keys` was not run.

Round 1 fixes re-checked: all twelve hold, with three partial exceptions listed below (the `can_administer?` half of the Authorization finding, a new 23-word sentence at line 44, and the rollback side of the `align_sessions_for_appkit` note).

Compliance:

- An agent new to appkit finds what the engine provides, its test and lint commands and its gotchas → `AGENTS.md` What this is, Domain, Commands, Gotchas (`grep -c` prints `4`); every documented command ran as described. Undermined in part by the Domain claim below.
- A migration that apps must copy gets a `### Upgrading` subsection with the generator command → `AGENTS.md:43` and the example at `AGENTS.md:61-63`.
- An internal method change adds no `### Upgrading` subsection → `AGENTS.md:51`.
- Claude Code reads the same content through `CLAUDE.md` → `test -L CLAUDE.md && readlink = AGENTS.md && cmp` passes.
- Plan `## Proof` names checks, not tests; all four pass. No existing test is weakened, skipped or deleted.

Findings:

- [x] Important: Domain says "Appkit reaches them through `Appkit.config.user_class`, `session_class` and `user_scope`". That is false in part. `SessionLookup#find_session_by_cookie` calls `Session.find_by` by constant (`app/controllers/concerns/appkit/authentication/session_lookup.rb:6`). `Appkit::Authenticatable` declares `has_many :sessions` (`authenticatable.rb:6`), and `Appkit::PushSubscription` declares `belongs_to :user` (`push_subscription.rb:5`). An app that points `session_class` at another class still gets login lookups against `Session`. Say that the host classes must be named `User` and `Session`, or name these constant references as exceptions, as the `Current` sentence does. — `AGENTS.md:9` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: Round 1's Authorization fix is partial. That finding asked to name the host's `User#can_administer?`; `AGENTS.md` still does not. `ensure_current_user` also needs a `@user` that responds to `current?` (`app/models/concerns/appkit/authorization.rb:5`, `:9`). — `AGENTS.md:9` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: Domain omits other host requirements the engine relies on. Engine controllers inherit the host's `::ApplicationController` (there is no `Appkit::ApplicationController`; see `app/controllers/appkit/first_runs_controller.rb:2`), so that class must include `Appkit::Authentication`. The host must define a `root` route (`authentication.rb:46`, `sessions_controller.rb:24`). `Appkit::VersionHeaders` needs `config.app_version` and `config.git_revision` (README "Version headers"). — `AGENTS.md:9` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: "`bin/rails -T` here lists only the gem's build and release tasks" is not exact. It also lists `test`, `clean`, `clobber`, `install` and `install:local`. "lists only the tasks from the gem `Rakefile`" is exact. — `AGENTS.md:18` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: The `Appkit.config` item, rewritten in round 1, is one sentence of 23 words, above the 20-word STE limit. — `AGENTS.md:44` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: "That migration is safe to run" holds for `up` only. The `down` of `align_sessions.rb.tt` removes `last_active_at` (`lib/generators/appkit/install/templates/align_sessions.rb.tt:8-10`), a column that `create_sessions` created and `SessionBehavior` validates. A `db:rollback` past it breaks login in that app. Say that it is safe to run but not safe to roll back. — `AGENTS.md:66` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: The list of changes that need no app action names "engine CI changes". `rails-ci.yml` also lives in this repo's `.github/workflows/`, so the phrase can be read to cover it. That workflow also needs app-side binstubs beyond its inputs: `bin/brakeman`, `bin/bundler-audit`, `bin/importmap`, `bin/rubocop` (`.github/workflows/rails-ci.yml:26`, `:29`, `:45`, `:72`). The gotcha covers only new inputs. Name `.github/workflows/ci.yml` in the negative list, and extend the gotcha to any new binstub, secret or file the workflow needs from apps. — `AGENTS.md:51`, `AGENTS.md:31` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: The rule says a change "adds a `### Upgrading` subsection" to its entry. All changes share one `## Unreleased` entry today, so a second change would add a second `### Upgrading` heading. Say: add the steps to the existing `### Upgrading` subsection when the entry already has one. — `AGENTS.md:39` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)
- [x] Nit: "The engine owns one model, `Appkit::PushSubscription` …, plus `Appkit::FirstRun`, `Appkit::ManifestIcon` and `Appkit::QrCodeLink`" reads as four models after "one". Say "one Active Record model … plus three plain Ruby classes". — `AGENTS.md:9` → fixed (Close review round 3 findings for agents-md-with-upgrade-instructions)

## Round 4 — 2026-10-12T15:21:42Z — 627b89f (codex)

No findings. `codex review --base origin/main`: the documentation and symlink match the current code and workflows.

## Round 5 — 2026-10-12T15:26:03Z — 668e53f

Checks run at 668e53f: `bundle exec rake test` (103 runs, 286 assertions, 0 failures), `bundle exec ruby -Itest test/models/appkit/push_subscription_test.rb` (3 runs, 0 failures), `bundle exec rubocop` (82 files, no offenses), both Brakeman scans (0 warnings), `bundle exec bundler-audit check --update` (no vulnerabilities). `bin/rails test <file>` fails with `cannot load such file -- test_helper`, as documented. `bin/rails -T` lists `build`, `build:checksum`, `clean`, `clobber`, `install`, `install:local`, `release` and `test`, all from the gem `Rakefile`. `appkit:vapid_keys` was not run.

Round 3 fixes re-checked against the code: all nine hold. The `rails-ci.yml` fix is partial; see the first nit below. Every other claim in `AGENTS.md` was checked against the named files (configuration, routes, controllers, concerns, jobs, generator and templates, layout, rake task, CI workflows, lefthook files, `.rubocop_todo.yml`, `test/test_helper.rb`, dummy app, README, CHANGELOG, gemspec, Gemfile). No false or unverifiable claim was found.

Compliance:

- An agent new to appkit finds what the engine provides, its test and lint commands and its gotchas → `AGENTS.md` What this is, Domain, Commands, Gotchas (`grep -c` prints `4`). Every documented command behaves as described.
- A migration that apps must copy gets a `### Upgrading` subsection with the generator command → `AGENTS.md:43` and the example at `AGENTS.md:62-64`.
- An internal method change adds no `### Upgrading` subsection → `AGENTS.md:52`.
- Claude Code reads the same content through `CLAUDE.md` → `test -L CLAUDE.md && readlink = AGENTS.md && cmp` passes.
- Plan `## Proof` names checks, not tests; all four pass. No existing test is weakened, skipped or deleted (the diff adds only `AGENTS.md`, `CLAUDE.md` and the change folder).

Findings:

- [x] Nit: The `rails-ci.yml` gotcha lists the app binstubs the workflow calls, but the list omits `bin/rails` (`.github/workflows/rails-ci.yml:98`, `:128`), so it reads as complete when it is not. Round 3 also asked to cover any new secret or file the workflow needs from apps; the fix covers only binstubs. A new required secret breaks every app's CI at merge in the same way. — `AGENTS.md:31` → fixed (Close review round 5 nits for agents-md-with-upgrade-instructions)
- [x] Nit: Domain lists host requirements but omits `config.app_name`. It defaults to `nil`, and every engine view calls `.call` on it (`app/views/layouts/login.html.erb:4`, `app/views/appkit/sessions/new.html.erb:4`, `app/views/appkit/pwa/manifest.json.erb:2`). So an app must set it to a callable. The README example sets a String (`README.md:102`), which raises `NoMethodError` on the login page. An agent that follows the README hits this. — `AGENTS.md:9` → fixed (Close review round 5 nits for agents-md-with-upgrade-instructions)
- [x] Nit: "An app ... finds its new steps with `git diff <old-sha>..<new-sha> -- CHANGELOG.md`" does not say where to run it. The command needs an appkit clone with history; an agent working in a host app has none at hand. Say to run it in an appkit checkout. — `AGENTS.md:39` → fixed (Close review round 5 nits for agents-md-with-upgrade-instructions)

## Round 6 — 2026-10-12T15:26:30Z — 668e53f (codex)

No findings. `codex review --base origin/main`: the guidance and symlink match the code, README, generator and workflows.
