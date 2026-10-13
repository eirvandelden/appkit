# Plan: app_name accepts a string, a callable or a translation

From `intent.md` (2026-10-13). Status: accepted.

## Context

Appkit is a Rails engine (Minitest, fixtures, dummy app in `test/dummy`, module `Dummy`). `Appkit.config.app_name` is a plain `attr_accessor` with no default (`nil`). Five engine templates call `Appkit.config.app_name.call`, so a String or `nil` crashes them with `NoMethodError`:

- `app/views/layouts/login.html.erb:4` (`<title>`)
- `app/views/appkit/first_runs/show.html.erb:2` (`<h1>`)
- `app/views/appkit/shared/_nav.html.erb:2` (`<h2>`)
- `app/views/appkit/sessions/new.html.erb:4` (`<h1>`)
- `app/views/appkit/pwa/manifest.json.erb:2` (`name`)

The dummy app layout `test/dummy/app/views/layouts/application.html.erb:4` does the same, and `test/dummy/config/initializers/appkit.rb:2` sets `-> { "Dummy" }`.

The engine never sets `I18n.locale` itself. The host app does that in its own `ApplicationController`. Every engine controller inherits `::ApplicationController`, except `Appkit::PwaController`, which inherits `ActionController::Base` and so never sees the host's locale switch.

## Design decisions

- **Name resolution lives in a PORO, `Appkit::AppName`**, in `app/models/appkit/app_name.rb`, next to the existing `Appkit::ManifestIcon` PORO. It takes the configured value and the host module name, and `#to_s` returns the first non-blank of:
  1. `I18n.t(:app_name, default: nil, fallback: false)` for the current locale, only when it is a `String` (a host app that uses `app_name` as a namespace hash does not render a hash). `fallback: false` keeps a host's `I18n.fallbacks` chain from handing an English visitor the Dutch name, so the key counts only when the current locale defines it.
  2. The configured value: called when it responds to `call`, used as is otherwise.
  3. The host module name split into words with `titleize` (`"MyRecipeBook"` becomes `"My Recipe Book"`).
- **The host module name is injected with a production default**: the constructor is `def initialize(configured, host_module_name: Rails.application.class.module_parent_name)`. `Configuration#app_display_name` calls `AppName.new(app_name)` and relies on that default; only tests pass `host_module_name:`. Minitest 6 has no `minitest/mock` in this bundle, and the dummy module is `Dummy`, so the `MyRecipeBook` splitting is proven in the unit test through the injected name. The page-level tests prove the production path (default argument, real `Rails.application`) with the dummy name `Dummy`.
- **One public reader for views: `Appkit::Configuration#app_display_name`**, which returns `AppName.new(app_name).to_s`. The raw `app_name` reader stays unchanged, so a host app view that calls `Appkit.config.app_name.call` with a callable keeps working (backwards compatibility constraint).
- **All five engine templates and the dummy layout call `Appkit.config.app_display_name`.**
- **`Appkit::PwaController` inherits `::ApplicationController` and declares `allow_unauthenticated_access`**, the same pattern as `Appkit::FirstRunsController` and `Appkit::QrCodeController`. The manifest then runs inside the host's locale switch, like the other engine pages. `skip_forgery_protection` stays. `allow_unauthenticated_access` also restores a signed-in session, so a host that picks the locale from the user's preference gets it on the manifest too.
- **The dummy app gets a test-only locale switch**: `around_action :switch_locale` in `test/dummy/app/controllers/application_controller.rb`, which wraps the action in `I18n.with_locale(params[:locale] || I18n.default_locale)`. This is how the tests act as "a Dutch visitor". It is test infrastructure, not engine behaviour.
- **The Dutch host translation is stored per test**: `I18n.backend.store_translations(:nl, app_name: "Receptenboek")` in the test, `I18n.backend.reload!` in teardown. No locale file in the dummy app, so no other test sees the key. Appkit's own `config/locales/appkit.{en,nl,it}.yml` stay without an `app_name` key.

## Integration points

