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

### Fixed
- `app_name` accepts a string or a callable, as the README shows, instead of crashing the sign-in page, first-run page, nav, login page title and PWA manifest with `NoMethodError`. A blank or unset name falls back to the host application module name, and a top-level `app_name` locale key gives a translated name per locale. The PWA manifest now follows the request locale.
