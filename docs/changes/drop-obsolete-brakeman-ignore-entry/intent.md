# Intent: Drop the obsolete Brakeman ignore entry

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no.

## Problem

`config/brakeman.gem.ignore` holds an entry, fingerprint `7c4e5f37…`, for a forgery-protection warning on `Appkit::PwaController`. Brakeman no longer raises that warning, so `brakeman -i config/brakeman.gem.ignore` prints an "Obsolete Ignore Entries" section. A stale ignore entry could hide a real warning with the same fingerprint later.

## Proposed outcome

The ignore file lists only the warnings Brakeman still raises. The "Obsolete Ignore Entries" section is gone from the Brakeman output.

## Affected users and systems

Appkit maintainers and the Brakeman run in CI and in the pre-push check. No host app is affected.

## Constraints

No new dependency, system tool, migration or deploy file.

## In scope

- Remove the obsolete entry from `config/brakeman.gem.ignore`.

## Out of scope

- The other ignore entry (`lib/appkit/version.rb`, `__dir__`), which Brakeman still matches.
- The engine controller signatures and the `Style/RbsInline` cop.
- Changing any controller's superclass or its `skip_forgery_protection` call.

## Acceptance criteria

- Running `bundle exec brakeman -q --no-pager -i config/brakeman.gem.ignore` prints no "Obsolete Ignore Entries" section and reports 0 security warnings.
- The `lib/appkit/version.rb` entry is still in the file, so its warning stays ignored.

## Decisions

- Autonomous delivery, no Codex review — chosen by Etienne when asked.

## Open questions

None.
