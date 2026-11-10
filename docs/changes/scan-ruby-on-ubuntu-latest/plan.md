# Plan: Run scan_ruby on ubuntu-latest

From `intent.md` (2026-11-10). Status: accepted.

## Design

### Domain terms

Not affected: no glossary terms. The change uses the intent's words: the `scan_ruby` job, the runner, the reusable workflow `rails-ci.yml`.

### Diagrams

Not affected: one YAML value changes. No objects, tables, flows or states change.

### Signatures

Not affected: no Ruby code changes.

Not checked: the change holds no Ruby, so `steep check` has nothing to check.

### Complexity

Not affected: no new path and no queries. The job runs the same steps on a different runner image.

### Invariants

- `scan_ruby` in `.github/workflows/rails-ci.yml` declares `runs-on: ubuntu-latest`. The workflow file holds it. The YAML check in `## Proof` proves it.
- The two existing comments `# ubuntu-slim fails to load openssl-4.0.2 (libcrypto lacks OPENSSL_3.4.0)` above `scan_js` and `lint` stay unchanged.

### Alternatives

- A. Minimal diff (chosen): change the one `runs-on` line of `scan_ruby`. It meets every acceptance criterion, including "The diff touches only that line".
- B. Consistency: also add the runner comment above `scan_ruby`'s `runs-on`, and widen the `CHANGELOG.md` line 21 bullet to name `scan_ruby`. Rejected for this plan, because it breaks the criterion "The diff touches only that line". The comment would also claim a root cause (`libcrypto lacks OPENSSL_3.4.0`) that nobody verified for `scan_ruby`: its log says only `OpenSSL is not available`. The CHANGELOG part is raised as a decision for Etienne, see `## Design decisions`.
- C. Change Brakeman instead (drop `--ensure-latest`, or point Rubygems at plain HTTP). Rejected: the intent puts the apps' `bin/brakeman` and the `ubuntu-slim` fix out of scope, and the intent's decision is "go back to using ubuntu".

## Design decisions

- The diff adds no runner comment above `scan_ruby`. The intent's criterion asks for a one-line diff, and the comment's root cause is unverified for this job.
- The two existing `ubuntu-slim` comments stay. The intent says to remove `ubuntu-slim` from comments only if the file no longer uses it. After this change no `runs-on` uses it, but the comments still explain why `scan_js` and `lint` moved. The intent's "Otherwise leave the comments alone" and its out-of-scope "any other job" both point to no edit there.
- Conflict with a repository rule, not resolved here: `CLAUDE.md` says a pull request that changes `rails-ci.yml` reaches apps and adds a `CHANGELOG.md` entry. Commit `efef3a0` did that for `scan_js` and `lint` (`CHANGELOG.md:21`). The intent's criterion "The diff touches only that line" rules the entry out. The plan follows the intent and leaves `CHANGELOG.md` alone. Etienne decides; if he wants the entry, it is one edit of the `CHANGELOG.md:21` bullet to also name `scan_ruby`, with "Apps need not act." kept and no `### Upgrading` step.
- Conflict with criterion 3, not resolved here: the intent asks for Clocky's `scan_ruby` "run against this branch of the workflow". That run is not possible inside the intent's scope. appkit's own `ci.yml` does not call `rails-ci.yml`, so the appkit pull request never runs `scan_ruby`. Clocky calls the workflow at `@main` and has no `workflow_dispatch` trigger, so it runs this branch only with a Clocky edit, and the intent puts "Changes in Clocky" out of scope. Etienne decides between two paths. Path 1 (the plan's default): pre-merge evidence stays indirect, and the direct proof is a new Clocky run after merge. Path 2: Etienne authorizes a temporary Clocky draft pull request that changes only `@main` to `@scan-ruby-on-ubuntu-latest` in Clocky's `.github/workflows/ci.yml`; it runs `scan_ruby` against this branch before merge, and it is closed unmerged with its branch deleted.

## Integration points

