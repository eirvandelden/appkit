# Intent: Publish appkit's type signatures

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-20). Type: feature. Delivery: autonomous.

## Problem

appkit ships no type signatures, and the RBS collection has no entry for it. A host app that type-checks with Steep cannot resolve appkit's modules and classes, such as `Appkit::Authentication` and `Appkit::QrCodeLink`. sticker-app works around this today: it declares each appkit constant as `untyped` with `# @type const` comments, and before that it kept a hand-written stub, `sig/stubs/appkit.rbs`. Each host app has to repeat that workaround, and a hand-written stub drifts from appkit's real methods. A consumer loads a gem's types only from `sig/` inside the gem; it does not read inline comments in the gem's source (RBS 4.2 `docs/gem.md`). Host apps install appkit from GitHub, so Bundler installs only what git holds. appkit also has no check that its own code matches any type.

## Proposed outcome

appkit's Ruby source carries inline `#:` signatures as the single source of its types. A committed `sig/` directory, generated from those comments with `rbs-inline`, ships with the gem. A host app that type-checks with Steep resolves appkit's constants and methods from that `sig/`, without a stub or a `@type const` workaround. appkit type-checks its own code with Steep. CI fails when the committed `sig/` differs from what the inline comments generate, and when Steep finds a type error. Lefthook catches both before the change leaves the maintainer's machine.

## Affected users and systems

- appkit maintainers: they write `#:` comments, and the hooks regenerate and check `sig/`.
- Host apps that type-check with Steep, first sticker-app (PR #180).
- appkit's CI (`.github/workflows/ci.yml`) and its lefthook configuration (`lefthook.yml`).
- Host apps that do not type-check: no change.

## Constraints

- The inline `#:` comments are the source. The `.rbs` files in `sig/` are generated and never edited by hand (option A, decided 2026-10-17).
- `sig/manifest.yaml` is the exception: it is hand-written, so regeneration deletes only `sig/**/*.rbs`, never the whole `sig/` directory.
- `rbs-inline` 0.14 generates nothing without `--opt-out`; otherwise it reads only files marked `# rbs_inline: enabled` (dotfiles PR #217).
- Follow the CI recipe in `new-repo-setup` step 12, with `app` added next to `lib`: `find sig -name '*.rbs' -delete && bundle exec rbs-inline --opt-out --output=sig app lib`, then `git add --intent-to-add sig/` and `git diff --exit-code sig/`.
- The global git ignore file ignores `sig/` (dotfiles change, separate intent). appkit's own `.gitignore` re-includes it with `!sig/`, so `sig/` stays tracked on any machine.
- appkit pins by git SHA, not semver. No version bump.
- Steep runs at its default diagnostics level. A gap Steep cannot type, such as the host-owned `User`, `Session` and `Current`, or Rails metaprogramming, is marked inline at the spot, not hidden by a lower level.
- `.github/workflows/rails-ci.yml`, the workflow that apps call at `@main`, stays unchanged.
- The `CHANGELOG.md` entry follows the `AGENTS.md` upgrade rules: an `### Upgrading` step only when apps must act.
- Approved permissions (2026-10-18):
  - Add `rbs-inline` and `steep` to the `Gemfile` as development gems (rule 11).
  - Add `rbs_rails` if Steep needs it for appkit's own Active Record model (rule 11).
  - Edit `.github/workflows/ci.yml` to add the `sig/` staleness check and `steep check` (rule 13).

## In scope

- Inline `#:` signatures on every Ruby file in `app/` and `lib/` (32 files).
- A committed `sig/`, generated from those signatures with `rbs-inline`, and `!sig/` in `.gitignore`.
- A rake task that regenerates `sig/`.
- A Steep setup that type-checks `app/` and `lib/` at the default diagnostics level.
- CI steps: one fails when `sig/` is stale, one fails when `steep check` fails.
- A lefthook pre-commit hook that regenerates `sig/` and stops the commit when it changed.
- A lefthook pre-push hook that runs `steep check`.
- A `CHANGELOG.md` entry, and a README note that tells host apps where appkit's types come from.

## Out of scope

- Proof that a host app's `rbs collection` and Steep load `sig/` from a git-sourced appkit. sticker-app PR #180 proves that.
- sticker-app's own change to drop its appkit workarounds.
- The dotfiles changes: the global `sig/` ignore, and the `new-repo-setup` and `ruby-style` updates.
- Signatures for `test/` and `test/dummy`.
- The generator templates in `lib/generators/appkit/install/templates/`.
- `.github/workflows/rails-ci.yml`.

## Acceptance criteria

- Every method in `app/` and `lib/` has an inline `#:` signature, or an inline marker that says why Steep cannot type it.
- Running the rake task after a change to the `#:` signature of `Appkit::QrCodeLink#signed` updates the matching file in `sig/`.
- Running the rake task leaves a hand-written `sig/manifest.yaml` unchanged.
- `sig/` is tracked in git although the global ignore file ignores `sig/`: `git check-ignore` reports none of its files.
- A pull request that changes a `#:` signature without regenerating `sig/` fails CI.
- A pull request whose `sig/` matches its `#:` signatures passes that CI check.
- A `#:` signature that contradicts its method body, such as `#: () -> Integer` on a method that returns a String, fails `steep check` in CI.
- `steep check` passes on the finished branch at the default diagnostics level.
- A commit that changes a `#:` signature without regenerating `sig/` stops, and the regenerated `sig/` is left in the working tree to stage.
- A push of a branch with a Steep error stops before it reaches GitHub.
- A gem built from appkit with `gem build` contains `sig/`.
- The tests, RuboCop, erb_lint, both Brakeman scans and bundler-audit stay green.

## Flagged concerns

- Proof versus scope: this change ships `sig/` before anything proves that a git-sourced consumer loads it. Proving it here would pull sticker-app work into an appkit change. Chosen side: keep the proof in sticker-app PR #180. If that proof fails, a follow-up appkit change fixes how `sig/` ships.

## Open questions

None.
