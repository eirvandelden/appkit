# Appkit

## What this is

A non-isolated Rails engine (`Appkit::Engine`, no `isolate_namespace`) that several personal Rails apps share. It provides session-based authentication: login, a FirstRun bootstrap, and session transfer with a QR magic link. It also provides a PWA manifest, a service worker with web push, theme and preferences, `VersionHeaders` and `Authorization`. Further parts are okcomputer health checks, static error pages and a reusable CI workflow. Apps install it with `gem "appkit", github: "eirvandelden/appkit", tag: "X.Y.Z"`. Releases follow semver: a release workflow tags each merge to `main` (`CHANGELOG.md`, `## Releases and versions`). An old SHA pin keeps working. It requires Rails (railties) `~> 8.1` (`appkit.gemspec`).

## Domain

Host apps own the `User` and `Session` models. Some engine code reaches them through `Appkit.config.user_class`, `session_class` and `user_scope`, and `lib/appkit/configuration.rb` lists every option. Other code names the classes directly. `SessionLookup` calls `Session.find_by`, `Appkit::Authenticatable` declares `has_many :sessions`, and `Appkit::PushSubscription` declares `belongs_to :user`. So the host classes must be called `User` and `Session`, whatever the config says. Host models include the concerns `Appkit::Authenticatable`, `Appkit::SessionBehavior`, `Appkit::Transferable` and `Appkit::UserTheming`. Host controllers include `Appkit::Authentication`, `Appkit::VersionHeaders` and `Appkit::Authorization`. `Appkit::Authorization` is a controller concern, although its file lives in `app/models/concerns/`. Its `ensure_can_administer` needs `User#can_administer?`. Its `ensure_current_user` needs a `@user` that responds to `current?`. Host apps also define `Current` with `user` and `session` attributes, because the engine uses `Current` directly, not through `Appkit.config`. Most engine controllers inherit the host's `::ApplicationController`, so that class must include `Appkit::Authentication`. The host must define a `root` route, because the engine redirects to `root_url`. `Appkit::VersionHeaders` needs `config.app_version` and `config.git_revision` (README). `Appkit.config.app_name` must be a callable, such as `-> { "My App" }`, because every engine view calls `.call` on it. The README example sets a String, which raises `NoMethodError` on the login page. The engine owns one Active Record model, `Appkit::PushSubscription` (table `appkit_push_subscriptions`). It also has three plain Ruby classes: `Appkit::FirstRun`, `Appkit::ManifestIcon` and `Appkit::QrCodeLink`. `config/routes.rb` draws straight into `Rails.application.routes`: `/first_run`, `/session` (with transfers), `/qr_code/:id`, `/preferences`, `/manifest`, `/service-worker` and `/push_subscription`. Jobs are `Appkit::PushNotificationJob` and `Appkit::SessionExpiryJob`. Locale files for `en`, `nl` and `it` live in `config/locales/`. `test/dummy` is the host app that the tests run against. The install generator (`lib/generators/appkit/install`) is the only way migrations, error pages and the CI caller reach an app.

## Commands

- Install: `bundle install`. The Ruby version comes from `.ruby-version` via `rv`.
- Test: `bin/rails test` or `bundle exec rake test` (Minitest, `test/**/*_test.rb`, against `test/dummy`).
- One test file: `bin/rails test test/models/appkit/push_subscription_test.rb`. `bin/rails test` prints `Unrecognized command "db:test:prepare"` first. The tests still run.
- Lint: `bundle exec rubocop`, and `bundle exec erb_lint --lint-all` for the ERB views.
- Security: `bundle exec brakeman -p test/dummy --no-pager --ignore-config config/brakeman.ignore`, then `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`, then `bin/bundler-audit check --update`.
- VAPID keys: a host app runs `bin/rails appkit:vapid_keys` (`lib/tasks/appkit.rake`). It generates a web push key pair and prints both keys and a `credentials.yml.enc` snippet. The task does not run in this repository: `bin/rails -T` here lists only the tasks from the gem `Rakefile`. The output holds the private key, so do not run it in a shared log.
- Types: `bundle exec rake rbs:generate` regenerates `sig/` from the inline `#:` signatures. `bundle exec rake rbs:check` fails when `sig/` differs from them. `bundle exec rake steep` type-checks `app/` and `lib/`, then `test/types/` as a host app (README, `## Type signatures`).
- CI: `.github/workflows/ci.yml` runs the same scans, RuboCop and tests. Its `types` job runs `rbs:check` and `steep`.

## Gotchas

