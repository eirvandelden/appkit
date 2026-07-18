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
