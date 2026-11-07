# Intent: Run lint and scan_js on ubuntu-latest

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-06). Type: chore. Delivery: autonomous. Codex review: no.

This is the appkit part of the sticker-app change `fix-rbs-inline-lint-and-steep-offenses`. Etienne accepted that intent on 2026-11-06. It covers this repository, `rubocop-eirvandelden` and sticker-app. This file restates the part for this repository.

## Problem

Since the Ruby and gem update, the `lint` and `scan_js` jobs of the shared `.github/workflows/rails-ci.yml` fail at boot in every app that uses this workflow, before RuboCop or importmap runs. The error is `libcrypto.so.3: version OPENSSL_3.4.0 not found (required by .../openssl-4.0.2/lib/openssl.so) (LoadError)`. sticker-app CI run 42282988312 and sticker-app issue #198 show it. Both jobs run on `ubuntu-slim`. The jobs on `ubuntu-latest` (`test`, `system-test`) load the same bundle and pass.

## Proposed outcome

`lint` and `scan_js` boot and run their tools in every app that calls this workflow.

## Affected users and systems

Every app that calls appkit's `rails-ci.yml` at `@main`. sticker-app checks it first.

## Constraints

- Etienne approved the edit to `.github/workflows/rails-ci.yml` (playbook rule 13).

## In scope

- The `lint` and `scan_js` jobs of `rails-ci.yml`.

## Out of scope

- `scan_ruby`, which passes on `ubuntu-slim` today.
- The root cause of the openssl mismatch (a bundle built against OpenSSL 3.4).

## Acceptance criteria

- On sticker-app's pull request, `ci / lint` and `ci / scan_js` pass instead of stopping with the openssl LoadError.

## Decisions

- Bundle the openssl CI failure into the sticker-app lint change — one change turns lint green; neither fix alone does.

## Open questions

None.
