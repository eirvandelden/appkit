# Review: drop-obsolete-brakeman-ignore-entry

## Round 1 — 2026-10-26T12:49:17Z — 1ff7b69

No findings.

The repository has no `REVIEW.md` or `REVIEW.local.md`, so the reviewer's default passes apply.

- Bugs: the edit removes only the `7c4e5f37…` object and its comma. `config/brakeman.gem.ignore` parses as JSON, and the `94fb8f8e…` entry and its note are unchanged.
- Security: removing an ignore entry only widens what Brakeman reports. `Appkit::PwaController` keeps `skip_forgery_protection` and inherits `::ApplicationController` (`app/controllers/appkit/pwa_controller.rb:4`), so ForgerySetting does not fire on it.
- Compliance:
  - "No Obsolete Ignore Entries section and 0 security warnings": proved by `bundle exec brakeman -q --no-pager -i config/brakeman.gem.ignore` and by the CI form `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`. Both report "Security Warnings: 0" and "Ignored Warnings: 1", print no obsolete section, and exit 0.
  - "The `lib/appkit/version.rb` entry is still in the file": `grep -c 94fb8f8e… config/brakeman.gem.ignore` prints 1, and both scans report "Ignored Warnings: 1".
  - The JSON invariant: `ruby -rjson -e 'JSON.parse(File.read("config/brakeman.gem.ignore"))'` exits 0.
  - The plan names no tests, because the change is configuration. No existing test is weakened, skipped or deleted.
- Design: no Ruby code changes, so no signature, Law of Demeter or N+1 finding applies. The repository has no glossary.
- Other checks: the dummy-app scan (`config/brakeman.ignore`) reports 0 warnings. `bundle exec rubocop` finds no offenses in 97 files. `bin/rails test` passes: 168 runs, 0 failures, 0 errors, 0 skips.
