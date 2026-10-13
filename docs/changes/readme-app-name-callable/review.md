# Review: readme-app-name-callable

## Round 1 — 2026-10-13T08:14Z — ea94de5

No `REVIEW.md` or `REVIEW.local.md` at the repository root; the default Bugs, Security and Compliance passes apply. Diff: `origin/main...ea94de5`, no uncommitted changes.

Checks: `bundle exec rake test` 122 runs, 0 failures, 0 errors, 0 skips. `bundle exec rubocop` 85 files, no offenses. `bundle exec bundle-audit check` no vulnerabilities. `bundle exec brakeman` reports one Medium command-injection warning in `lib/appkit/version.rb:3`, a file this branch does not touch. `bin/rails test` crashes in Minitest's option parser before any test runs; `rake test` is the working entry point.

Bugs: no Important findings. `fallback: false` is a real option in i18n 1.15.2 (`I18n::Backend::Fallbacks#translate` returns `super` when it is false), and the fallbacks unit test fails without it. `I18n.t(:app_name, default: nil)` returns `nil` instead of throwing `MissingTranslation`. `PwaController` keeps `skip_forgery_protection`, so the service worker's same-origin check stays off. Both PWA actions keep `layout: false`, so the host layout cannot wrap them.

Security: no findings. The name renders through `<%= %>` escaping in the HTML views. In the manifest it goes through `to_json`. Translations come from the host's own locale files.

Compliance, acceptance criteria against tests:

- String `app_name` on sign-in page, first-run page, nav, page title and manifest → `test/integration/app_name_test.rb` "a string app_name shows on the sign-in page, first-run page, nav, page title and manifest".
- Callable `app_name` on the same pages → `test/integration/app_name_test.rb` "a callable app_name shows on every page that names the app".
- Unset `app_name` shows the module name → `test/models/appkit/app_name_test.rb` "falls back to the host module name split into words when nothing is configured" and `test/integration/app_name_test.rb` "an unset app_name shows the host module name on every page".
- `app_name = ""` shows the module name → `test/models/appkit/app_name_test.rb` "treats an empty string as unset" and `test/integration/app_name_test.rb` "an empty app_name shows the host module name on every page".
- `app_name = -> { nil }` shows the module name → `test/models/appkit/app_name_test.rb` "treats a callable returning nil as unset" and `test/integration/app_name_test.rb` "a callable returning nil shows the host module name on every page".
- Dutch visitor sees "Receptenboek", English visitor "Recipe Book" → `test/integration/app_name_test.rb` "a Dutch visitor sees the nl app_name translation and an English visitor the configured name".
- Dutch manifest name is "Receptenboek" → `test/controllers/appkit/pwa_controller_test.rb` "manifest name uses the app_name translation for the request locale".
- README `app_name` row → `README.md:108` names a string or a callable, the top-level `app_name` locale key, the resolution order, the module-name default and the five places. Met.

Every test that `plan.md`'s Proof names exists, except one renamed test (Nit below). No existing test was weakened, skipped or deleted. The dummy initializer moved from a callable to a string; the callable path keeps its integration and configuration tests.

- [ ] Nit: The configuration test is named "app_name keeps returning a callable unchanged"; `plan.md`'s Proof names it "keeps the raw app_name reader unchanged for a callable". The behaviour is the same, but a reader who greps the Proof name finds nothing. — `test/appkit/configuration_test.rb:16` → fixed (test: name the raw app_name reader test after the plan's Proof)
- [ ] Nit: `AppName#to_s` returns whatever the configured value or callable gives when it is present. A callable that returns a Symbol or an Integer makes `to_s` return a non-String, which breaks the `to_s` contract that string interpolation relies on. `configured_name` can coerce with `.to_s` before `.presence`. — `app/models/appkit/app_name.rb:25` → fixed (fix: return a string app name when a callable gives a non-string)
- [ ] Nit: `assert_name_on_every_page` takes a `locale:` keyword that no caller passes, because the Dutch test uses the narrower helpers directly. Drop the keyword and pass `"en"` straight through. — `test/integration/app_name_test.rb:54` → fixed (test: drop the unused locale keyword from assert_name_on_every_page)

