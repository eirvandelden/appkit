# Intent: Require mvpa-css at boot and fix login flashes placement

Author: Etienne van Delden. Status: accepted (2026-10-30). Type: feature.
Delivery: autonomous
Codex review: no

## Problem

Appkit's views and `login.css` need mvpa-css, but nothing checks that the host app has it. A host without the gem boots fine, and its login page renders unthemed with no hint why. mvpa-css also now treats `main` as a size container, so the login layout, which renders flashes inside `<main>`, has flashes that scroll with the content on Safari before 18.4.

## Proposed outcome

A host app without mvpa-css fails at boot with an error that names the missing `Gemfile` line. The login page renders its flashes outside `<main>`, as mvpa-css expects.

## Affected users and systems

- Host apps that install appkit: any app without `mvpa-css` in its `Gemfile` stops booting.
- Host apps that override the `login` layout: they must move their flashes outside `<main>` too.
- Appkit's own login layout, engine and tests (`lib/appkit/engine.rb`, `app/views/layouts/login.html.erb`).

## Constraints

- mvpa-css stays a co-gem. It is not added to `appkit.gemspec`, because a gemspec cannot declare a git source.
- No new dependency and no new `Appkit.config` option.
- The `CHANGELOG.md` entry gets an `### Upgrading` subsection, because the check requires a `Gemfile` line and the flashes move changes the login layout that apps may override.
- Presence check only. mvpa-css versions are `0.1.0.pre.git.<sha>`, so a minimum version means nothing.

## In scope

- A boot-time check in the engine that raises when `Mvpa::Css` is not loaded.
- The error names `gem "mvpa-css", github: "eirvandelden/mvpa.css"`.
- Moving the flashes partial in `app/views/layouts/login.html.erb` from inside `<main>` to a direct child of `<body>`.
- Tests for both, a `CHANGELOG.md` entry and the README wording.

## Out of scope

- Declaring mvpa-css in the gemspec or publishing it to RubyGems.
- Checking an mvpa-css version.
- Any opt-out for the check.
- Host apps' own layouts and stylesheets.
- Other mvpa-css changes (segmented control, count badge, nav-only header, pull-down menu): appkit uses none of them.

## Acceptance criteria

- Booting a host app without mvpa-css raises an error that says to add `gem "mvpa-css", github: "eirvandelden/mvpa.css"` to the `Gemfile`.
- Booting a host app with mvpa-css works as before.
- The login page has its `[data-mvpa-flashes]` section as a direct child of `<body>`, not inside `<main>`.
- A flash set before login still shows on the login page.
- The `CHANGELOG.md` `### Upgrading` steps tell an app to add the `Gemfile` line and to move flashes out of an overridden login layout.

## Decisions

- Include the login flashes fix in this change — user asked for it to be included, although it is independent of the boot check.
- The boot check always raises, with no opt-out — user chose it over an opt-out option or a warning.
- mvpa-css stays a co-gem, with an explicit boot-time contract — user chose this over publishing the gem.
- Deliver autonomously, without the Codex review — user chose it; the diff is small.

## Open questions

None.