- Every app whose CI calls `eirvandelden/appkit/.github/workflows/rails-ci.yml@main`. Clocky does this in `.github/workflows/ci.yml` (job `ci`). The merge changes their `scan_ruby` runner at once.
- Clocky run `42821079816` (`main`, after PR #174) is the failing baseline: `ci / scan_ruby` fails with `Gem::Request.configure_connection_for_https: OpenSSL is not available`. In the same run `ci / scan_js` and `ci / lint` pass on `ubuntu-latest` with the same `spinel-coop/setup-rv@main` step.

## Files that change

- `.github/workflows/rails-ci.yml` — line 13, `runs-on: ubuntu-slim` becomes `runs-on: ubuntu-latest`. Nothing else in the file changes.

## Order of work

No criterion needs a test: the change is configuration.

1. Edit `.github/workflows/rails-ci.yml` line 13 from `    runs-on: ubuntu-slim` to `    runs-on: ubuntu-latest`. Keep the four-space indent.
2. Run the checks for criteria 1 and 4 in `## Proof`, except the pull request part of criterion 4.
3. Commit with `ci: run scan_ruby on ubuntu-latest`.
4. Run the check for criterion 2 in `## Proof`. It compares commits, so it runs only after step 3.
5. Push the branch. The appkit pull request's own CI (`ci.yml`) must stay green.
6. Check criterion 3 by the path Etienne chose (see `## Design decisions`). Path 1: after Etienne merges, start a new Clocky CI run. Path 2: before merge, on the temporary Clocky draft pull request. Record the run URL and the result in the delivery account.

## Risks

- The merge changes `scan_ruby` for every app at once. If `ubuntu-latest` had a different problem, every app's `scan_ruby` would still fail. Evidence against it: `lint` and `scan_js` run the same Ruby setup on `ubuntu-latest` and pass in Clocky.
- `ubuntu-latest` is a larger runner than `ubuntu-slim`. That costs more runner minutes per run. The intent accepts this.
- Brakeman's `--ensure-latest` may now reach rubygems.org and find a newer Brakeman. The job then fails with a "newer version" message, not with the OpenSSL error. That is Brakeman doing its job and is out of scope; the app updates its Brakeman.
- `gh run rerun` of an old Clocky run may reuse the old workflow resolution of `@main`. This plan did not verify how a re-run resolves a reusable workflow ref, so step 6 uses a new run, not a re-run.
- Rejected: Alternatives B and C, see `### Alternatives`.

Out of scope, named as follow-ups:

- appkit's own `.github/workflows/ci.yml` still runs two jobs on `ubuntu-slim` (lines 14 and 116). Moving them needs its own intent.
- The Brakeman `--ensure-latest` flag in the apps' `bin/brakeman`, the `ubuntu-slim` image itself, the `rv` Ruby build, and every change in Clocky or other apps.

## Proof

- `scan_ruby` in `rails-ci.yml` declares `runs-on: ubuntu-latest` → check: `ruby -ryaml -e 'puts YAML.load_file(".github/workflows/rails-ci.yml")["jobs"]["scan_ruby"]["runs-on"]'` prints `ubuntu-latest`.
- The diff touches only that line → check, after the commit: `git diff --numstat origin/main...HEAD -- . ':(exclude)docs/changes'` prints exactly `1	1	.github/workflows/rails-ci.yml`, and `git diff origin/main...HEAD -- .github/workflows/rails-ci.yml` shows only the `runs-on` line of `scan_ruby`.
- Clocky's `scan_ruby` check no longer fails with `OpenSSL is not available` → check, by the path Etienne chose in `## Design decisions`. Path 1, after merge: start a new Clocky CI run (the next push to Clocky `main`, or a Clocky pull request). Path 2, before merge: the run of the temporary Clocky draft pull request. Find it with `gh run list -R eirvandelden/clocky --workflow CI --limit 1`. `gh run view <id> -R eirvandelden/clocky --json jobs --jq '.jobs[] | select(.name == "ci / scan_ruby") | .conclusion'` must not print a failure caused by OpenSSL, and `gh run view <id> -R eirvandelden/clocky --log --job <scan_ruby job id> | grep -c "OpenSSL is not available"` must print `0`. The log must show Brakeman's report and the bundler-audit result.
- `actionlint` or the repository's workflow checks stay green → check: `command -v actionlint && actionlint .github/workflows/rails-ci.yml` if actionlint is already installed (do not install it, playbook rule 8); the YAML check above parses the file; the appkit pull request's `ci.yml` checks are green.

Per changed file, the unit tests expected:

- `.github/workflows/rails-ci.yml`: none. Configuration has no tests.

Test setup: none.

---
Domain skills applied: None. The change is one CI runner value; no Rails, Ruby or UI skill applies.

## Critique

### Round 1 (Codex gpt-6.1-sol)

- The plan replaces the intent's branch-specific Clocky check with a post-merge run, and green appkit CI cannot prove the fix → fixed (`## Design decisions` now names the conflict with criterion 3, offers Path 1 post-merge and Path 2 a temporary Clocky draft pull request, and leaves the choice to Etienne; `## Order of work` step 6 and `## Proof` follow the chosen path)
- The criterion 2 check compares `origin/main...HEAD` but ran before the commit, so it misses the uncommitted edit → fixed (the check now runs as step 4, after the commit in step 3, and its `## Proof` line says "after the commit")
