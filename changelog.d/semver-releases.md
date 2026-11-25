---
level: major
---
### Added
- Semantic versions with automatic releases. Each merge to `main` gets a git tag `X.Y.Z` (no `v` prefix) and a GitHub Release, and a moving major tag such as `3` follows the newest release of that major. A PR declares its level in `changelog.d/<branch-slug>.md`, and a CI check fails a PR whose diff touches the public surface with a level below the detected floor.
- `CHANGELOG.md` has one section per version. The history gets retro versions from `0.1.0`.

### Changed
- `Appkit::VERSION` is the plain released version, such as `3.1.0`. It no longer ends in `.pre.git.<sha>`, and `Appkit::BASE_VERSION` is gone. `Appkit::Revision` and the service worker cache name still follow the commit when a host uses a git source.
- `bin/rails generate appkit:install` writes a CI caller that calls `rails-ci.yml` at the major tag of the installed appkit, not at `@main`.

### Upgrading
1. Pin a release in your `Gemfile`: `gem "appkit", github: "eirvandelden/appkit", tag: "X.Y.Z"`. Take the version from the newest GitHub Release. A pin on a git SHA still works.
2. Run `bundle update appkit`.
3. Change the `uses:` line of `.github/workflows/ci.yml` to `eirvandelden/appkit/.github/workflows/rails-ci.yml@<major>`, where `<major>` is the major number of the release you pinned, such as `3`.
4. Replace any code that reads `Appkit::BASE_VERSION` with `Appkit::VERSION`.
