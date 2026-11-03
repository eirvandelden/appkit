# Review: require-mvpa-css-at-boot

## Round 1 — 2026-11-03T10:55:40Z — 397347c

No findings.

The repository has no `REVIEW.md` or `REVIEW.local.md`, so the default Bugs, Security, Compliance and Design passes ran.

Checks run: `bin/rails test` (174 runs, 0 failures), `bundle exec erb_lint --lint-all`, `bundle exec rake rbs:check`, `bundle exec rake steep`, both Brakeman scans and `bin/bundler-audit check` are green. `bundle exec rubocop` did not run: the local `Gemfile.lock` resolves RuboCop 1.74.0, which rejects `TargetRubyVersion: 4.0`. That is a stale local lockfile, not a change on this branch; CI resolves fresh gems.

Compliance:
- Boot without mvpa-css raises with the Gemfile line → `test/integration/mvpa_css_boot_test.rb` "booting without mvpa-css in the bundle raises with the Gemfile line".
- Boot with mvpa-css works as before → `test/integration/mvpa_css_boot_test.rb` "booting loads the mvpa-css engine before initialize", plus the full suite.
- Flashes are a direct child of `<body>`, not inside `<main>` → `test/controllers/appkit/sessions_controller_test.rb` "the login page renders flashes outside main".
- A flash set before login still shows → the same test (`render_rejection` renders the login layout with the alert).
- `### Upgrading` steps → `CHANGELOG.md` steps 5 and 6 hold the Gemfile line and the flashes move.
- Every test named in `plan.md` `## Proof` exists. No existing test was weakened, skipped or deleted.

Design: `CoGem#initialize` and `CoGem#ensure_loaded` match `### Signatures` and carry inline RBS. No Law of Demeter chain, no query, no `GLOSSARY.md` in the repository; the plan's `Avoid:` terms do not appear in code or tests. mvpa-css styles `[data-mvpa-flashes]` as `position: fixed`, so the move out of the flex `main` does not change the login layout.
