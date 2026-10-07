# Changelog

**Note:** This project uses git SHAs instead of semver. Pin to a specific SHA in your Gemfile.

## Unreleased

### Added
- Engine skeleton and dummy-app test harness (Task 0). No auth/PWA/theme features yet.
- Session-based authentication: login/logout, session cookie, configurable
  `email_attribute`/`user_scope` (Task 1).
- FirstRun bootstrap, session transfer + QR magic-link handoff,
  `VersionHeaders`, `Authorization`, static error pages via the install
  generator, and `Authenticatable#deactivate!` (Task 1b). Portions adapted
  from Basecamp's Writebook (MIT) — see `THIRD_PARTY_NOTICES.md`.
- Theme/preferences: `UserTheming` concern (`color_scheme`/`light_theme`/
  `dark_theme` enums), `ThemeHelper`, Stimulus `theme_controller.js`,
  `PreferencesController`/view with an optional `config.timezone_attribute`
  gate, a reusable `_flashes` partial, and `en`/`nl`/`it` locale files
  covering sessions/first_run/preferences (Task 3).

### Changed
- appkit now requires Rails 8.1: the gemspec floors are railties `~> 8.1`, turbo-rails `~> 2.0`, importmap-rails `~> 2.2`, web-push `~> 3.1`, rqrcode `~> 3.2` and okcomputer `~> 1.20`, so apps on Rails 8.0 can no longer install appkit.

### Fixed
- `app_name` accepts a string or a callable, as the README shows, instead of crashing the sign-in page, first-run page, nav, login page title and PWA manifest with `NoMethodError`. A blank or unset name falls back to the host application module name, and a top-level `app_name` locale key gives a translated name per locale. The PWA manifest now follows the request locale. To do that, the manifest and the service worker now inherit the host's `ApplicationController`, so every host `before_action` runs on them, including a Rails 8 host's `allow_browser versions: :modern`; check that none of them redirects or blocks these two endpoints. Both endpoints now send `Cache-Control: max-age=0, private, must-revalidate` instead of `no-cache`, so a CDN or proxy no longer caches them.
