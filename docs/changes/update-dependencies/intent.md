# Intent: Update all dependencies to their latest stable versions

Author: Etienne van Delden. Status: accepted. Type: chore.

## Problem

Appkit runs on dependency versions that are behind their latest stable releases. `bundle outdated` lists 23 gems with newer versions, including both personal git gems. The project pins Ruby 4.0.5 while 4.0.7 is out, and the lockfile uses Bundler 4.0.16 while 4.0.22 is out. Three GitHub Actions are a major version behind. The gemspec floors still accept versions older than the ones appkit is tested against, so a consuming app can resolve a combination nobody tested.

## Proposed outcome

Every dependency appkit controls sits on its latest stable version, and the engine is proven to work on it. Consuming apps can only install appkit next to versions it is tested against.

## Affected users and systems

- The engine itself: Gemfile.lock, appkit.gemspec, .ruby-version, the test suite against the dummy app.
- Consuming apps: the gemspec floors decide which versions they can resolve. Raising railties to `~> 8.1` means an app on Rails 8.0 can no longer install appkit.
- Consuming apps that call the reusable workflow `.github/workflows/rails-ci.yml`: they get the new action versions on their next CI run.
- appkit's own CI in `.github/workflows/ci.yml`.

## Constraints

- Never skip a major version. Each action major bump here is exactly one major step.
- Changes to `.github/workflows/` need explicit approval (playbook rule 13). This intent records that approval for the action version bumps only.
- Installing system tooling needs explicit approval (playbook rule 8). This intent records that approval for one install only: `gem install bundler -v 4.0.22` under Ruby 4.0.7.
- Version constraint style follows the dependencies skill: `~> major.minor`, no extra upper bound.
- Personal git gems stay unversioned and move by commit SHA.
- Fix deprecation warnings that the new versions surface, as part of this change.
- No linter disable comments and no new `.rubocop_todo.yml` entries.

## In scope

- Locked gems: every gem in Gemfile.lock moves to the latest version its constraints allow.
- Personal git gems: mvpa-css (cdc8355 → 412cc74) and rubocop-eirvandelden (a168e3d → 1e2e033) move to their latest commits.
- Gemspec runtime floors, all in `~> major.minor` style:
  - railties `>= 8.0` → `~> 8.1`
  - turbo-rails `>= 2.0` → `~> 2.0`
  - importmap-rails `>= 1.0` → `~> 2.2`
  - web-push `~> 3.0` → `~> 3.1`
  - rqrcode `~> 3.0` → `~> 3.2`
  - okcomputer `~> 1.19` → `~> 1.20`
- Gemspec development floor: rails `>= 8.0` → `~> 8.1`, to match railties.
- Ruby: `.ruby-version` 4.0.5 → 4.0.7 (already installed through rv).
- Bundler: `BUNDLED WITH` 4.0.16 → 4.0.22.
- GitHub Actions, all on floating major tags:
  - actions/checkout `@v6.0.3` → `@v7`
  - actions/cache `@v5` → `@v6`
  - actions/setup-node `@v6` → `@v7`
  - actions/upload-artifact `@v7` stays `@v7`
- Code fixes for any new RuboCop offenses or deprecation warnings that the updates surface.
- A CHANGELOG.md line under Unreleased → `### Changed`: appkit requires Rails 8.1, plus the new gemspec floors. It names no Ruby requirement, because the gemspec sets no `required_ruby_version`; `.ruby-version` binds only appkit's own development.

## Out of scope

- marcel 1.2.1 → 2.1.0: Active Storage constrains it to `~> 1.0`, so it cannot move until Rails allows it.
- `spinel-coop/setup-rv@main`: it has no releases, so it stays on `@main`.
- Adding a Dependabot config: the repo has none. That belongs in a separate change.
- Any behaviour change in the engine beyond what an update forces.

## Acceptance criteria

- `bundle outdated` lists only marcel, held back by Active Storage.
- An app on Rails 8.0 cannot resolve appkit; an app on Rails 8.1 can.
- The engine test suite passes on Ruby 4.0.7 with no deprecation warnings.
- RuboCop, both Brakeman scans and bundler-audit pass, with no new disable comments or todo entries.
- appkit's CI on the pull request is green on checkout `@v7` and cache `@v6`.
- `rails-ci.yml` references checkout `@v7`, cache `@v6`, setup-node `@v7` and upload-artifact `@v7`.
- `Gemfile.lock` reads `BUNDLED WITH 4.0.22`, and `.ruby-version` reads `ruby-4.0.7`.
- A reader of CHANGELOG.md learns under Unreleased that appkit now requires Rails 8.1.

## Flagged concerns

- Compatibility versus current floors: raising railties to `~> 8.1` stops apps on Rails 8.0 from installing appkit. Chosen side: current floors. The CHANGELOG entry tells consumers.
- Shared workflow versus caution: `rails-ci.yml` is reusable, so the action major bumps reach consuming apps on their next CI run. Chosen side: bump. appkit's own CI uses checkout and cache and proves those two; setup-node and upload-artifact only run inside `rails-ci.yml`, so a consuming app's CI proves them.

## Open questions

None.
