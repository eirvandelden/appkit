# Plan: Drop the obsolete Brakeman ignore entry

From `intent.md` (2026-10-22). Status: accepted.

## Design

### Domain terms

- **Ignore entry**: one fingerprint and note in a Brakeman ignore file.
- **Obsolete ignore entry**: an ignore entry that matches no current warning. Brakeman 8.1.0 lists these under "== Obsolete Ignore Entries ==".
- The repository has no `GLOSSARY.md`, so no avoided word applies. These terms are Brakeman's own; the plan adds none to a glossary.

### Diagrams

Not affected: the change touches no object, message or table. It edits one JSON data file.

### Signatures

Not affected: no Ruby class or method changes, so no `#:` comment changes and `sig/` stays the same.

Checked by: steep check

### Complexity

Not affected: the change adds no runtime path and no query. `config/brakeman.gem.ignore` is read only by the gem-root Brakeman scan.

### Invariants

- The `94fb8f8e7d54276bab652be99422a0a7ac352fd836e68952d7667382d7bd6e42` entry (`lib/appkit/version.rb`, `__dir__`) stays, with its note unchanged. Enforced by the CI gem-root scan (`.github/workflows/ci.yml:56`): without the entry, it reports a security warning and fails.
- `config/brakeman.gem.ignore` stays valid JSON, with no trailing comma after the last array element. Enforced by Brakeman, which fails to parse an invalid ignore file.

### Alternatives

1. **Delete the one entry, leave everything else (chosen).** The diff is one removed JSON object and its separating comma. It does exactly what `intent.md` scopes.
2. **Delete the entry and add an obsolete-entry guard.** Brakeman 8.1.0 has `--ensure-no-obsolete-ignore-entries` (`lib/brakeman/options.rb:78` in the installed gem). It also loads `<app_path>/config/brakeman.yml` automatically, so a new `config/brakeman.yml` with `ensure_no_obsolete_ignore_entries: true` would make the CI gem-root scan exit 9 on a future obsolete entry, without a `ci.yml` edit. Rejected for this change: it adds a file that `intent.md` puts out of scope ("In scope" lists only the removal), and `config/**` ships in the gem. It is a follow-up proposal for a separate change.
3. **Regenerate the file with Brakeman's interactive mode (`-I`).** Rejected: it rewrites the whole file, including the `updated` and `brakeman_version` metadata, and needs a terminal.

## Design decisions

- Leave the `updated` (`2026-07-18 00:00:00 +0000`) and `brakeman_version` (`8.0.5`) keys unchanged. Brakeman does not read them when it matches warnings. Changing them adds lines that `intent.md` does not ask for.
- No `CHANGELOG.md` entry. `config/brakeman.gem.ignore` is used only for appkit's own gem-root scan. No app acts on it, and it is none of the cases in CLAUDE.md "Upgrade instructions". The existing `## Unreleased` entries record app-facing changes only.
- No conflict with `intent.md` `## Decisions` (autonomous delivery, no Codex review).

## Integration points

- `.github/workflows/ci.yml:56`: `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`. Unchanged; it reads the edited file.
- `lefthook-local.yml` skips the Brakeman pre-push hook, so no local hook reads the file.
- `config/brakeman.ignore` (dummy-app scan) is a different file and does not change.

## Context

`Appkit::PwaController` now inherits the host's `::ApplicationController` (`app/controllers/appkit/pwa_controller.rb:4`). Brakeman's ForgerySetting check therefore no longer fires on it, so fingerprint `7c4e5f37091e56e253ac126f319524494620c4c4806e1461b831daf35ac64eb4` matches nothing. Before the change, both of these commands print "== Obsolete Ignore Entries ==" with that fingerprint, "Security Warnings: 0" and "Ignored Warnings: 1":

- `bundle exec brakeman -q --no-pager -i config/brakeman.gem.ignore`
- `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`

## Files that change

- `config/brakeman.gem.ignore` — remove the `ignored_warnings` object whose fingerprint is `7c4e5f37091e56e253ac126f319524494620c4c4806e1461b831daf35ac64eb4` (its `fingerprint` and `note` keys) and the comma after it. The `94fb8f8e…` object becomes the only array element. Nothing else in the file changes.

## Order of work

1. Edit `config/brakeman.gem.ignore` as "Files that change" says. This is configuration, so no test comes first.
2. Run `ruby -rjson -e 'JSON.parse(File.read("config/brakeman.gem.ignore"))'`. Expect exit 0.
3. Run `bundle exec brakeman -q --no-pager -i config/brakeman.gem.ignore`. Expect "Security Warnings: 0", "Ignored Warnings: 1" and no "Obsolete Ignore Entries" section.
4. Run the CI form, `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore`. Expect the same output and exit 0.
5. Run the dummy-app scan, `bundle exec brakeman -p test/dummy --no-pager --ignore-config config/brakeman.ignore`, to confirm nothing else moved. Expect exit 0.
6. Re-read `git diff`: only the removed object and its comma. Commit as one change.

## Risks

- A trailing comma left behind makes the file invalid JSON and fails the scan. Step 2 catches it.
- Deleting the wrong object un-ignores the `lib/appkit/version.rb` warning. Steps 3 and 4 catch it: "Security Warnings" would be 1.
- If a later change makes `PwaController` trip ForgerySetting again, CI reports it as a new warning. That is the wanted behaviour: it gets a fresh review instead of a stale ignore.
- Rejected: the obsolete-entry guard (Alternative 2) and metadata updates (Design decisions).

## Out of scope

- The `lib/appkit/version.rb` ignore entry.
- `config/brakeman.ignore` (dummy app).
- The engine controller signatures and the `Style/RbsInline` cop.
- Any controller superclass or `skip_forgery_protection` call.
- A `config/brakeman.yml` obsolete-entry guard or any `.github/workflows/` change.
- `CHANGELOG.md`.

## Proof

- Running `bundle exec brakeman -q --no-pager -i config/brakeman.gem.ignore` prints no "Obsolete Ignore Entries" section and reports 0 security warnings → check: run that command and read the output; also run the CI form `bundle exec brakeman -p . --force-scan --no-pager --ignore-config config/brakeman.gem.ignore` and expect the same and exit 0.
- The `lib/appkit/version.rb` entry is still in the file, so its warning stays ignored → check: `grep -c 94fb8f8e7d54276bab652be99422a0a7ac352fd836e68952d7667382d7bd6e42 config/brakeman.gem.ignore` prints 1, and the scan above reports "Ignored Warnings: 1".
- Invariant: the ignore file is valid JSON, enforced by Brakeman's parser → check: `ruby -rjson -e 'JSON.parse(File.read("config/brakeman.gem.ignore"))'` exits 0.

Per changed file, the unit tests expected:
- `config/brakeman.gem.ignore`: none; configuration has no tests.

Test setup: none. The existing suite (`bin/rails test`) and RuboCop do not read this file; run them once only if a step touches anything else.

---
Domain skills applied: brakeman, software-design, glossary, diagrams.

## Critique

### Round 1 (codex exec -p terra)

No findings.
