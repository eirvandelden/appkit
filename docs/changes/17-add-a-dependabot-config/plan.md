# Plan: Add a Dependabot config

From `intent.md` (2026-10-16). Status: accepted.

## Design decisions

- Schedule `interval: "daily"` in both ecosystems. Intent leaves the interval open. The cooldown sets the delay to one week; a daily check opens the pull request on the first run after day seven. A weekly check would add up to seven more days, so a release could wait almost two weeks. Daily runs add Dependabot jobs, not pull requests: a pull request needs a new release.
- Bundler gets `allow: [{ dependency-type: "all" }]`. Without it, Dependabot version updates cover only gems named in a manifest ("All dependencies explicitly defined in a manifest are kept up to date by version updates", options reference, section `allow`). Two of the six releases in the intent's Problem, json and net-imap, are indirect gems (not in `Gemfile` or `appkit.gemspec`). The default config would miss them, so the Problem is a verified need. `all` is documented for Bundler: "For `bundler`, ... also the dependencies of direct dependencies". This is not a group, label, reviewer or ignore rule, so the minimal-config constraint holds.
- GitHub Actions gets no `allow`: every action is a direct dependency.
- `cooldown: { default-days: 7 }` in both ecosystems. The options reference says "The `default-days` option is supported for all package managers listed", and both Bundler and GitHub Actions are listed. No `semver-*-days`: one week for every update type is what the intent asks for.
- No `versioning-strategy`, `ignore`, `groups`, `labels`, `reviewers`, `assignees`, `open-pull-requests-limit` or `target-branch`. The defaults propose every update type, and no verified problem needs more.
- The file starts with `---`. The global yamllint config warns on a missing document start (the two workflows show that warning today).
- The findings go into `AGENTS.md` `## Gotchas` (`CLAUDE.md` is a symlink to it). They are maintainer facts, not app upgrade steps, so they do not belong in `CHANGELOG.md`. The Dependabot config does not require apps to act, so it gets no CHANGELOG entry and no `### Upgrading` (AGENTS.md "Upgrade instructions").
- Source links point at dependabot-core commit `de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a` (main on 2026-10-16), so a line reference stays valid. GitHub's docs do not describe git gems, gemspec versions or branch refs, so the source is the documentation for those three answers.

## Integration points

- GitHub Dependabot reads `.github/dependabot.yml` from the default branch only. Nothing runs before merge to `main`.
- Dependabot bundler reads `Gemfile`, `Gemfile.lock`, `appkit.gemspec` and `lib/appkit/version.rb` (the gemspec `require_relative`s it). `Gemfile.lock` says `BUNDLED WITH 4.0.22`; dependabot-core supports Bundler 2 and 4 (`bundler/lib/dependabot/bundler/package_manager.rb`, `SUPPORTED_BUNDLER_VERSIONS`).
- The Gemfile source is `https://gem.coop`. Dependabot reads release dates for the cooldown from `<registry>/api/v1/versions/<gem>.json` (`bundler/lib/dependabot/bundler/package/package_details_fetcher.rb`, `RELEASES_URL`). `curl https://gem.coop/api/v1/versions/marcel.json` returns 200 with `created_at` per version, so the cooldown has dates to work with.
- Dependabot github-actions reads `.github/workflows/ci.yml` and `.github/workflows/rails-ci.yml` ("For GitHub Actions, use the value `/`. Dependabot will search the `/.github/workflows` directory", options reference, section `directories` or `directory`).
- Apps call `rails-ci.yml` at `@main`. A merged action bump there reaches every app's CI at once. The pull request is the review gate (intent constraint).

## Files that change

- `test/dependabot_config_test.rb` — new. Minitest test that loads `.github/dependabot.yml` with `YAML.safe_load_file` and asserts its structure (see Proof). It follows `test/importmap_pins_test.rb`: `require "test_helper"`, `ActiveSupport::TestCase`, path from `Appkit::Engine.root`.
- `.github/dependabot.yml` — new. Content, exactly:

  ```yaml
  ---
  version: 2
  updates:
    - package-ecosystem: "bundler"
      directory: "/"
      schedule:
        interval: "daily"
      cooldown:
        default-days: 7
      allow:
        - dependency-type: "all"

    - package-ecosystem: "github-actions"
      directory: "/"
      schedule:
        interval: "daily"
      cooldown:
        default-days: 7
  ```

