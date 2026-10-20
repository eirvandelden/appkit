# Plan: Publish appkit's type signatures

From `intent.md` (2026-10-20). Status: accepted.

## Design decisions

Facts this plan rests on, checked on 2026-10-20 in a scratch copy of the repository (Ruby 4.0.7, rbs 4.2.0, rbs-inline 0.14.0, Steep 2.1.0):

- `rbs-inline --opt-out --output=sig app lib` strips the `app/` and `lib/` prefix. `app/models/appkit/qr_code_link.rb` becomes `sig/models/appkit/qr_code_link.rbs`, and `lib/appkit.rb` becomes `sig/appkit.rbs`. The 32 files give 32 `.rbs` files with no path collision.
- Without annotations, Steep reports 8 signature errors and, once those are resolved, 117 Ruby diagnostics (88 `Ruby::NoMethod`, 26 `Ruby::UnknownConstant`, 3 others). `steep check` fails on warnings too: its default severity level is `:warning`, and `UnknownConstant` is a warning at the default diagnostics level.
- The 8 signature errors are superclasses that no RBS declares: the host-owned `ApplicationController` (7 engine controllers) and `::OkComputer::Check` (`lib/appkit/ok_computer/solid_queue_check.rb`). A superclass sits in the generated `.rbs`, so a `# steep:ignore` comment in the Ruby file cannot reach it.
- `ruby/gem_rbs_collection` has RBS for railties, actionpack, actionview, activerecord, activejob, activesupport, rqrcode and web-push. It has none for okcomputer, solid_queue, turbo-rails or importmap-rails.
- `rbs collection` must ignore the `appkit` gem itself, or it loads `sig/` a second time as a library. Ignoring it also drops appkit's runtime dependencies, so `rqrcode` and `web-push` must be listed by name in `rbs_collection.yaml`.
- `# steep:ignore NoMethod` accepts only diagnostic names after the keyword. Any trailing text makes Steep discard the comment (`steep-2.1.0/lib/steep/ast/ignore.rb`, `return unless scanner.eos?`). The reason therefore goes on the comment line above.
- rbs-inline 0.14 accepts `# @rbs module-self ::ActiveRecord::Base` above a module and emits `module Appkit::Transferable : ::ActiveRecord::Base`. A `singleton(...)` module-self is not accepted.
- Methods inside an `ActiveSupport::Concern` `class_methods do ... end` block get no signature from rbs-inline.
- rubocop-eirvandelden already sets `Layout/LeadingCommentSpace: AllowRBSInlineAnnotation: true`, so `#:` comments pass RuboCop.

Decisions:

