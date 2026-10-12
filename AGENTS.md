# Appkit

## What this is

A non-isolated Rails engine (`Appkit::Engine`, no `isolate_namespace`) that several personal Rails apps share. It provides session-based authentication: login, a FirstRun bootstrap, and session transfer with a QR magic link. It also provides a PWA manifest, a service worker with web push, theme and preferences, `VersionHeaders` and `Authorization`. Further parts are okcomputer health checks, static error pages and a reusable CI workflow. Apps install it with `gem "appkit", github: "eirvandelden/appkit"` and pin a git SHA, because the project uses SHAs instead of semver (`CHANGELOG.md`). It requires Rails (railties) >= 8.0 (`appkit.gemspec`).

## Domain

Host apps own the `User` and `Session` models. Appkit reaches them through `Appkit.config.user_class`, `session_class` and `user_scope`; `lib/appkit/configuration.rb` is the source of truth for every option. Host models include the concerns `Appkit::Authenticatable`, `Appkit::SessionBehavior`, `Appkit::Transferable` and `Appkit::UserTheming`. Host controllers include `Appkit::Authentication`, `Appkit::VersionHeaders` and `Appkit::Authorization`. `Appkit::Authorization` is a controller concern, although its file lives in `app/models/concerns/`. Host apps also define `Current` with `user` and `session` attributes, because the engine uses `Current` directly, not through `Appkit.config`. The engine owns one model, `Appkit::PushSubscription` (table `appkit_push_subscriptions`), plus `Appkit::FirstRun`, `Appkit::ManifestIcon` and `Appkit::QrCodeLink`. `config/routes.rb` draws straight into `Rails.application.routes`: `/first_run`, `/session` (with transfers), `/qr_code/:id`, `/preferences`, `/manifest`, `/service-worker` and `/push_subscription`. Jobs are `Appkit::PushNotificationJob` and `Appkit::SessionExpiryJob`. Locale files for `en`, `nl` and `it` live in `config/locales/`. `test/dummy` is the host app that the tests run against. The install generator (`lib/generators/appkit/install`) is the only way migrations, error pages and the CI caller reach an app.

## Commands

- Install: `bundle install`. The Ruby version comes from `.ruby-version` via `rv`.
- Test: `bundle exec rake test` (Minitest, `test/**/*_test.rb`, against `test/dummy`).
- One test file: `bundle exec ruby -Itest test/models/appkit/push_subscription_test.rb`. `bin/rails test <file>` fails here with `cannot load such file -- test_helper`.
- Lint: `bundle exec rubocop`.
- Security: `bundle exec brakeman -p test/dummy --no-pager --ignore-config config/brakeman.ignore`, then `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`, then `bundle exec bundler-audit check --update`.
- VAPID keys: a host app runs `bin/rails appkit:vapid_keys` (`lib/tasks/appkit.rake`). It generates a web push key pair and prints both keys and a `credentials.yml.enc` snippet. The task does not run in this repository: `bin/rails -T` here lists only the gem's build and release tasks. The output holds the private key, so do not run it in a shared log.
- CI: `.github/workflows/ci.yml` runs the same scans, RuboCop and tests.

## Gotchas

- There is no `isolate_namespace`. Engine routes and helpers live in the host's namespace, so an app route with the same path collides (`lib/appkit/engine.rb`, `config/routes.rb`).
- `mvpa-css` is a git co-gem declared in `Gemfile`, not in `appkit.gemspec`. Apps add it to their own `Gemfile`.
- Apps register appkit's Stimulus controllers by hand in their own `controllers/index.js`. A missing `auto-submit` registration silently breaks the magic-link flow (README).
- The engine's own `login` layout renders `javascript_importmap_tags`. An app that overrides that layout must keep the tag, or the magic-link flow breaks.
- `lib/appkit/version.rb` appends the short git SHA to the version. Once HEAD has moved since `Gemfile.lock` was written, any `bundle exec` or `bin/rails` command rewrites the `appkit (0.1.0.pre.git.<sha>)` self-reference in it. Do not commit that rewrite with an unrelated change.
- `test/dummy/db/schema.rb` is hand-written, and `test/test_helper.rb` loads it on every run. A new migration template needs the matching schema edit there.
- `test/test_helper.rb` clears `Rails.cache` before each test, because the `sessions#create` rate limiter counts attempts in the cache.
- `Appkit::SessionExpiryJob` keeps its name although it breaks `Obsession/Rails/ServiceName`. Apps schedule it by name in `config/recurring.yml` (`.rubocop_todo.yml`).
- Apps call `.github/workflows/rails-ci.yml` at `@main`, not at their pinned SHA. A change there reaches every app's CI at merge. Add a new input only as optional, with a default, so no app's CI breaks. The repository must stay public (README).
- Brakeman runs twice with two ignore files: `config/brakeman.ignore` for the dummy app and `config/brakeman.gem.ignore` for the gem root (`ci.yml`).
- `lefthook-local.yml` skips the CSS, JS and ERB hooks, the per-file test hooks and the Brakeman and bundler-audit pre-push hooks. CI runs the tests, RuboCop, Brakeman and bundler-audit. No CSS, JS or ERB lint runs anywhere, so check those files by hand.
- Re-running `bin/rails generate appkit:install` in an app that already ran it needs `--skip`. Without it, an existing migration with changed content raises a conflict. The generator picks `align_sessions_for_appkit` over `create_sessions` whenever a `sessions` table exists.
- Use `rv` for Ruby. Do not use mise, asdf, rbenv or rvm.

## Upgrade instructions

A change that requires apps to act adds a `### Upgrading` subsection to the `CHANGELOG.md` entry that records the change. Put it after that entry's `### Added`, `### Changed` and `### Fixed` subsections. Today that entry is `## Unreleased`. When dated `## YYYY-MM-DD` headings exist, it is the dated one. Do not change the changelog format to add it. Write one instruction per step, with an exact command where one exists, in the order an app runs them. Only write a step that you ran or read in the code. An app that moves from one pinned SHA to another finds its new steps with `git diff <old-sha>..<new-sha> -- CHANGELOG.md`.

A change requires apps to act when it is one of these:

- A new migration template in `lib/generators/appkit/install/templates/`. Ship a schema change as a new, uniquely named template. Never change a template that apps already copied, because `--skip` leaves the app's old copy in place.
- A new or renamed `Appkit.config` option that an app must set, or a removed option that an app must stop setting (`lib/appkit/configuration.rb`).
- A new Stimulus controller pin in `config/importmap.rb` that apps must register in their own `controllers/index.js`.
- A renamed or removed public class, concern, helper, partial, route or job. Apps reference these by name, such as `Appkit::SessionExpiryJob` in `config/recurring.yml`.
- New credentials, such as `web_push`.
- A new co-gem line in the app's `Gemfile`, such as `mvpa-css`.
- A new requirement for apps that override an engine layout or view.

A change that does not require apps to act adds no `### Upgrading` subsection. Examples are internal method changes, test-only changes, engine CI changes and lint fixes.

Example, an illustration built on the real `create_appkit_push_subscriptions` migration template:

```markdown
## Unreleased

### Added
- Web push subscriptions, stored in `appkit_push_subscriptions`.

### Upgrading
1. Run `bin/rails generate appkit:install --skip` to copy the `create_appkit_push_subscriptions` migration.
2. Run `bin/rails db:migrate`.
```

In an app that first got `create_sessions`, step 1 also creates an `align_sessions_for_appkit` migration, because the `sessions` table now exists. That migration is safe to run.