- `AGENTS.md` — add four lines to `## Gotchas`, after the `rails-ci.yml` `@main` line, one per finding below. Write them in the file's style: Simplified Technical English, one line each, file references in backticks. Each line carries its documentation or source link.
  1. Cooldown gaps. Security update pull requests skip the cooldown: "The `cooldown` option is only available for *version* updates, not *security* updates" (options reference, section `cooldown`). Git gems also skip it. Dependabot proposes the newest commit on the tracked branch of `mvpa-css` and `rubocop-eirvandelden` as a new `revision` in `Gemfile.lock`. The cooldown does not delay these pull requests: for a git gem it filters only version tags, and these gems track a branch. Links: https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference (section `cooldown`), https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/update_checker.rb#L286-L308 and https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/common/lib/dependabot/git_commit_checker.rb#L160-L167.
  2. marcel. With `dependency-type: "all"`, Dependabot checks indirect gems such as marcel. It opens a pull request only for a version that Bundler resolves against the other locked gems. Active Storage requires `marcel (~> 1.0)`, so marcel 2.x (2.0.0 and 2.1.0 exist) gives no pull request, broken or otherwise. Links: https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference (section `allow`, table `dependency-type`) and https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/update_checker.rb#L36-L40.
  3. `appkit` SHA lines. Dependabot fetches `lib/appkit/version.rb` with the gemspec, because the gemspec `require_relative`s it. In its temporary copy of the gemspec it replaces `Appkit::VERSION` with the `appkit (...)` version already in `Gemfile.lock`, so its pull requests leave the `appkit (0.1.0.pre.git.<sha>)` lines unchanged. After a Dependabot merge HEAD moves, so the existing `version.rb` gotcha applies to the next local `bundle exec`. Links: https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/file_fetcher.rb and https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/file_updater/lockfile_updater.rb#L338-L360.
  4. App-facing Dependabot pull requests. A runtime gem major in `appkit.gemspec` comes as a widened range (`~> 8.1` becomes `>= 8.1, < 10`), not as the `~> major.minor` style the `dependencies` skill asks for; rewrite it in the pull request before merge. A pull request that changes `appkit.gemspec` runtime dependencies or `rails-ci.yml` reaches apps, so add its `CHANGELOG.md` entry (and `### Upgrading` when apps must act) in that pull request before merge. `spinel-coop/setup-rv@main` is a branch ref, so Dependabot never updates it. Links: https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/bundler/lib/dependabot/bundler/update_checker/requirements_updater.rb#L188-L260 and https://github.com/dependabot/dependabot-core/blob/de71a59f11cc8373d39bbf5b7af5e8b73f45ca0a/github_actions/lib/dependabot/github_actions/file_parser.rb#L94.

  Before writing each line, open its link and confirm the cited lines still say what this plan says. If one does not, report the difference instead of writing the line.

No other file changes. `Gemfile.lock` may get the `appkit (0.1.0.pre.git.<sha>)` rewrite from `bundle exec` (AGENTS.md gotcha); revert it before every commit.

## Order of work

1. Write `test/dependabot_config_test.rb` with all tests from Proof. Run `bundle exec ruby -Itest test/dependabot_config_test.rb`. Watch every test fail with `Errno::ENOENT` for `.github/dependabot.yml`. Commit the test.
2. Add `.github/dependabot.yml` with the content above. Run the test file again; all green. Run `yamllint .github/dependabot.yml`; no warnings. Commit.
3. Add the four `AGENTS.md` gotchas, after verifying each link. Commit.
4. Run `bundle exec rubocop` and `bundle exec rake test`. Both green. Check `git status` and revert any `Gemfile.lock` appkit-line rewrite.
5. After merge (outside this branch, Etienne or the coordinator): run the post-merge checks in Proof and record the result in the pull request description.

## Risks

- Dependabot validates the config only on the default branch. A wrong key shows up only after merge. Mitigation: the keys and values come from the options reference read on 2026-10-16, the structural test pins them, and the post-merge check reads the Dependabot page.
- `dependency-type: "all"` raises the pull request count. The default limit of five open version-update pull requests per ecosystem caps it ("If five pull requests with version updates are open, no further pull requests are raised"). Rejected: `groups`, because the intent forbids grouping.
- Git gem pull requests skip the cooldown (finding 1). Rejected: an `ignore` rule or a cooldown workaround. Both are Etienne's own gems, the intent forbids ignore rules without a verified problem, and an early bump of his own gem is not a problem.
- Widened gemspec ranges (finding 4). Rejected: `versioning-strategy: increase`. It changes the default for every gem to fix a style point the review catches, and the intent asks for a minimal config.
- A merged action major in `rails-ci.yml` reaches every app at once. Accepted by the intent: the pull request is the gate. Finding 4 tells the reviewer to write the CHANGELOG entry.
- Several Dependabot pull requests edit `Gemfile.lock` at once and conflict after one merges. Dependabot rebases its own open pull requests; no action.
- Rejected: a JSON Schema check of the YAML (SchemaStore `dependabot-2.0.json`). It needs a new tool, which rule 11 makes a separate approval. The structural test and the post-merge page check cover validity.

