# Intent: appkit gets an AGENTS.md with upgrade instructions

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-12). Type: chore. Delivery: autonomous.

## Problem

appkit is a Rails engine that several of Etienne's apps use, pinned to a git SHA. It has no `AGENTS.md`, so an agent working in appkit gets no account of what the engine does, its domain, its commands or its gotchas. When appkit changes what an app must do (a migration, a config option, a partial or a controller), the changelog says what changed, but not what an app must do to follow.

## Proposed outcome

appkit has an `AGENTS.md` with the same sections as mvpa.css's: What this is, Domain, Commands and Gotchas, written from the code. `CLAUDE.md` links to it, as in mvpa.css. It also holds the rule that a change which requires apps to act adds an "Upgrading" subsection to its dated `CHANGELOG.md` entry, with steps that Etienne or an agent in another app can follow.

## Affected users and systems

- Agents and Etienne working in appkit.
- Apps that use appkit, such as journal_administration, when they upgrade.

## Constraints

- Everything in `AGENTS.md` comes from the code, the README and the changelog. Nothing is invented.
- The changelog keeps its current format.
- No permissions are needed under playbook rules 8, 9, 11, 12 or 13.

## In scope

- A new `AGENTS.md`: What this is, Domain, Commands, Gotchas, and the upgrade-instructions rule with a short example.
- `CLAUDE.md` as a link to `AGENTS.md`.

## Out of scope

- Code changes, and rewriting older changelog entries.
- mvpa.css, which gets its own change.

## Acceptance criteria

- An agent new to appkit finds in `AGENTS.md` what the engine provides, how to run its tests and linters, and its known gotchas.
- An agent that adds a migration that apps must copy adds a `### Upgrading` subsection to the changelog entry with the generator command to run.
- An agent that changes an internal method with no effect on apps adds no `### Upgrading` subsection.
- Claude Code reads the same content through `CLAUDE.md`.

## Open questions

None.