- Rails I18n (`I18n.t`, current `I18n.locale`, the host's `I18n.fallbacks` setting when enabled).
- `Rails.application.class.module_parent_name` for the fallback.
- `I18n.fallbacks`: deliberately bypassed for the `app_name` key.
- The host app's `::ApplicationController` and its `Appkit::Authentication` include, which `Appkit::PwaController` now depends on, like every other engine controller.
- Host app layouts that render the name themselves (README documents `Appkit.config.app_display_name`).

## Files that change

- `app/models/appkit/app_name.rb` — new PORO with the resolution order above.
- `lib/appkit/configuration.rb` — add `#app_display_name`.
- `app/views/layouts/login.html.erb`, `app/views/appkit/first_runs/show.html.erb`, `app/views/appkit/shared/_nav.html.erb`, `app/views/appkit/sessions/new.html.erb`, `app/views/appkit/pwa/manifest.json.erb` — call `Appkit.config.app_display_name` instead of `.app_name.call`.
- `app/controllers/appkit/pwa_controller.rb` — inherit `::ApplicationController`, add `allow_unauthenticated_access`.
- `test/dummy/config/initializers/appkit.rb` — `config.app_name = "Dummy"`.
- `test/dummy/app/views/layouts/application.html.erb` — call `Appkit.config.app_display_name`.
- `test/dummy/app/controllers/application_controller.rb` — `around_action :switch_locale` from `params[:locale]`.
- `test/models/appkit/app_name_test.rb` — new unit tests.
- `test/appkit/configuration_test.rb` — add `#app_display_name` tests.
- `test/integration/app_name_test.rb` — new acceptance tests across the five places.
- `test/controllers/appkit/pwa_controller_test.rb` — add the Dutch-manifest test.
- `README.md` — configuration example stays `config.app_name = "My App"`; rewrite the `app_name` table row only.
- `CHANGELOG.md` — one `### Fixed` entry under `## Unreleased` (add the `### Fixed` heading below `### Added`).

## Order of work

1. Write `test/integration/app_name_test.rb` "a string app_name shows on the sign-in page, first-run page, nav, page title and manifest". Run it. Watch it fail with `NoMethodError: undefined method 'call' for an instance of String`.
2. In the same file, write the unset, `""` and `-> { nil }` acceptance tests. Watch the unset and `""` tests fail with `NoMethodError`. Watch the `-> { nil }` test fail on its assertion: the page renders an empty name and the manifest a JSON `null` instead of `Dummy`. Write the callable test; it passes today and stays as the backwards-compatibility guard.
3. Write `test/models/appkit/app_name_test.rb`. Run it, watch it fail with `NameError: uninitialized constant Appkit::AppName`. Implement `Appkit::AppName` until green.
4. Add the `#app_display_name` tests to `test/appkit/configuration_test.rb`, watch them fail, add the method.
5. Change the five engine templates to `Appkit.config.app_display_name`. Steps 1 and 2 go green.
6. Change `test/dummy/config/initializers/appkit.rb` to `"Dummy"` and the dummy layout to `app_display_name`. Run the full suite.
7. Add the dummy `switch_locale` around action. Write the Dutch-visitor acceptance test for the pages and the manifest test in `test/controllers/appkit/pwa_controller_test.rb`. The manifest test fails, because `PwaController` ignores the host locale. Change `PwaController` to inherit `::ApplicationController` with `allow_unauthenticated_access`. Green.
8. Update the README `app_name` row and the CHANGELOG.
9. Run `bundle exec rake test`, `bundle exec rubocop`, `bundle exec brakeman` and `bundle exec bundle-audit check` where available. `erb_lint` is not in the bundle, so the templates get no ERB linter run. Re-read the diff.

## Risks

- `PwaController` now runs the host's `ApplicationController` callbacks, `VersionHeaders` and any host `before_action`. A host `before_action` that redirects unauthenticated visitors outside `Appkit::Authentication` would now redirect the manifest and the service worker. This is the same exposure every other engine controller already has; `allow_unauthenticated_access` handles Appkit's own authentication. Rejected alternative: keep `ActionController::Base` and read the locale in the engine; the engine has no locale rule of its own, so it would not match "like the other pages".
- `allow_unauthenticated_access` resumes a signed-in session on each manifest and service-worker fetch, which updates the session's activity like any other page view.
- The manifest is served with `Cache-Control: no-cache` and no `Vary` header. A shared cache could serve one locale's manifest to another; browsers revalidate. Accepted per the intent's flagged concern on manifest caching.
- A host that enables `config.i18n.fallbacks` does not get the fallback locale's `app_name` key for a locale that lacks it; that locale shows the configured name instead. This follows the intent's "when the current locale defines it".
- `titleize` loses acronyms: `HTTPRecipes` becomes `Http Recipes`. A host that dislikes the derived name sets `app_name`.
- A host app whose own views call `Appkit.config.app_name.call` breaks if it switches to a string. The README row points to `Appkit.config.app_display_name`.
- The top-level `app_name` key can collide with a host key (intent's flagged concern). A non-String value is ignored, so a namespace hash does not render.

## Out of scope

- Other configuration options and their types.
- README sections other than the configuration example and the `app_name` row.
- An `app_name` key in Appkit's own locale files.
- A locale rule inside the engine (the host decides the locale).

## Proof

- A host app sets `app_name = "My App"`; the sign-in page, first-run page, nav, page title and PWA manifest show "My App" → `test/integration/app_name_test.rb` `test "a string app_name shows on the sign-in page, first-run page, nav, page title and manifest"`
- A host app sets `app_name = -> { "My App" }`; the same pages show "My App" → `test/integration/app_name_test.rb` `test "a callable app_name shows on every page that names the app"`
- A host app whose application module is `MyRecipeBook` sets no `app_name`; those pages show "My Recipe Book" → `test/models/appkit/app_name_test.rb` `test "falls back to the host module name split into words when nothing is configured"` and `test/integration/app_name_test.rb` `test "an unset app_name shows the host module name on every page"`
- A host app whose application module is `MyRecipeBook` sets `app_name = ""`; those pages show "My Recipe Book" → `test/models/appkit/app_name_test.rb` `test "treats an empty string as unset"` and `test/integration/app_name_test.rb` `test "an empty app_name shows the host module name on every page"`
- A host app whose application module is `MyRecipeBook` sets `app_name = -> { nil }`; those pages show "My Recipe Book" → `test/models/appkit/app_name_test.rb` `test "treats a callable returning nil as unset"` and `test/integration/app_name_test.rb` `test "a callable returning nil shows the host module name on every page"`
- A host app sets `app_name = "Recipe Book"` and defines `app_name: "Receptenboek"` in its `nl` locale file only; a Dutch visitor sees "Receptenboek" and an English visitor sees "Recipe Book" → `test/integration/app_name_test.rb` `test "a Dutch visitor sees the nl app_name translation and an English visitor the configured name"`
- A Dutch visitor fetches the PWA manifest of that host app; the manifest name is "Receptenboek" → `test/controllers/appkit/pwa_controller_test.rb` `test "manifest name uses the app_name translation for the request locale"`
- The README `app_name` row states the accepted values, the locale key, the order, the module-name fallback default and every place the name appears → check: `grep -n '^| \`app_name\`' README.md` and read the row against this criterion during review.

Per changed file, the unit tests expected, named as behaviour:

- `app/models/appkit/app_name.rb`: `AppName#to_s returns a configured string`, `calls a configured callable`, `prefers the app_name translation for the current locale`, `ignores the translation in a locale that does not define it`, `ignores an app_name translation reached only through I18n fallbacks`, `ignores a non-string app_name translation`, `treats an empty string as unset`, `treats a callable returning nil as unset`, `treats a callable returning an empty string as unset`, `falls back to the host module name split into words when nothing is configured`.
- `lib/appkit/configuration.rb`: `Configuration#app_display_name resolves the configured app_name`, `keeps the raw app_name reader unchanged for a callable`.
- `app/controllers/appkit/pwa_controller.rb`: `manifest name uses the app_name translation for the request locale`; the existing `manifest renders valid JSON built from configuration` already fetches the manifest without signing in and keeps passing, which proves unauthenticated access after the inheritance change.

Test setup: integration tests save `Appkit.config.app_name` in `setup` and restore it in `teardown`. First-run tests delete `Session` and `User` rows like `test/integration/first_run_test.rb`. Nav tests sign in with `sign_in_as users(:alice)` and fetch `root_url`. The Dutch tests call `I18n.backend.store_translations(:nl, app_name: "Receptenboek")` and `I18n.backend.reload!` in `teardown`, and pass `locale: "nl"` or `locale: "en"` as a request parameter for the dummy `switch_locale`. Unit tests pass `host_module_name: "MyRecipeBook"` and use `I18n.with_locale`. The fallbacks unit test builds its own `I18n::Backend::Simple` that includes `I18n::Backend::Fallbacks`, sets `I18n.fallbacks = { en: [:en, :nl] }`, and restores `I18n.backend` and `I18n.fallbacks` in `teardown`.

---
Domain skills applied: rails-architecture, object-oriented-design, rails-testing, rails-ui (i18n).

## Critique

### Round 1 (codex -p terra)

- `I18n.t(:app_name, default: nil)` follows a host's `I18n.fallbacks`, so an English visitor can get the Dutch name, against "when the current locale defines it" → fixed (lookup uses `fallback: false`; verified against i18n 1.15.2; added the unit test `ignores an app_name translation reached only through I18n fallbacks`; Risks line rewritten)
- The `host_module_name` injection contract was inconsistent with `Configuration` calling `AppName.new(app_name)` → fixed (the constructor default is now stated; `Configuration` relies on it; the page-level `Dummy` tests cover that production path)
- `PwaController` inheriting `::ApplicationController` makes the PWA endpoints depend on the host including `Appkit::Authentication` → dismissed: that dependency already exists, because `SessionsController`, `FirstRunsController` and `QrCodeController` call `require_unauthenticated_access` or `allow_unauthenticated_access` at class load and their routes are always drawn, so an eager-loaded host without the concern already fails to boot; the README gap on including the concern is outside this change's README scope
- The planned unauthenticated-manifest test duplicates the existing `manifest renders valid JSON built from configuration` test, which already fetches without signing in → fixed (the new test is dropped; Proof names the existing test)
- The `-> { nil }` acceptance test does not fail with `NoMethodError` before the change; it renders an empty name → fixed (Order of work step 2 states the assertion failure)
- `erb_lint` is not in the bundle, so the planned ERB lint run cannot happen → fixed (removed from step 9; no dependency is added)