## Proof

- `.github/dependabot.yml` is valid → `test/dependabot_config_test.rb` `test "declares version 2 with a bundler and a github-actions update at the root"`; check: `yamllint .github/dependabot.yml` gives no output; post-merge check: on the Insights, Dependency graph, Dependabot tab (https://github.com/eirvandelden/appkit/network/updates), both ecosystems are listed with no config error; press "Check for updates" on each and confirm its latest job log ends without an error.
- A new gem release opens a bundler pull request only after it is a week old → `test/dependabot_config_test.rb` `test "bundler waits seven days after a release"`; post-merge check: every bundler version-update pull request body names a version whose `created_at` on `https://gem.coop/api/v1/versions/<gem>.json` is at least seven days before the pull request date (security update pull requests and git gems excepted, finding 1).
- A new action release opens a github-actions pull request that touches `ci.yml` and `rails-ci.yml` → `test/dependabot_config_test.rb` `test "github-actions scans the workflows and waits seven days after a release"`; post-merge check: the first github-actions pull request for an action used in both files (`actions/checkout`, `actions/cache`) changes both `.github/workflows/ci.yml` and `.github/workflows/rails-ci.yml`.
- A major gem update is proposed, not skipped → `test/dependabot_config_test.rb` `test "no update is restricted by type, ignore rule or versioning strategy"`.
- A release that the constraints block, such as a marcel release above `~> 1.0`, produces no broken pull request → `test/dependabot_config_test.rb` `test "bundler includes indirect gems"` (marcel is checked at all); recorded answer: AGENTS.md finding 2; post-merge check: no open pull request bumps marcel to 2.x.
- The three Scope checks each have a recorded answer with a documentation link → check: `grep -n -i "dependabot" AGENTS.md` shows findings 1, 2 and 3, each with a link.
- `bundle exec rubocop` and the test suite stay green → check: `bundle exec rubocop` and `bundle exec rake test` exit 0.

Per changed file, the unit tests expected, named as behaviour:
- `test/dependabot_config_test.rb`: declares version 2 with a bundler and a github-actions update at the root; bundler waits seven days after a release; bundler includes indirect gems; github-actions scans the workflows and waits seven days after a release; no update is restricted by type, ignore rule or versioning strategy; stays minimal (no `groups`, `labels`, `reviewers`, `assignees` or `ignore` key in any update).
- `.github/dependabot.yml`: covered by the test above.
- `AGENTS.md`: prose, covered by the grep check.

Test setup: none beyond `test_helper`. The test reads the real file; no fixtures, no fakes. Find an update by `package-ecosystem`, not by array index.

## Out of scope

- Any dependency version change, including merging a Dependabot pull request.
- Edits to `ci.yml`, `rails-ci.yml`, `lib/appkit/version.rb` or how `Gemfile.lock` is written.
- Auto-merge, groups, labels, assignees, reviewers, security-only rules, other ecosystems.
- A CHANGELOG entry for this change.

---
Domain skills applied: dependencies, rails-testing (Minitest, personal project).

## Critique

### Round 1 (codex exec -p terra)

- The seven-day cooldown is treated as applying to every bundler pull request, but security updates bypass it. → fixed (the bundler Proof line now names version-update pull requests and excepts security updates; AGENTS.md finding 1 records that security updates skip the cooldown, with the docs quote)
- Finding 3 says Dependabot does not evaluate `lib/appkit/version.rb`, but its fetcher follows the gemspec `require_relative` and the updater replaces `Appkit::VERSION` with the lockfile version. → fixed (finding 3 now says Dependabot fetches `version.rb` and replaces `Appkit::VERSION` in its temporary gemspec, and links `file_fetcher.rb`)
- The weekly schedule is justified as "no speed" lost, but a weekly check adds up to seven days after the cooldown ends. → fixed (both updates now use `interval: "daily"`; the design decision explains the added Dependabot jobs and unchanged pull request count)
- The validity check relies on `gh run list` and an exact "Dependabot Updates" run name, while Dependabot runs as a dynamic workflow and its status lives on the Dependabot tab. → fixed (the post-merge check now uses the Dependency graph Dependabot tab, "Check for updates" and the job log)