## Round 2 — 2026-10-13T08:20Z — ea94de5 (codex)

`codex review --base origin/main`. Codex ran the focused model, integration and PWA tests: all green.

No findings.

## Round 3 — 2026-10-13T08:20Z — 7e0a343

No `REVIEW.md` or `REVIEW.local.md` at the repository root; the default Bugs, Security and Compliance passes apply. Diff: `origin/main...7e0a343`, no uncommitted changes. This round re-reads the whole diff and the three round 1 fixes.

Checks: `bundle exec rake test` 123 runs, 0 failures, 0 errors, 0 skips. `bundle exec rubocop` 85 files, no offenses. `bundle exec bundle-audit check` no vulnerabilities. `bundle exec brakeman` reports the same Medium warning in `lib/appkit/version.rb`, a file this branch does not touch. The fallbacks unit test also passes when it runs alone, so it does not depend on test order.

Bugs: no Important findings. The round 1 fixes hold: the Proof test name now matches, `assert_name_on_every_page` has no unused keyword, and a Symbol from a callable now gives a String.

Security: no findings. The HTML views escape the name with `<%= %>`. The manifest escapes it with `to_json`.

Compliance: every acceptance criterion maps to the same tests as in round 1. Every test that `plan.md`'s Proof names exists, including the renamed configuration test. No existing test was weakened, skipped or deleted.

- [ ] Nit: The round 1 coercion fix calls `to_s` before `presence`, so `false` is no longer blank. A callable that returns `false`, or `config.app_name = false`, now shows "false" instead of the module name. Before ba45875 it fell back. The intent counts a blank configured name as unset, and `false` is blank in Rails. `name.presence&.to_s` keeps the Symbol fix and the fallback for `false`. — `app/models/appkit/app_name.rb:25` → fixed (fix: fall back to the module name when a callable returns false)

## Round 4 — 2026-10-13T08:24Z — 7e0a343 (codex)

`codex review --base origin/main`. Codex ran the full suite: 123 runs, 378 assertions, 0 failures, 0 errors.

No findings.

## Round 5 — 2026-10-13T08:25Z — bd84daf

No `REVIEW.md` or `REVIEW.local.md` at the repository root; the default Bugs, Security and Compliance passes apply. Diff: `origin/main...bd84daf`, no uncommitted changes. This round re-reads the whole diff and the round 3 fix.

Checks: `bundle exec rake test` 124 runs, 379 assertions, 0 failures, 0 errors, 0 skips. `bundle exec rubocop` 85 files, no offenses. `bundle exec bundle-audit check` no vulnerabilities. `bundle exec brakeman` reports the same Medium warning in `lib/appkit/version.rb`, a file this branch does not touch.

Bugs: the round 3 fix holds. `name.presence&.to_s` makes `false` fall back to the module name and still turns a Symbol into a String; "treats a callable returning false as unset" covers it.

Security: one Important finding below. A scratch integration test (not committed) fetched the PWA endpoints as a signed-in user. Signed out, the manifest has `Cache-Control: no-cache` and no `Set-Cookie`. Signed in, both the manifest and the service worker now return `Cache-Control: no-cache` and a `Set-Cookie: session_token=…` header. A normal page returns `max-age=0, private, must-revalidate`.

Compliance: every acceptance criterion maps to the same tests as in rounds 1 and 3. Every test that `plan.md`'s Proof names exists. No existing test was weakened, skipped or deleted.

