# Plan: Run lint and scan_js on ubuntu-latest

From `intent.md` (2026-11-06). Status: accepted.

This is the appkit part of the sticker-app plan `docs/changes/fix-rbs-inline-lint-and-steep-offenses/plan.md` (sticker-app commit `c5558a7`). That plan was accepted on 2026-11-07 after one Codex critique round, with all 3 findings fixed. This file copies the parts for this repository.

## Context

- sticker-app CI run 42282988312: `ci / lint` and `ci / scan_js` fail on `ubuntu-slim` with the `OPENSSL_3.4.0` LoadError. `ci / scan_ruby` on `ubuntu-slim` passes. `test` and `system-test` on `ubuntu-latest` pass.
- sticker-app's `.github/workflows/ci.yml` calls this workflow at `@main`, so a merge here takes effect on the next sticker-app run.

## Design decisions

- Move only `lint` and `scan_js` to `ubuntu-latest`, the runner where the same bundle already loads `openssl-4.0.2`. `scan_ruby` stays on `ubuntu-slim`, because it passes today and the intent puts it out of scope.

## Files that change

- `.github/workflows/rails-ci.yml` — `runs-on: ubuntu-latest` for `scan_js` and `lint`, each with a one-line comment that names the `OPENSSL_3.4.0` LoadError on `ubuntu-slim`.

## Proof

- Configuration, no test. The workflow YAML parses. On sticker-app's pull request, `ci / lint` and `ci / scan_js` pass → check: `gh pr checks` on that pull request, after this branch merges.
