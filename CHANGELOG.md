# Changelog

**Note:** This project uses git SHAs instead of semver. Pin to a specific SHA in your Gemfile.

## Unreleased

### Added
- Engine skeleton and dummy-app test harness (Task 0). No auth/PWA/theme features yet.
- Session-based authentication: login/logout, session cookie, configurable `email_attribute`/`user_scope` (Task 1).
- FirstRun bootstrap, session transfer + QR magic-link handoff, `VersionHeaders`, `Authorization`, static error pages via the install generator, and `Authenticatable#deactivate!` (Task 1b). Portions adapted from Basecamp's Writebook (MIT) — see `THIRD_PARTY_NOTICES.md`.
- Theme/preferences: `UserTheming` concern (`color_scheme`/`light_theme`/`dark_theme` enums), `ThemeHelper`, Stimulus `theme_controller.js`, `PreferencesController`/view with an optional `config.timezone_attribute` gate, a reusable `_flashes` partial, and `en`/`nl`/`it` locale files covering sessions/first_run/preferences (Task 3).
- `Appkit::Menu`, `Appkit::Menu::Hub`, `Appkit::Menu::Page` and `Appkit::Menu::Link`: one menu map that places a request in a hub and a page, carries the origin hub in a `from` query parameter, and gives the back link and the exit path. Plus the `appkit/shared/account_menu` partial.
- Type signatures: appkit ships RBS in `sig/`, generated from inline `#:` comments with `rbs-inline`, and checks its own code with Steep. A type-checking app can drop its appkit stub or `@type const` workaround; a hand-written appkit stub left in place makes Steep report duplicate declarations.

### Changed
- appkit now requires Rails 8.1: the gemspec floors are railties `~> 8.1`, turbo-rails `~> 2.0`, importmap-rails `~> 2.2`, web-push `~> 3.1`, rqrcode `~> 3.2` and okcomputer `~> 1.20`, so apps on Rails 8.0 can no longer install appkit.
- The reusable `rails-ci.yml` workflow now uses `actions/checkout@v7`, `actions/cache@v6` and `actions/setup-node@v7`. Checkout v7 refuses to check out a fork's pull request under `pull_request_target` or `workflow_run`, so an app that calls `rails-ci.yml` from one of those triggers fails on fork pull requests.
- The reusable `rails-ci.yml` test job now runs `npm ci` when the calling app has a `package-lock.json`. Apps without that file are unaffected.
- The `appkit/shared/nav` partial now renders a rail of task hubs and a hub column for the current hub, from an `Appkit::Menu` map, with an account menu under the user's name. It no longer renders the app-name heading, the home link, the yielded list items or the Voorkeuren link. The `appkit.navigation.home` locale key is gone; `appkit.navigation.rail` and `appkit.navigation.hub_column` are new.

### Fixed
- `app_name` accepts a string or a callable, as the README shows, instead of crashing the sign-in page, first-run page, nav, login page title and PWA manifest with `NoMethodError`. A blank or unset name falls back to the host application module name, and a top-level `app_name` locale key gives a translated name per locale. The PWA manifest now follows the request locale. To do that, the manifest and the service worker now inherit the host's `ApplicationController`, so every host `before_action` runs on them, including a Rails 8 host's `allow_browser versions: :modern`. Both endpoints now send `Cache-Control: max-age=0, private, must-revalidate` instead of `no-cache`, so a CDN or proxy no longer caches them.
- The service worker cache name now changes with every appkit commit, also in hosts whose Docker build deletes the gem's `.git` directory.
- Following the README or running `bin/rails generate appkit:install` no longer leaves engine pages raising `NoMethodError` for `allow_unauthenticated_access`: the generator adds `include Appkit::Authentication` to `ApplicationController`.

### Upgrading
1. Upgrade the app to Rails 8.1 before you move its appkit pin to this SHA. Bundler does not resolve appkit next to Rails 8.0.
2. If the app calls `rails-ci.yml` from a `pull_request_target` or `workflow_run` trigger, move that call to `pull_request`. Otherwise checkout v7 fails on fork pull requests.
3. Check that no `before_action` in your `ApplicationController` redirects or blocks `GET /manifest` or `GET /service-worker`; both now inherit it.
4. If your `ApplicationController` does not include `Appkit::Authentication`, add `include Appkit::Authentication` to it by hand. Do not re-run `bin/rails generate appkit:install` for this: in an app that has a `sessions` table, it also creates an `align_sessions_for_appkit` migration.
5. Build an `Appkit::Menu` per request from your own map of hubs, pages and account links: `Appkit::Menu.new(hubs:, account:, controller_path: controller_path, params: request.parameters)`. Each `Appkit::Menu::Hub` takes a `landing:` hash (a controller path plus params) and its `pages:`; a hub may hold only one page per controller. Give a hub that the account menu links to, and not the rail, `rail: false`: it stays out of the rail, but still gets its hub column and highlighting. Expose the menu to views, for example with `helper_method :menu`.
6. Render the nav with `render layout: "appkit/shared/nav", locals: { menu: menu, user_name: Current.user.name } do … end`. The block renders at the top of the rail: put the search button there. Move the Voorkeuren link into the `account:` links as `Appkit::Menu::Link.new(label: t("appkit.navigation.preferences"), path: edit_preferences_path)`. The partial appends the logout button.
7. Stop relying on the old home link, the app-name heading and the yielded `<li>` items: the nav no longer renders them. Use the `appkit.navigation.home` key no more; it is removed.
8. Move `mvpa-css` in your `Gemfile` to a commit whose CHANGELOG names the rail and hub column. Before that, the new nav renders as plain lists.
