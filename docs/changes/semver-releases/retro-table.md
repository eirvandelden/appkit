# Retro table

Status: draft

Baseline SHA: 42e22b3a3f3f2e9fec4026f829e498d84fe6f186

Edit the Level column (patch, minor or major), then set `Status: accepted`. The Version column is recomputed.

| # | Version | PR | Merge | Date | Title | Detected | Notes | Level |
|---|---|---|---|---|---|---|---|---|
| 0 | 0.1.0 | - | 21689fb | | Baseline: everything before the first merge | - | direct commits | patch |
| 1 | 0.1.1 | #1 | b62771f | 2026-07-19 | fix: correct i18n key for preferences update success flash | major | locale: removed en.appkit.preferences.edit.success, locale: removed it.appkit.preferences.edit.success, locale: removed nl.appkit.preferences.edit.success | patch |
| 2 | 1.0.0 | #2 | 0b97f94 | 2026-07-19 | fix: move auto_submit_controller into appkit/ namespace, pin it | major | importmap: added appkit/controllers/auto_submit_controller | major |
| 3 | 1.1.0 | #3 | 5ac97e9 | 2026-07-19 | feat: add session-expiry sweep job | patch |  | minor |
| 4 | 1.1.1 | #4 | e6ca904 | 2026-07-19 | fix: login layout never loaded JavaScript at all | major | gemspec: added importmap-rails | patch |
| 5 | 1.1.2 | #5 | 822925b | 2026-07-20 | fix: default --color-accent to magenta | patch |  | patch |
| 6 | 1.2.0 | #10 | 8431fc0 | 2026-09-04 | Bump mvpa-css to latest main | patch | direct commits: 723c085 feat(ui): login layout declares theme and colour-scheme; add shared partials; ca7da16 security: update rails, json, and sqlite3 to patched versions; e131f65 fix: favicon link now follows configured icons, not a hardcoded path; df199d6 chore: update Ruby dependencies to latest versions; 07185d3 chore: refresh lockfile self-reference after dependency bump; c12ca27 chore: refresh lockfile self-reference after review test run; 0c6142b chore: refresh lockfile self-reference after review test run; 0fab18a feat: redirect authenticated users away from the login page; 2811892 feat(ui): add shared nav partial with home link, preferences, and logout; ae7e85b chore: refresh lockfile self-reference after review test run; cb8c1e9 fix(test): use html format in dummy controllers so the application layout renders; 4a57986 chore: refresh lockfile self-reference after PR test run; 15471d9 feat(ui): allow apps to inject nav links between home and preferences; 67d0cc8 chore: refresh lockfile self-reference after PR test run; 7541038 fix(ui): remove dead nav Stimulus controller reference; ff30547 chore: refresh lockfile self-reference after fix commit; 02fa603 fix(i18n): namespace nav translations under appkit; 839e8cb refactor(ui): drop the home_path local, nav links straight to root; 79947bd chore: refresh lockfile self-reference after review test run; 1fdce8a update mvpa; b8a2816 feat: recognize known e-ink devices and force the e-ink theme; 7c18532 feat: recognize the BigMe HiBreak Pro as an e-ink device; 296596f chore: refresh lockfile self-reference after merge; 9186e9d chore: refresh lockfile after Ruby 4 validation; ed6f302 chore: refresh lockfile self-reference after rebase onto main | minor |
| 7 | 1.2.1 | #11 | 2dbb638 | 2026-09-04 | Inherit the shared rubocop rules | patch |  | patch |
| 8 | 1.2.2 | #12 | fa8eead | 2026-09-30 | Bump Rails to 8.1.4 | patch |  | patch |
| 9 | 1.2.3 | #13 | fd86991 | 2026-10-05 | Remove the cspell spell checker | patch |  | patch |
| 10 | 1.2.4 | #15 | 0bc4f57 | 2026-10-13 | app_name accepts a string, a callable or a translation | patch |  | patch |
| 11 | 1.2.5 | #14 | 4415186 | 2026-10-13 | appkit gets an AGENTS.md with upgrade instructions | patch |  | patch |
| 12 | 2.0.0 | #16 | 1cc1433 | 2026-10-13 | Update all dependencies to their latest stable versions | major | changelog has Upgrading / gemspec: changed railties, gemspec: changed web-push, gemspec: changed turbo-rails | major |
| 13 | 3.0.0 | #18 | d837929 | 2026-10-16 | appkit follow-up nits from readme-app-name-callable | patch | changelog has Upgrading | major |
| 14 | 3.0.1 | #19 | e47907f | 2026-10-16 | Add a Dependabot config | patch |  | patch |
| 15 | 3.0.2 | #21 | 9e7fa41 | 2026-10-19 | Replace yarn with npm in personal projects | patch |  | patch |
| 16 | 3.0.3 | #22 | d82b9c7 | 2026-10-20 | Finish the untracked-lockfile follow-ups in CI and lefthook | patch |  | patch |
| 17 | 3.1.0 | #23 | 9b5b30d | 2026-10-20 | Publish appkit's type signatures | major | config: added brand_color | minor |
| 18 | 3.1.1 | #25 | 4c82e2e | 2026-10-26 | Drop the obsolete Brakeman ignore entry | patch |  | patch |
| 19 | 4.0.0 | #26 | 2314e30 | 2026-11-03 | Require mvpa-css at boot and fix login flashes placement | minor | changelog has Upgrading / rbs: added Appkit, rbs: added Appkit::MissingCoGem, rbs: added Appkit::CoGem | major |
| 20 | 4.0.1 | #27 | de56db4 | 2026-11-06 | Upgrade RuboCop and Ruby so CI lint goes green | patch |  | patch |
| 21 | 5.0.0 | #24 | d106f6b | 2026-11-06 | Navigate by task hubs | major | changelog has Upgrading / locale: removed en.appkit.navigation.home, locale: removed it.appkit.navigation.home, locale: removed nl.appkit.navigation.home | major |
| 22 | 5.0.1 | #28 | 839ca4a | 2026-11-07 | Run lint and scan_js on ubuntu-latest | patch |  | patch |
| 23 | 5.0.2 | #31 | 709fcac | 2026-11-10 | Run scan_ruby on ubuntu-latest | patch |  | patch |
| 24 | 6.0.0 | #32 | 42e22b3 | 2026-11-13 | Hubs under a parent hub, sign-out as a hub page, and a list origin | major | changelog has Upgrading / rbs: removed Appkit::Menu#account, rbs: changed Appkit::Menu#initialize, rbs: changed Appkit::Appkit::Menu::Hub#initialize | major |

## Where the Level column differs from Detected

- #1: patch. The removed locale key is an internal rename inside a fix.
- #3: minor. A new opt-in job that apps schedule.
- #4: patch. The detected major is the new `importmap-rails` runtime dependency, which installs with the gem and needs no app step. Etienne may prefer minor.
- #10 (row 6): minor. The direct commits before it add shared partials and a login layout feature.
- #23 (row 17): minor. Published signatures are opt-in. The detected major is `brand_color`, an option that defaults to nil.
- #26 (row 19) and #18 (row 13): major. Their changelog text has `### Upgrading` steps. Row 19 breaks boot without the `mvpa-css` line.

## Known limits

- Changelog text goes to the PR that last touched each line (`git blame --first-parent` on `origin/main`). #18 rewrote the Task 0-3 lines and the manifest and service worker upgrade steps of #15, so they land in 3.0.0 (row 13, #18). Move them in `retro.rb` if you disagree.
- Row 0 holds every commit before the first merge. Its tag points at the commit before merge #1.
- A PR with no changelog text gets its title as a `### Changed` line.

