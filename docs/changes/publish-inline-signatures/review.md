# Review: publish-inline-signatures

## Round 1 — 2026-10-20T09:25Z — f183524 (codex)

- [x] Important: Steep does not extend a host class that includes a concern with that concern's nested `ClassMethods`. A host that includes the concerns gets `Ruby::NoMethod` on `ApplicationController.allow_unauthenticated_access`, `Session.start!`, `Session.expire_stale!` and `User.find_by_transfer_id`. The explicit `extend` in the engine controllers hides this gap in appkit's own check. Give all three concerns the class-side signatures that a host needs, and cover that with a minimal host type-check — `app/controllers/concerns/appkit/authentication.rb:17` → fixed (Type-check appkit as a host app would use it)
- [x] Important: `rbs:check` misses a deleted signature. When a Ruby file is deleted and its committed `.rbs` file stays, regeneration deletes the `.rbs` file. Then `git add --intent-to-add sig/` stages that deletion, the working-tree diff is empty, and the check passes. CI accepts obsolete signatures, and the local hook stages deletions without telling anyone. Check for removals before the index is updated, or add only new files with intent-to-add — `rakelib/signatures.rake:12` → fixed (Check sig/ without touching the index, and only the staged files before a commit)
- [x] Important: the `app_name` type rejects `Appkit.config.app_name = -> { nil }`, a supported fallback that `test/integration/app_name_test.rb:35-38` tests. A host type-check reports `Ruby::ArgumentTypeMismatch` for it. `AppName` also accepts callable results such as `false` and symbols. Widen the callable's return type to keep that behaviour, then regenerate `sig/` — `lib/appkit/configuration.rb:5` → fixed (Type the configuration values that hosts may set as they behave)

## Round 2 — 2026-10-20T09:29Z — f183524 (claude)

- [x] Important: `locale_attribute` is typed `Symbol`, but the README documents it as optional ("only shown when this is set"), and `PreferencesController#locale_attribute_shown?` checks it for nil. A host that sets `Appkit.config.locale_attribute = nil` to hide the locale field gets `Ruby::ArgumentTypeMismatch` from its Steep check. Type it `Symbol?`, as `timezone_attribute` is — `lib/appkit/configuration.rb:15` → fixed (Type the configuration values that hosts may set as they behave)
- [x] Nit: `locale_attribute_shown?` and `timezone_attribute_shown?` are typed `() -> bool`, but they return `nil` when the attribute is unset (`nil && ...`). The `steep:ignore:start` block hides the mismatch. The shipped type says `bool`, the method returns `bool?` — `app/controllers/appkit/preferences_controller.rb:41` → fixed (Type the configuration values that hosts may set as they behave)
- [x] Nit: the test helpers `commit_generated_sig` and `rake` pass the parent environment to `git` and `rake rbs:check`. When the test runs inside a git hook, which exports `GIT_DIR` in a worktree (the `steep` task comment says so), `git init`, `git add .` and `git commit` in the temp copy act on the real repository. A scratch check confirmed that with `GIT_DIR` set, the "baseline" commit lands on the real branch with the temp tree. No current hook runs this file, but the steep task already clears `GIT_*` for the same reason — `test/signatures_test.rb:119` → fixed (Check sig/ without touching the index, and only the staged files before a commit)
- [x] Nit: `rbs:check fails when sig/ is stale` asserts only that the task failed. `commit_generated_sig` ignores the exit status of `git init`, `git add` and `git commit`, so a failed setup or a missing gem also passes the test. Assert that the output shows the diff of `sig/models/appkit/qr_code_link.rbs` — `test/signatures_test.rb:58` → fixed (Check sig/ without touching the index, and only the staged files before a commit)
- [x] Nit: the pre-commit `rbs` hook regenerates `sig/` from the working tree, not from the staged content. An unstaged signature edit, or an untracked new Ruby file, blocks every unrelated commit. A staged `sig/` regenerated from an unstaged Ruby edit passes, and only CI catches the mismatch — `lefthook-local.yml:33` → fixed (Check sig/ without touching the index, and only the staged files before a commit)

Compliance (acceptance criteria to proof):

