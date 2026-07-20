# Appkit

A non-isolated Rails engine bundling session-based authentication, PWA
installability with web push notifications, and theme/preferences
management for host Rails applications.

Appkit requires [`mvpa-css`](https://github.com/eirvandelden/mvpa.css) as
a co-gem for its themed UI components. `mvpa-css` is not declared in
`appkit.gemspec` — gemspecs cannot declare git-sourced dependencies, so
it is declared in this repo's `Gemfile` instead. Consuming apps must add
`mvpa-css` to their own `Gemfile` as well.

Appkit depends directly on [`importmap-rails`](https://github.com/rails/importmap-rails)
(declared in `appkit.gemspec`, unlike `mvpa-css` — no action needed in
consuming apps). The engine's own `config/importmap.rb` pins
`appkit/pwa.js`, `appkit/controllers/push_controller.js`,
`appkit/controllers/theme_controller.js`, and
`appkit/controllers/auto_submit_controller.js` via the importmap DSL, and
`lib/appkit/engine.rb` adds that file to the host app's
`config.importmap.paths` automatically. The host's own layouts must still
render `<%= javascript_importmap_tags %>` (including the `login` layout —
a missing tag there silently breaks the auto-submit magic-link flow, since
no JS runs on that page at all).

The engine is deliberately **not** `isolate_namespace`d: host apps' URL
helpers (`root_url`, etc.) need to work from inside engine controllers
and views.

### JavaScript controllers

`eagerLoadControllersFrom` only autoloads Stimulus controllers from the
host app's own `controllers/` importmap namespace — it does **not** pick
up appkit's `appkit/controllers/*` pins automatically. Host apps must
register each one explicitly in their `app/javascript/controllers/index.js`:

```js
import PushController from "appkit/controllers/push_controller"
application.register("push", PushController)

import ThemeController from "appkit/controllers/theme_controller"
application.register("theme", ThemeController)

import AutoSubmitController from "appkit/controllers/auto_submit_controller"
application.register("auto-submit", AutoSubmitController)
```

Skipping `auto-submit` breaks the session-transfer (magic-link) flow
silently: the transfer `show` page renders but never submits, so the
user gets stuck on the intermediate page instead of being logged in.

### Login page branding

The login layout colors its heading with `--color-accent`. Host apps set
this once, e.g. in a `themes/brand.css`:

```css
:root {
  --color-accent: var(--color-blue);
}
```

If a host app forgets to set it, the login page falls back to magenta
rather than rendering unstyled.

## Installation

```ruby
gem "appkit", github: "eirvandelden/appkit"
gem "mvpa-css", github: "eirvandelden/mvpa.css"
```

Host apps should add this one-line directive to their own
`ApplicationController` — it's not part of the engine itself:

```ruby
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges,
  # import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
```

See "Configuration" and "Web Push setup" below for the remaining
per-app setup steps.

## Status

Phase 0 is complete: session-based authentication (login, FirstRun
bootstrap, session transfer/QR handoff), PWA installability with web
push notifications, theme/preferences management, VersionHeaders,
Authorization, static error pages, and CI (engine + reusable app
workflow) are all implemented.

## Configuration

Host apps configure Appkit via `Appkit.config` (see
`lib/appkit/configuration.rb` for the source of truth), typically in a
`config/initializers/appkit.rb`:

```ruby
Appkit.configure do |config|
  config.app_name = "My App"
end
```

| Option | Default | Description |
| --- | --- | --- |
| `app_name` | `nil` | Display name used in the PWA manifest. |
| `email_attribute` | `:email` | Attribute on `user_class` used as the user's email/login identifier. |
| `user_scope` | `-> { User.all }` | Relation used to look up users (e.g. for sign-in). |
| `user_class` | `-> { "User".constantize }` | Lazily-resolved host app User class. |
| `first_run` | creates a `User` with `role: :administrator` | Callable used by the FirstRun bootstrap flow to create the first administrator account. |
| `icons` | `%w[/icon.svg /icon-192.png /icon-512.png /icon-mask-512.png]` | Icon paths advertised in the PWA manifest. |
| `sw_extra_cache_paths` | `[]` | Extra paths the service worker should precache alongside the default offline shell. |
| `brand_color` | `nil` | Theme color used in the PWA manifest and browser chrome. |
| `timezone_attribute` | `nil` | Attribute on the user model for their timezone preference; the timezone field on the preferences form is only shown when this is set and the user responds to it. |
| `locale_attribute` | `:locale` | Attribute on the user model for their locale preference; the locale field on the preferences form is only shown when this is set and the user responds to it. |
| `session_expiry` | `1.year` | How long a session may sit idle before `Appkit::SessionExpiryJob` destroys it. Matches the signed-cookie lifetime by default, so it changes no real user's experience — see "Session hygiene" below. |
| `session_class` | `-> { "Session".constantize }` | Lazily-resolved host app Session class. |

## Session hygiene

The signed session cookie stops renewing once a browser drops it, but a
stolen token replayed directly against the server never goes through the
cookie at all — nothing expires it. `Appkit::SessionExpiryJob` closes that
gap by destroying any session whose `last_active_at` is older than
`config.session_expiry`. It isn't scheduled automatically (the engine doesn't
own the host's recurring-job config) — add it yourself, e.g. in
`config/recurring.yml`:

```yaml
production:
  appkit_session_expiry:
    class: Appkit::SessionExpiryJob
    schedule: every day at midnight
```

## Web Push setup

Push notifications use the `web-push` gem with VAPID keys. Generate a
key pair with the bundled rake task:

```
bin/rails appkit:vapid_keys
```

This prints a public/private key pair and a `credentials.yml.enc`
snippet to paste in (`bin/rails credentials:edit`):

```yaml
web_push:
  vapid_public_key: ...
  vapid_private_key: ...
  subject: mailto:you@example.com
```

`Appkit::PushNotificationJob` reads these via
`Rails.application.credentials.dig(:web_push, :subject/:vapid_public_key/:vapid_private_key)`
at delivery time.

## Version headers

`Appkit::VersionHeaders` sets `X-Version`/`X-Rev` response headers from
`Rails.application.config.app_version`/`config.git_revision`. Host apps
must set both themselves; they are not provided by the engine. See
`test/dummy/config/application.rb` for the pattern:

```ruby
module MyApp
  class Application < Rails::Application
    config.app_version = "1.2.3"
    config.git_revision = "deadbeef"
  end
end
```

## Health checks

Appkit mounts [`okcomputer`](https://github.com/sportngin/okcomputer) so an
uptime monitor (e.g. Uptime Kuma) can poll a check that's representative of
real app health, not just a bare 200 OK. By default it registers:

- `"default"` — trivial "app is running" check (from the gem itself).
- `"database"` — real DB connectivity (from the gem itself, auto-registered
  whenever `ActiveRecord` is defined).
- `"cache"` — only when `Rails.cache` is a `SolidCache::Store`; skipped for
  other cache backends.
- `"queue"` — only when `Rails.application.config.active_job.queue_adapter`
  is `:solid_queue`; verifies at least one `SolidQueue::Process` has
  heartbeated recently (worker liveness), not queue depth/backlog.

Point your uptime monitor at `<health_check_path>/all`, **not** the bare
root — the root path only runs the trivial `"default"` check, while `/all`
runs every registered check and returns `500` if any fail.

Configure the mount path (default `"healthz"`, chosen to avoid colliding with
Rails' own `/up` health check route):

```ruby
Appkit.configure do |config|
  config.health_check_path = "healthz"
end
```

To protect the endpoint with HTTP Basic auth, call `OkComputer.require_authentication`
directly from your own initializer (Appkit does not wrap this, since Uptime
Kuma polling usually doesn't need auth):

```ruby
OkComputer.require_authentication(Rails.application.credentials.dig(:health_check, :username),
                                   Rails.application.credentials.dig(:health_check, :password))
```

## Continuous Integration

This repo's own `.github/workflows/ci.yml` tests the engine against
`test/dummy` (`bundle exec rake test`), lints with RuboCop, and scans for
security issues with Brakeman/bundler-audit.

Consuming apps get CI via `.github/workflows/rails-ci.yml`, a reusable
`workflow_call` workflow with `scan_ruby`, `scan_js`, `lint`, `test`, and
`system-test` jobs. Each app's own CI becomes a thin ~6-line caller (see
`lib/generators/appkit/install/templates/github/workflows/ci.yml.tt`,
copied in by `bin/rails generate appkit:install`):

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  ci:
    uses: eirvandelden/appkit/.github/workflows/rails-ci.yml@main
    with:
      run_system_tests: true
```

Cross-repo reusable workflows require this repo to stay **public** — a
private repo would need each consuming app's Settings → Actions → Access
to explicitly allow `eirvandelden/appkit`, plus credentials for `bundle
install` to fetch the git-sourced gem.

## Third-party notices

Some of appkit's auth code is adapted from Basecamp's
[Writebook](https://github.com/basecamp/writebook) (MIT license). See
`THIRD_PARTY_NOTICES.md` for details.
