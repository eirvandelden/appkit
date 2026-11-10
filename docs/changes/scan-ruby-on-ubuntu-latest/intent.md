# Intent: Run scan_ruby on ubuntu-latest

Author: Etienne van Delden. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no.

## Problem

The `scan_ruby` job of the reusable workflow `.github/workflows/rails-ci.yml` runs on `ubuntu-slim`. On that runner `bin/brakeman` crashes with `OpenSSL is not available` while it checks rubygems.org for a newer Brakeman (`--ensure-latest`). The `lint` and `scan_js` jobs already moved to `ubuntu-latest` for the same OpenSSL reason (commit `35063fb`); `scan_ruby` was missed. The job is red on every pull request and on `main` of each app that calls this workflow. It is red on Clocky `main` after PR #174.

## Proposed outcome

`scan_ruby` runs on `ubuntu-latest`, like `lint` and `scan_js`. `bin/brakeman` and `bin/bundler-audit` reach their actual scans in the apps' CI.

## Affected users and systems

- `.github/workflows/rails-ci.yml` in this repository.
- Every app that calls the workflow through `@main`, Clocky included. Open pull requests there show a red `scan_ruby` until this lands.

## Constraints

- Approved permission: an edit of one file under `.github/workflows/` (playbook rule 13), the single `runs-on` line of the `scan_ruby` job. No gems, no migrations.
- Apps call the workflow at `@main`, so the merge changes their CI at once. Etienne approves the merge.
- Never read or print secrets.

## In scope

- Change `runs-on: ubuntu-slim` to `runs-on: ubuntu-latest` in the `scan_ruby` job.
- Remove `ubuntu-slim` from the comment convention only if the file no longer uses it. Otherwise leave the comments alone.
- Verify through the workflow run on the pull request.

## Out of scope

- Any other job, step, action version or input of the workflow.
- The Brakeman `--ensure-latest` flag in the apps' `bin/brakeman`.
- Fixing `ubuntu-slim` itself or the `rv` Ruby build.
- Changes in Clocky or in other apps.

## Acceptance criteria

- `scan_ruby` in `rails-ci.yml` declares `runs-on: ubuntu-latest`.
- The diff touches only that line.
- Clocky's `scan_ruby` check, run against this branch of the workflow, no longer fails with `OpenSSL is not available`.
- `actionlint` or the repository's workflow checks, where they exist, stay green.

## Decisions

- Go back to `ubuntu-latest` for `scan_ruby` — Etienne's words: "go back to using ubuntu".
- Autonomous delivery, no Codex review — chosen at the delivery question.
- Workflow edit approved — Etienne said "yes" to editing workflow files and "fine, go back to using ubuntu".

## Open questions

None.