- Every method has a `#:` signature or a marker → `test/signatures_test.rb` "every method in app and lib has an inline signature", "every steep:ignore names its diagnostic and has a reason above".
- Rake task updates the sig of `QrCodeLink#signed` → "rbs:generate rewrites the sig file of a changed signature".
- Rake task leaves `sig/manifest.yaml` unchanged → "rbs:generate leaves sig/manifest.yaml unchanged".
- `sig/` tracked despite a global ignore → "sig/ is not ignored when the global ignore file ignores sig/".
- Stale `sig/` fails CI → "rbs:check fails when sig/ is stale", `test/ci_workflow_test.rb` "the types job runs rbs:check" (deletion gap: Round 1).
- Matching `sig/` passes CI → "rbs:check passes when sig/ matches"; the green `types` job on GitHub is still missing (branch not pushed).
- Contradicting signature fails Steep in CI → `test/ci_workflow_test.rb` "the types job runs steep"; the manual `ManifestIcon#content_type` check is not in the diff.
- Steep passes at the default level → `Steepfile` has no `configure_code_diagnostics`; `rake steep` exit 0 per coordinator.
- Commit stops on stale `sig/` → `test/lefthook_config_test.rb` "pre-commit runs rbs:check on Ruby files"; manual check not in the diff.
- Push with a Steep error stops → `test/lefthook_config_test.rb` "pre-push runs steep"; manual check not in the diff.
- `gem build` contains `sig/` → "the gemspec packages sig/".
- Gates green → 160 tests, RuboCop and erb_lint green in this round; Brakeman and bundler-audit per coordinator.
- Every test named in `plan.md` `## Proof` exists. No existing test is weakened, skipped or deleted.

## Round 3 — 2026-10-20T09:44Z — 2cacf14 (codex)

- [x] Important: when a file has staged and unstaged signature changes, `rbs:check_staged` recovers by regenerating `sig/` from the working tree, not from the staged snapshot. With `signed -> Integer` staged and `signed -> Symbol` unstaged, the regenerated file says `Symbol`. Staging it and committing again still fails, so a partial commit can never pass. Copy the staged snapshot's generated signatures back, deletions included — `rakelib/signatures.rake:34` → fixed (Recover a stale staged sig/ from the staged snapshot)

## Round 4 — 2026-10-20T09:52Z — 5806637 (codex)

No findings.

## Round 5 — 2026-10-20T09:56Z — 5806637 (claude)

Closed findings re-checked at this SHA: Round 1 (host ClassMethods: `test/types/` checks them through `rake steep`; deleted signature: `rbs:check` diffs before touching the index and lists untracked files; `app_name` callable: `(String | ^() -> untyped)?`), Round 2 (`locale_attribute` is `Symbol?`; `*_shown?` return `bool?`; test helpers clear `GIT_*` and assert each git step; stale-sig test asserts the file name; pre-commit runs `rbs:check_staged` on the staged snapshot) and Round 3 (recovery copies what the staged snapshot generates, deletions included) all hold in the code and their tests.

- [x] Nit: the README says "CI runs the last two in the `types` job", but the list now ends with `rbs:check_staged` and `steep`. CI runs `rbs:check` and `steep`. Name the two tasks — `README.md:182` → fixed (Describe rbs:check_staged in the README and the plan)
- [x] Nit: `plan.md` `## Proof` names `test/lefthook_config_test.rb` `test "pre-commit runs rbs:check on Ruby files"`, and decision 11 says the hook runs `rbs:check`. After the Round 2 fix the test is `"pre-commit checks the staged sig/"` and the hook runs `rbs:check_staged`. The behaviour is proved, but the named test does not exist. Record the deviation in the plan — `docs/changes/publish-inline-signatures/plan.md:105` → fixed (Describe rbs:check_staged in the README and the plan)

Compliance (acceptance criteria to proof):