- [ ] Important: `PwaController` now runs `allow_unauthenticated_access`, so `restore_authentication` re-issues the signed `session_token` cookie on every manifest and service-worker fetch by a signed-in user. The controller replaces Rails' default `private` cache directive with a bare `no-cache`, so a shared cache (CDN or proxy) may store the response with its `Set-Cookie`. The manifest ETag is the same for every user in one locale. A revalidation then gets a 304, and the cache can serve the stored `session_token` cookie to the next visitor, who becomes signed in as the first user. On `main` these endpoints never set a cookie. The plan's Risks list the session activity update and the missing `Vary`, but not the cookie in a publicly cacheable response. Mark both responses `private`, or keep the host locale without restoring the session cookie. — `app/controllers/appkit/pwa_controller.rb:3` → fixed (fix: keep PWA responses that carry a session cookie out of shared caches)
- [ ] Nit: The fallback calls `host_module_name.titleize`. A host whose application class is not inside a module gets `nil` from `module_parent_name`, and then every page that names the app raises `NoMethodError`. Rails generators always nest the class in a module, so this is rare. `host_module_name.to_s.titleize` would give a blank name instead of a crash. — `app/models/appkit/app_name.rb:12` → fixed (fix: show a blank app name instead of raising when the host has no module)

## Round 6 — 2026-10-13T08:27Z — bd84daf (codex)

`codex review --base origin/main`. Codex ran the full suite: 124 runs, 379 assertions, 0 failures, 0 errors. This round predates the round 5 fixes.

No findings.

## Round 7 — 2026-10-13T08:37Z — a565e3b

No `REVIEW.md` or `REVIEW.local.md` at the repository root; the default Bugs, Security and Compliance passes apply. Diff: `origin/main...a565e3b`, no uncommitted changes. This round re-reads the whole diff and the two round 5 fixes.

Checks: `bundle exec rake test` 126 runs, 386 assertions, 0 failures, 0 errors, 0 skips. `bundle exec rubocop` 85 files, no offenses. `bundle exec bundle-audit check` no vulnerabilities. `bundle exec brakeman` reports the same Medium warning in `lib/appkit/version.rb`, a file this branch does not touch. Running `bundle exec` rewrites the `appkit` version in `Gemfile.lock` to the current SHA; that is existing behaviour of `lib/appkit/version.rb`, and this round restored the file.

Bugs: no Important findings. The round 5 fixes hold. `expires_in 0, must_revalidate: true` gives `max-age=0, private, must-revalidate` on the manifest and the service worker, signed in or signed out. That is the same revalidation as the old `no-cache` for a browser. "PWA responses that carry a session cookie stay private, out of shared caches" signs in, asserts the `session_token` cookie is present, and asserts `private` on both endpoints. `host_module_name.to_s.titleize` gives `""` for a `nil` module, and "shows a blank name instead of raising when the host application has no module" covers it.

Security: no findings. A shared cache must not store a `private` response, so the re-issued `session_token` cookie cannot reach another visitor. `private` also makes the plan's accepted risk moot: a shared cache can no longer serve one locale's manifest to another. The HTML views escape the name with `<%= %>`. The manifest escapes it with `to_json`.

Compliance: every acceptance criterion maps to the same tests as in rounds 1, 3 and 5. Every test that `plan.md`'s Proof names exists. Two existing assertions in `test/controllers/appkit/pwa_controller_test.rb` changed from `no-cache` to `max-age=0, private, must-revalidate`. They still assert one exact header value, so they are not weaker, and the round 5 Important fix needs the change. No existing test was skipped or deleted.

- [ ] Nit: The CHANGELOG entry says only that the manifest follows the request locale. Two other changes affect host apps on upgrade. First, the manifest and the service worker now inherit the host's `::ApplicationController`, so every host `before_action` runs on them; a Rails 8 host's generated `allow_browser versions: :modern` now applies to them too. Second, both endpoints now send `Cache-Control: max-age=0, private, must-revalidate` instead of `no-cache`, so a CDN no longer caches them. One sentence per change in the `### Fixed` entry tells the host what to check. — `CHANGELOG.md:22` →