1. Signatures: every `def` in `app/` and `lib/` gets a `#:` comment on the line above it, or `# @rbs` parameter lines plus `# @rbs return:` where keyword arguments need names. Every `attr_reader`, `attr_accessor` and constant gets a trailing `#:` type. `Appkit::Configuration`'s single `attr_accessor` with 13 names splits into one `attr_accessor` line per type, because one trailing `#:` types every name on its line. A value whose type is owned by the host (`User`, `Session`, `Current`, the host's `ApplicationController`) is written as `untyped` in a signature. The shipped `sig/` then never names a host constant.
2. Concerns get a module self type with `# @rbs module-self`: `::ActionController::Base` for `Appkit::Authentication`, `Appkit::Authentication::SessionLookup`, `Appkit::VersionHeaders` and `Appkit::Authorization`; `::ActiveRecord::Base` for `Appkit::Authenticatable`, `Appkit::SessionBehavior`, `Appkit::Transferable` and `Appkit::UserTheming`; `::ActionView::Base` for `Appkit::FormsHelper`, `Appkit::PwaHelper` and `Appkit::ThemeHelper`. This also tells a host's Steep where each concern belongs.
3. The three `class_methods do ... end` blocks (`Authentication`, `SessionBehavior`, `Transferable`) become explicit `module ClassMethods ... end` modules inside the concern. `ActiveSupport::Concern#class_methods` defines or reopens exactly that `ClassMethods` constant, so the behaviour is the same. The existing tests prove it. Without this change rbs-inline emits no signature for `start!`, `expire_stale!`, `find_by_transfer_id`, `require_unauthenticated_access` and `allow_unauthenticated_access`.
4. Gaps Steep cannot type are marked at the spot, at the default diagnostics level. The marker has two parts: a short reason comment on the line above, such as `# Session is owned by the host app.`, and `# steep:ignore UnknownConstant` (always with the diagnostic name, never bare) at the end of the offending line. A multi-line Rails DSL block, such as `included do ... end`, uses `# steep:ignore:start` and `# steep:ignore:end` with the reason above the start line. This covers `User`, `Session`, `Current`, route helpers (`root_url`, `first_run_url`, `new_session_url`, `edit_preferences_path`), `class_attribute`, `enum`, `has_many`, `validates`, `Rails.application.config.app_version`, `::OkComputer` and `::SolidQueue`. A real type comes first; a marker is only for what no available RBS describes.
5. The two superclass gaps are marked inline with rbs-inline's `# @rbs inherits` annotation, so the shipped `sig/` names neither `ApplicationController` nor `::OkComputer::Check`. Each of the 7 engine controllers gets, above its `class` line, a reason comment (the host's `ApplicationController`, which includes `Appkit::Authentication`) and `# @rbs inherits ::ActionController::Base`; its `class` line ends in `# steep:ignore UnknownConstant`; and an `# @rbs!` block in the class body declares `include ::Appkit::Authentication` and `extend ::Appkit::Authentication::ClassMethods`. The `AGENTS.md` host contract makes both true at runtime. `Appkit::OkComputer::SolidQueueCheck` gets `# @rbs inherits ::Object` with a reason comment (okcomputer ships no RBS), `# steep:ignore UnknownConstant` on its `class` line, and `# steep:ignore NoMethod` on its `mark_message` and `mark_failure` calls. Checked in the scratch copy: `pwa_controller.rb` annotated this way generates `class PwaController < ::ActionController::Base` with the `include` and `extend`, and `steep check` on it reports no error. There is no hand-written signature file outside `sig/manifest.yaml`.
6. Steep reads the generated `sig/` (`signature "sig"`), not `check ..., inline: true`. The check then type-checks exactly the files that ship, as rbs-inline wrote them. `Steepfile` has one target that checks `app` and `lib`.
7. `rbs_collection.yaml` is committed. `rbs_collection.lock.yaml` and `.gem_rbs_collection/` are git-ignored. appkit does not commit `Gemfile.lock`, and the collection lock records the gem versions from that lockfile, so a committed collection lock would drift from every fresh resolve. This follows the same rule as `Gemfile.lock` and departs from `new-repo-setup` step 12, which commits both files. `rbs collection update` writes a fresh lock each run and never reuses a stale local one, so a local check and CI read the same collection types.
8. `rbs-inline` and `steep` go in `Gemfile` as `gem "rbs-inline", "~> 0.14", require: false` and `gem "steep", "~> 2.1", require: false`, next to `lefthook` (approved 2026-10-18). This departs from `new-repo-setup` step 12, which installs Steep globally: CI has no global gems, and the intent's approval names the Gemfile. `rbs_rails` is not added: the only Active Record model, `Appkit::PushSubscription`, needs only `belongs_to :user` and four string columns, which an `# @rbs!` block in the model declares inline.
9. The rake tasks live in `rakelib/signatures.rake`, which Rake loads automatically from the gem root. They must not go in `lib/tasks/appkit.rake`: the engine loads that file into every host app.
   - `rbs:generate` runs the intent's recipe verbatim: `find sig -name '*.rbs' -delete && rbs-inline --opt-out --output=sig app lib`. It never touches `sig/manifest.yaml`.
   - `rbs:check` runs `rbs:generate`, then `git diff --exit-code -- sig/`, and fails when `git ls-files --others --exclude-standard -- sig/` lists a file. It never touches the index, so a deleted signature shows in the diff (review round 1 replaced the recipe's `git add --intent-to-add sig/`, which staged that deletion). CI runs it.
   - `rbs:check_staged` checks out the index into a temporary directory, regenerates `sig/` there and compares it with the staged `sig/`. On a mismatch it copies what the staged files generate into `sig/` and fails, so unstaged work neither blocks nor passes a commit (review rounds 2 and 3). The pre-commit hook runs it.
   - `steep` runs `rbs collection update`, then `steep check`.
10. CI gets one new job, `types`, in `.github/workflows/ci.yml`. It repeats the existing setup steps (checkout, `setup-rv`, `bundle lock`, gem cache, `rv ci`), then runs `bundle exec rake rbs:check` and `bundle exec rake steep` as two named steps. `rails-ci.yml` is not touched.
11. The hooks go in `lefthook-local.yml`, the appkit-specific file. `lefthook.yml` stays a copy of the shared dotfiles config. Pre-commit adds `rbs` with `run: bundle exec rake rbs:check_staged` and no glob, so a commit that deletes a Ruby file, or changes `Gemfile` or `rakelib/signatures.rake`, still regenerates and checks `sig/`. The task takes a few seconds. Pre-push adds `steep` with `run: bundle exec rake steep` and no glob, so a push that changes only `Steepfile` or `Gemfile` is still checked.
12. `sig/manifest.yaml` is hand-written. It lists each standard library whose types the generated signatures name, found by running `bundle exec rake steep` and reading which stdlib types resolve. When none is needed it holds `dependencies: []`.
13. `appkit.gemspec` adds `sig` to its `spec.files` glob: `Dir["{app,config,lib,sig}/**/*", ...]`. Without it `gem build` leaves `sig/` out.
14. `CHANGELOG.md` gets one `### Added` line under `## Unreleased`, and no `### Upgrading` step: none of the cases in `AGENTS.md` applies, and apps that do not type-check see no change. The line says that a type-checking app can drop its appkit stub or `@type const` workaround, and that a hand-written appkit stub left in place makes Steep report duplicate declarations. `README.md` gets a `## Type signatures` section after `## Development`: where the types come from, that `sig/*.rbs` is generated and never edited, and the three rake tasks.
15. `Style/RbsInline` stays in rubocop-eirvandelden's `opt_in` mode. Switching it to `opt_out` would lint every `#:` comment, but it is a lint config change the intent does not ask for. It is a follow-up candidate.

No conflict with an intent `## Decisions` section: `intent.md` has none. Decisions 7, 8 and 9 each depart from a source the intent names (constraints, `new-repo-setup` step 12); each says why above.

## Integration points

- rbs-inline 0.14 CLI (`--opt-out`, `--output`).
- Steep 2.1 (`Steepfile`, `steep check`, `# steep:ignore`) and RBS 4.2 (`rbs collection`, `sig/manifest.yaml`, the gem `sig/` lookup in `docs/gem.md`).
- `ruby/gem_rbs_collection` at `main`, fetched by `rbs collection update` in CI and on push.
- GitHub Actions: `.github/workflows/ci.yml` only.
- Lefthook: `lefthook-local.yml`, run by the global git hooks.
- Host apps that type-check (first sticker-app PR #180): they load `sig/` from the installed gem.

## Files that change

- `Gemfile` — add `rbs-inline` and `steep` (decision 8).
- `.gitignore` — add `!sig/`, `.gem_rbs_collection/` and `/rbs_collection.lock.yaml`.
- `appkit.gemspec` — add `sig` to the `spec.files` glob (decision 13).
- `rakelib/signatures.rake` (new) — `rbs:generate`, `rbs:check`, `rbs:check_staged`, `steep` (decision 9). `steep` also checks `test/types/` as a host app, with its own `test/types/Steepfile` (review round 1).
- `Steepfile` (new) — one target: `signature "sig"`, `check "app", "lib"`.
- `rbs_collection.yaml` (new) — `ruby/gem_rbs_collection` source, `path: .gem_rbs_collection`, `appkit` ignored, `rqrcode` and `web-push` listed.
- `sig/manifest.yaml` (new, hand-written) — decision 12.
- `sig/**/*.rbs` (new, generated, 32 files) — never edited by hand.
- All 32 Ruby files in `app/` and `lib/` — `#:` signatures, `# @rbs module-self`, `# @rbs!` blocks for Rails DSL methods, inline Steep markers. Code changes beyond comments: `class_methods do` to `module ClassMethods` in `app/controllers/concerns/appkit/authentication.rb`, `app/models/concerns/appkit/session_behavior.rb` and `app/models/concerns/appkit/transferable.rb`; the split `attr_accessor` in `lib/appkit/configuration.rb`.
- `.github/workflows/ci.yml` — new `types` job (decision 10). Approved 2026-10-18.
- `lefthook-local.yml` — pre-commit `rbs`, pre-push `steep` (decision 11).
- `test/signatures_test.rb` (new), `test/ci_workflow_test.rb` (new), `test/lefthook_config_test.rb` (new).
- `CHANGELOG.md`, `README.md` — decision 14.

## Order of work

1. Write `test/signatures_test.rb` `test "every method in app and lib has an inline signature"` and `test "every steep:ignore names its diagnostic and has a reason above"`. Run `bin/rails test test/signatures_test.rb`. Watch it fail and list the unsigned methods.
2. Add `rbs-inline` and `steep` to `Gemfile`. Install with `bi` (never `bundle install`). Confirm `bundle exec rbs-inline --version` prints 0.14.x and `bundle exec steep version` prints 2.1.x.
3. Write the `.gitignore` test (`sig/ is not ignored when the global ignore file ignores sig/`), watch it fail, add `!sig/`, `.gem_rbs_collection/` and `/rbs_collection.lock.yaml`, watch it pass.
4. Write the rake task tests (`rbs:generate rewrites the sig file of a changed signature`, `rbs:generate leaves sig/manifest.yaml unchanged`, `rbs:check fails when sig/ is stale`, `rbs:check passes when sig/ matches`). Watch them fail. Write `sig/manifest.yaml` with `dependencies: []` for now and `rakelib/signatures.rake`. Watch them pass.
5. Write the gemspec test (`the gemspec packages sig/`), watch it fail, add `sig` to the glob, watch it pass.
6. Add `Steepfile` and `rbs_collection.yaml`. Run `bundle exec rake rbs:generate` and `bundle exec rake steep` to get the baseline diagnostics list.
7. Annotate the files one directory at a time: `lib/`, `app/models/`, `app/models/concerns/`, `app/jobs/`, `app/helpers/`, `app/controllers/concerns/`, `app/controllers/`. After each directory: `bundle exec rake rbs:generate`, `bundle exec rake steep`, then the narrowest matching tests (`bin/rails test test/models`, and so on). Do the `class_methods` to `module ClassMethods` change in its own commit, before its signatures, with `bin/rails test` green before and after.
8. Fill `sig/manifest.yaml` with the stdlib libraries Steep needs (decision 12). Run `bundle exec rake rbs:generate` and confirm `git diff sig/manifest.yaml` is empty.
9. Run the check for the contradicting signature (see `## Proof`). Revert it.
10. Write `test/ci_workflow_test.rb`, watch it fail, add the `types` job, watch it pass.
11. Write `test/lefthook_config_test.rb`, watch it fail, add the two hooks, watch it pass. Run the pre-commit and pre-push checks (see `## Proof`).
12. Update `CHANGELOG.md` and `README.md`.
13. Run the full gates: `bin/rails test`, `bundle exec rubocop`, `bundle exec erb_lint --lint-all`, both Brakeman scans and `bin/bundler-audit check --update` (exact commands in `AGENTS.md`), `bundle exec rake rbs:check`, `bundle exec rake steep`, and the `gem build` check. Re-read the full diff.

## Risks

- The shipped controller signatures say `< ::ActionController::Base`, not the host's `ApplicationController`, and `SolidQueueCheck` says `< ::Object` (decision 5). A host that reads the engine controllers' ancestors from RBS misses its own `ApplicationController` methods. Hosts do not subclass engine controllers, so this costs them nothing in practice. Rejected: a Steep-only hand-written `steep/host.rbs` declaring `::ApplicationController` and `::OkComputer::Check` (it is not inline, and it leaves the shipped `sig/` naming two constants a host may not declare); an `# @rbs!` stub of either class inside `sig/` (it collides with a host or a future okcomputer RBS that declares it).
- Whether a host's `rbs collection` and Steep load the shipped `sig/` from a git-sourced appkit is the proof the intent leaves to sticker-app PR #180.
- rbs-inline is pre-1.0 and `Gemfile.lock` floats. A rbs-inline 0.15 release that changes its output format makes `rbs:check` fail in CI on an unrelated pull request. The fix is one `bundle exec rake rbs:generate` commit. `gem_rbs_collection` at `main` floats the same way for Steep.
- Steep logs a FATAL internal error on `rescue_from ..., with: -> { head :not_found }` in `app/controllers/appkit/qr_code_controller.rb` (actionpack RBS gives the lambda an `instance` self type). In the scratch run Steep still reported that file's diagnostics. If it changes the exit status, move the lambda body into a private method with a signature and pass `with: :method_name`, which Rails supports and the existing QR code tests cover.
- Lefthook pre-commit runs in parallel, and the RuboCop command autocorrects and restages files. `rbs:check` could read a Ruby file while RuboCop rewrites it. RuboCop does not rewrite `#:` comments, so the signatures it reads stay the same.
- `rbs collection update` clones `gem_rbs_collection` on every CI run and on a push without a local cache. This adds time, not failures. No cache step is added to keep the job small.
- Rejected: `rbs_rails` (decision 8); `check ..., inline: true` (decision 6); committing `rbs_collection.lock.yaml` (decision 7); a lower Steep diagnostics level (forbidden by the intent).

Out of scope, from `intent.md`: proof that a host loads `sig/` from a git-sourced appkit; sticker-app's change; the dotfiles changes; signatures for `test/` and `test/dummy`; the generator templates; `.github/workflows/rails-ci.yml`. Also out of scope here: `Style/RbsInline` `opt_out` mode (decision 15), one-line class summary comments.

## Proof

- Every method in `app/` and `lib/` has an inline `#:` signature, or an inline marker that says why Steep cannot type it → `test/signatures_test.rb` `test "every method in app and lib has an inline signature"` and `test "every steep:ignore names its diagnostic and has a reason above"`
- Running the rake task after a change to the `#:` signature of `Appkit::QrCodeLink#signed` updates the matching file in `sig/` → `test/signatures_test.rb` `test "rbs:generate rewrites the sig file of a changed signature"`
- Running the rake task leaves a hand-written `sig/manifest.yaml` unchanged → `test/signatures_test.rb` `test "rbs:generate leaves sig/manifest.yaml unchanged"`
- `sig/` is tracked in git although the global ignore file ignores `sig/` → `test/signatures_test.rb` `test "sig/ is not ignored when the global ignore file ignores sig/"`
- A pull request that changes a `#:` signature without regenerating `sig/` fails CI → `test/signatures_test.rb` `test "rbs:check fails when sig/ is stale"` and `test/ci_workflow_test.rb` `test "the types job runs rbs:check"`
- A pull request whose `sig/` matches its `#:` signatures passes that CI check → `test/signatures_test.rb` `test "rbs:check passes when sig/ matches"`, and the branch's own green `types` job on GitHub
- A `#:` signature that contradicts its method body fails `steep check` in CI → `test/ci_workflow_test.rb` `test "the types job runs steep"`, and check: change the signature above `Appkit::ManifestIcon#content_type` to `#: () -> Integer`, run `bundle exec rake rbs:generate && bundle exec rake steep`, see it exit non-zero with `Ruby::MethodBodyTypeMismatch` on `manifest_icon.rb`, then revert both files. Deviation: `QrCodeLink#signed` cannot serve here, because the activesupport RBS types `MessageVerifier#generate` as `untyped`, so Steep reports no mismatch there
- `steep check` passes on the finished branch at the default diagnostics level → check: `bundle exec rake steep` exits 0, and `Steepfile` holds no `configure_code_diagnostics` line
- A commit that changes a `#:` signature without regenerating `sig/` stops, and the regenerated `sig/` is left in the working tree to stage → `test/lefthook_config_test.rb` `test "pre-commit checks the staged sig/"`, `test/signatures_test.rb` `test "rbs:check_staged fails on a staged signature change without its sig, and regenerates sig/"` and `test "rbs:check_staged recovers a partial commit with the staged signatures"`, and check: change the signature above `Appkit::QrCodeLink#signed`, `git add` only that Ruby file, run `git commit -m probe`, see the commit stop, see `git status` list `sig/models/appkit/qr_code_link.rbs` as modified and unstaged, then `git restore --staged --worktree` both files
- A push of a branch with a Steep error stops before it reaches GitHub → `test/lefthook_config_test.rb` `test "pre-push runs steep"`, and check: with the contradicting signature from above regenerated, run `lefthook run pre-push --no-auto-install` (never a plain `lefthook run`) and see it fail on the `steep` command, then revert
- A gem built from appkit with `gem build` contains `sig/` → `test/signatures_test.rb` `test "the gemspec packages sig/"`, and check: `gem build appkit.gemspec`, then `tar -xOf appkit-*.gem data.tar.gz | tar -tz | grep '^sig/'` lists `sig/manifest.yaml` and the `.rbs` files, then delete the `.gem` file
- The tests, RuboCop, erb_lint, both Brakeman scans and bundler-audit stay green → check: the step 13 gate commands, each exiting 0

Per changed file, the unit tests expected:
- `test/signatures_test.rb`: `every method in app and lib has an inline signature` (parses each `app/**/*.rb` and `lib/**/*.rb` with Prism; a `def` passes when the contiguous comment block directly above it holds a `#:` or `# @rbs` line, and the matching generated `.rbs` file holds a `def <name>:` or `def self.<name>:` member for it; an `attr_reader`/`attr_accessor` call passes when its line ends in a `#:` comment and the `.rbs` file holds an `attr_*` member for each name; the failure message lists `path:line name` for each miss), `every steep:ignore names its diagnostic and has a reason above` (each `steep:ignore` comment except `steep:ignore:end` is followed by at least one diagnostic name or is `steep:ignore:start`, and the line above it, or above the line it ends, is a plain reason comment), `rbs:generate rewrites the sig file of a changed signature`, `rbs:generate leaves sig/manifest.yaml unchanged`, `rbs:check fails when sig/ is stale`, `rbs:check fails when a committed signature has no source`, `rbs:check fails when a new source has no committed signature`, `rbs:check leaves the index unchanged`, `rbs:check passes when sig/ matches`, `rbs:check_staged ignores an unstaged signature change`, `rbs:check_staged fails on a staged signature change without its sig, and regenerates sig/`, `rbs:check_staged recovers a partial commit with the staged signatures`, `rbs:check_staged recovers a staged deletion`, `rbs:check_staged passes when the staged sig matches the staged signatures`, `sig/ is not ignored when the global ignore file ignores sig/`, `the gemspec packages sig/`.
- `test/ci_workflow_test.rb`: `the types job runs rbs:check`, `the types job runs steep`.
- `test/lefthook_config_test.rb`: `pre-commit checks the staged sig/`, `pre-push runs steep`.
- `app/models/concerns/appkit/session_behavior.rb`, `transferable.rb`, `app/controllers/concerns/appkit/authentication.rb`: no new tests; the `module ClassMethods` change keeps behaviour, and `test/models/session_behavior_test.rb`, `test/models/appkit`, `test/integration/authentication_test.rb` and the controller tests cover it.

Test setup: the rake task tests copy `app/`, `lib/`, `sig/` and `rakelib/` into a `Dir.mktmpdir`, write an empty `Rakefile` there, and run `bundle exec rake <task>` with `chdir:` the copy and `BUNDLE_GEMFILE` set to the repository's `Gemfile`. The `rbs:check` tests first run `git init`, set a local user name and email, and commit the copy. The ignore test runs `git -c core.excludesFile=<tempfile holding "sig/"> check-ignore --no-index` on `sig/manifest.yaml` and a generated `.rbs` file, and expects exit status 1 (nothing ignored). The gemspec test loads `Gem::Specification.load("appkit.gemspec")` and checks `files`. The config tests read YAML with `YAML.safe_load_file`, as `test/dependabot_config_test.rb` does. No fixtures, no network.

---
Domain skills applied: dependencies, ruby-style, rails-testing, new-repo-setup (step 12), rails-architecture (concern structure).

## Critique

### Round 1 (codex exec -p terra)

- The shipped `sig/` still names `ApplicationController` and `::OkComputer::Check`, and the Steep-only `steep/host.rbs` breaks the intent's inline-marker constraint → fixed (decision 5 now uses `# @rbs inherits ::ActionController::Base` plus an embedded `include`/`extend` on each engine controller and `# @rbs inherits ::Object` on `SolidQueueCheck`, verified in the scratch copy; `steep/host.rbs` is gone; Steepfile reads only `sig`; Risks records the trade-off)
- `rbs collection install` reuses an ignored but existing local lock, so a local check can read older collection types than CI → fixed (the `steep` task and decision 7 use `rbs collection update`)
- The pre-commit `glob: "*.rb"` misses a commit that deletes a Ruby file or changes `Gemfile` or the rake task → fixed (decision 11 runs `rbs:check_staged` with no glob; the matching risk is removed)
- The signature test proves only comment placement, not that rbs-inline emitted a member, and nothing checks the reason and diagnostic name on each `steep:ignore` → fixed (the test also matches each `def` and `attr_*` to a member in the generated `.rbs`; a new test checks every `steep:ignore` names its diagnostic and has a reason comment above)