- Every method has a `#:` signature or a marker → `test/signatures_test.rb` "every method in app and lib has an inline signature", "every steep:ignore names its diagnostic and has a reason above".
- Rake task updates the sig of `QrCodeLink#signed` → "rbs:generate rewrites the sig file of a changed signature".
- Rake task leaves `sig/manifest.yaml` unchanged → "rbs:generate leaves sig/manifest.yaml unchanged".
- `sig/` tracked despite a global ignore → "sig/ is not ignored when the global ignore file ignores sig/".
- Stale `sig/` fails CI → "rbs:check fails when sig/ is stale", "rbs:check fails when a committed signature has no source", "rbs:check fails when a new source has no committed signature", `test/ci_workflow_test.rb` "the types job runs rbs:check".
- Matching `sig/` passes CI → "rbs:check passes when sig/ matches"; the green `types` job on GitHub follows the push.
- Contradicting signature fails Steep in CI → `test/ci_workflow_test.rb` "the types job runs steep"; the manual `ManifestIcon#content_type` check is coordinator evidence, not in the diff.
- Steep passes at the default level → `Steepfile` and `test/types/Steepfile` hold no `configure_code_diagnostics`; `rake steep` reports no type error in this round.
- Commit stops on stale `sig/`, regenerated `sig/` left to stage → "rbs:check_staged fails on a staged signature change without its sig, and regenerates sig/", "rbs:check_staged recovers a partial commit with the staged signatures", `test/lefthook_config_test.rb` "pre-commit checks the staged sig/" (renamed: see the Nit above).
- Push with a Steep error stops → `test/lefthook_config_test.rb` "pre-push runs steep"; manual check is coordinator evidence.
- `gem build` contains `sig/` → "the gemspec packages sig/".
- Gates green → in this round: 168 tests, RuboCop, erb_lint, `rake rbs:check`, `rake steep`, bundler-audit and the gem-root Brakeman scan pass.
- No existing test is weakened, skipped or deleted.

## Round 6 — 2026-10-20T10:00Z — 8e3ec50 (codex)

No findings.

## Round 7 — 2026-10-20T10:30Z — 8e3ec50 (claude)

Round 5 fixes re-checked at this SHA: `README.md:182` names `rbs:check` and `steep` for the `types` job, and `plan.md` `## Proof` and decisions 9 and 11 name `rbs:check_staged` and the test `"pre-commit checks the staged sig/"`. Both hold.

- [x] Nit: `AGENTS.md` (`CLAUDE.md` links to it) still says "`.github/workflows/ci.yml` runs the same scans, RuboCop and tests", and its Commands and Gotchas do not mention `rake rbs:generate`, `rake rbs:check`, `rake steep`, or that `sig/**/*.rbs` is generated and never edited by hand. An agent that changes a `#:` signature gets no instruction to regenerate `sig/` before the pre-commit hook stops it. Add the three tasks to Commands, the `types` job to the CI line, and the `sig/` rule to Gotchas — `AGENTS.md:19` → fixed (Document the type signature tasks in AGENTS.md)

Compliance (acceptance criteria to proof):

- Every method has a `#:` signature or a marker → `test/signatures_test.rb` "every method in app and lib has an inline signature", "every steep:ignore names its diagnostic and has a reason above".
- Rake task updates the sig of `QrCodeLink#signed` → "rbs:generate rewrites the sig file of a changed signature".
- Rake task leaves `sig/manifest.yaml` unchanged → "rbs:generate leaves sig/manifest.yaml unchanged".
- `sig/` tracked despite a global ignore → "sig/ is not ignored when the global ignore file ignores sig/".
- Stale `sig/` fails CI → "rbs:check fails when sig/ is stale", "rbs:check fails when a committed signature has no source", "rbs:check fails when a new source has no committed signature", "rbs:check leaves the index unchanged", `test/ci_workflow_test.rb` "the types job runs rbs:check".
- Matching `sig/` passes CI → "rbs:check passes when sig/ matches"; the green `types` job on GitHub follows the push.
- Contradicting signature fails Steep in CI → `test/ci_workflow_test.rb` "the types job runs steep"; the manual `ManifestIcon#content_type` check is coordinator evidence, not in the diff.
- Steep passes at the default level → `Steepfile` and `test/types/Steepfile` hold no `configure_code_diagnostics`; `rake steep` exits 0 in this round for both targets.
- Commit stops on stale `sig/`, regenerated `sig/` left to stage → "rbs:check_staged fails on a staged signature change without its sig, and regenerates sig/", "rbs:check_staged recovers a partial commit with the staged signatures", "rbs:check_staged recovers a staged deletion", "rbs:check_staged ignores an unstaged signature change", `test/lefthook_config_test.rb` "pre-commit checks the staged sig/"; the manual `git commit` check is coordinator evidence.
- Push with a Steep error stops → `test/lefthook_config_test.rb` "pre-push runs steep"; the manual check is coordinator evidence.
- `gem build` contains `sig/` → "the gemspec packages sig/".
- Gates green → in this round: 168 tests (0 failures), RuboCop, erb_lint, `rake rbs:check` (no diff), `rake steep`, both Brakeman scans and bundler-audit all exit 0.
- Every test named in `plan.md` `## Proof` and its per-file list exists. No existing test is weakened, skipped or deleted (`test/lefthook_config_test.rb` only gains two tests).