- There is no `isolate_namespace`. Engine routes and helpers live in the host's namespace, so an app route with the same path collides (`lib/appkit/engine.rb`, `config/routes.rb`).
- `mvpa-css` is a git co-gem declared in `Gemfile`, not in `appkit.gemspec`. Apps add it to their own `Gemfile`.
- Apps register appkit's Stimulus controllers by hand in their own `controllers/index.js`. A missing `auto-submit` registration silently breaks the magic-link flow (README).
- The engine's own `login` layout renders `javascript_importmap_tags`. An app that overrides that layout must keep the tag, or the magic-link flow breaks.
- `lib/appkit/version.rb` holds the plain released version, which the release workflow stamps (never edit it by hand). appkit does not commit `Gemfile.lock` (it is in `.gitignore`). A fresh clone and CI resolve the newest allowed gems. An existing checkout keeps its own lockfile until `bundle update`. The service worker cache name reads `Appkit.revision` (`lib/appkit/revision.rb`), which uses the full SHA from a host's Bundler git source, so it also rotates when a Docker build deletes the gem's `.git` directory.
- `test/dummy/db/schema.rb` is hand-written, and `test/test_helper.rb` loads it on every run. A new migration template needs the matching schema edit there.
- `test/test_helper.rb` clears `Rails.cache` before each test, because the `sessions#create` rate limiter counts attempts in the cache.
- `Appkit::SessionExpiryJob` keeps its name although it breaks `Obsession/Rails/ServiceName`. Apps schedule it by name in `config/recurring.yml` (`.rubocop_todo.yml`).
- Apps call `.github/workflows/rails-ci.yml` at the moving major tag (`@<major>`, the bare major number), or at `@main` when they have not moved yet. A change there reaches an `@main` app's CI at merge, and a `@<major>` app at the next release of that major. The release workflow moves the major tag. Add a new input only as optional, with a default, so no app's CI breaks. The workflow also uses app files: the binstubs `bin/brakeman`, `bin/bundler-audit`, `bin/importmap`, `bin/rubocop` and `bin/rails`. Never make it need a new binstub, file or secret that apps may not have. The repository must stay public (README).
- Dependabot (`.github/dependabot.yml`) skips its one-week cooldown for security update pull requests ("The `cooldown` option is only available for *version* updates, not *security* updates", https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference, section `cooldown`). It also skips it for the git gems `mvpa-css` and `rubocop-eirvandelden`: it proposes the newest commit of the tracked branch as a new `revision` in `Gemfile.lock`, and the cooldown filters only version tags (https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/update_checker.rb#L286-L308, https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/common/lib/dependabot/git_commit_checker.rb#L160-L167).
- Dependabot checks indirect gems such as marcel, because `dependency-type: "all"` is set (https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference, section `allow`). It opens a pull request only for a version that Bundler resolves with the other locked gems. Active Storage requires `marcel (~> 1.0)`, so marcel 2.x gives no pull request (https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/update_checker.rb#L36-L40).
- Dependabot fetches `lib/appkit/version.rb` with the gemspec and replaces `Appkit::VERSION` in its temporary gemspec with the `appkit (...)` version already in `Gemfile.lock`. Its pull requests leave the `appkit (X.Y.Z)` lines unchanged. After a release the version moves, so a stale local `Gemfile.lock` needs `bundle lock` before the next `bundle exec` (https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/file_fetcher.rb, https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/file_updater/lockfile_updater.rb#L338-L360).
- A Dependabot major bump of a runtime gem in `appkit.gemspec` widens the range (`~> 8.1` becomes `>= 8.1, < 10`) instead of keeping the `~> major.minor` style of the `dependencies` skill. Rewrite it in the pull request. A pull request that changes `appkit.gemspec` runtime dependencies or `rails-ci.yml` reaches apps: add its `changelog.d/<branch-slug>.md` fragment, with `### Upgrading` and `level: major` when apps must act, before merge. Never edit `CHANGELOG.md` for it. `spinel-coop/setup-rv@main` is a branch ref, so Dependabot never updates it (https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/update_checker/requirements_updater.rb#L188-L260, https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/github_actions/lib/dependabot/github_actions/file_parser.rb#L94).
- Brakeman runs twice with two ignore files: `config/brakeman.ignore` for the dummy app and `config/brakeman.gem.ignore` for the gem root (`ci.yml`).
- `lefthook-local.yml` skips the CSS and JS hooks and the Brakeman pre-push hook. The bundler-audit pre-push hook runs `bin/bundler-audit` when `Gemfile` or `appkit.gemspec` changes. On a machine without the advisory database, run `bin/bundler-audit update` once first, because the download can fail inside a git hook. The ERB lint (`bundle exec erb_lint`) and the per-file test hook run. CI runs the tests, RuboCop, Brakeman and bundler-audit, not erb_lint. No CSS or JS lint runs anywhere, so check those files by hand.
- Re-running `bin/rails generate appkit:install` in an app that already ran it needs `--skip`. Without it, an existing migration with changed content raises a conflict. The generator picks `align_sessions_for_appkit` over `create_sessions` whenever a `sessions` table exists.
- Use `rv` for Ruby. Do not use mise, asdf, rbenv or rvm.
- `sig/**/*.rbs` is generated from the inline `#:` signatures; never edit it by hand. Change the `#:` comment, then run `bundle exec rake rbs:generate`. `sig/manifest.yaml` is hand-written. The pre-commit hook runs `rbs:check_staged` and the pre-push hook runs `steep` (`lefthook-local.yml`).

## Releases and versions

appkit follows semver. Every PR declares its level in its own fragment, `changelog.d/<branch-slug>.md`, and never writes a version number. Never edit `lib/appkit/version.rb` by hand, and never edit `CHANGELOG.md` for an unreleased change. A release workflow (`.github/workflows/release.yml`) runs on each merge to `main`. It takes the highest level among the pending fragments (a merge with no fragment releases a patch), stamps `version.rb` and `CHANGELOG.md`, deletes the fragments, tags `X.Y.Z` with no `v` prefix, moves the major tag (the bare major number) and creates the GitHub Release. The code is `script/semver/`. It uses the standard library only and never ships in the gem.

A fragment is Markdown with front matter:

```markdown
---
level: minor
---
### Added
- Web push subscriptions, stored in `appkit_push_subscriptions`.
```

Sections are `### Added`, `### Changed`, `### Fixed` and `### Upgrading`. Leave out an empty section. Pick the level like this:

- `level: major`: apps must act, or the change breaks an app. Only a major fragment may have `### Upgrading`.
- `level: minor`: an opt-in feature. Apps that do nothing keep working.
- `level: patch`: a bug fix, a security fix, or a change with no app-facing effect.

The `Changelog check` workflow (`script/semver/bin/surface --base <ref> --head HEAD`) fails a PR when its diff touches the public surface and the declared level is below the floor it detects. A PR with no fragment counts as patch. The detection is a heuristic, so it cannot see a changed default, a changed behaviour with the same signature or a removed view or partial: judge those yourself. Silence a false positive with `overrides:` in the front matter, a rule id and a reason, for example `overrides: {config: "the option is optional"}`. The rule ids are in `script/semver/rules.rb`.

A change requires apps to act, and so is `level: major` with an `### Upgrading` section, when it is one of these:

- A new migration template in `lib/generators/appkit/install/templates/`. Ship a schema change as a new, uniquely named template. Never change a template that apps already copied, because `--skip` leaves the app's old copy in place.
- A new or renamed `Appkit.config` option that an app must set (`lib/appkit/configuration.rb`).
- A removed `Appkit.config` option that an app must stop setting.
- A new Stimulus controller pin in `config/importmap.rb` that apps must register in their own `controllers/index.js`.
- A renamed or removed public class, concern, helper, partial, route or job. Apps reference these by name, such as `Appkit::SessionExpiryJob` in `config/recurring.yml`.
- New credentials, such as `web_push`.
- A new co-gem line in the app's `Gemfile`, such as `mvpa-css`.
- A new requirement for apps that override an engine layout or view.

A change that does not require apps to act has no `### Upgrading` section. Examples are internal method changes, test-only changes, changes to the engine's own `.github/workflows/ci.yml` and lint fixes. Write one instruction per step, with an exact command where one exists, in the order an app runs them. Only write a step that you ran or read in the code. An app that moves from one version to another reads the `CHANGELOG.md` sections between them.

Example fragment, an illustration built on the real `create_appkit_push_subscriptions` migration template:

```markdown
---
level: major
---
### Added
- Web push subscriptions, stored in `appkit_push_subscriptions`.

### Upgrading
1. Run `bin/rails generate appkit:install --skip` to copy the `create_appkit_push_subscriptions` migration.
2. Run `bin/rails db:migrate`.
```

In an app that first got `create_sessions`, step 1 also creates an `align_sessions_for_appkit` migration, because the `sessions` table now exists. That migration is safe to run, but not safe to roll back: its `down` removes `last_active_at`, which login needs.
