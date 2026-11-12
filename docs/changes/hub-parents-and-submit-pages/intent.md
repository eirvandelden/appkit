# Intent: Hubs under a parent hub, sign-out as a hub page, and a list origin

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-12). Type: feature. Delivery: autonomous. Codex review: no.

## Problem

Journal Administration's accepted navigation-hubs amendment (2026-11-11, `docs/changes/navigation-hubs/intent.md` in that repository) replaces the account pop-up with a 👤 Profiel hub: a rail hub like Plannen, with a hub column and landing tiles for Gegevens, Voorkeuren, Beheer and Uitloggen. Today the appkit menu map cannot express that:

- A hub that has no rail item of its own (Beheer, `rail: false`) marks no rail item while it is current, so on a Beheer page nothing in the rail shows where the person is. Profiel must light up there.
- Every page opens a list with a GET request. Uitloggen is an action (it ends the session with DELETE), so a host cannot make it a tile or a hub-column item. The only sign-out appkit offers is the button inside the account pop-up.
- `_nav` always ends the rail with the account pop-up (`_account_menu`, a `<details>` with the user's name), and `Appkit::Menu` requires `account:` links. A host cannot drop the pop-up. The rail item shows the full user name over four lines and no emoji.
- The origin (`from=<hub>`) names only a hub. A record opened from a list that combines several pages (Journal's Alles) goes back to the page that owns the record's controller, not to the list the person came from.

## Proposed outcome

A host builds an account hub from the same parts as every other hub. A hub can sit under a parent hub: it has no rail item, and the rail marks the parent while it is current. A page can be a submit page: its tile and hub-column item send that request (Uitloggen signs out at once), and they look like every other tile and item. The rail has no account pop-up. A record opened from a list returns to that list, also when the list is not the page that owns the record.

## Affected users and systems

- Journal Administration, the only app that uses `Appkit::Menu` today. Its navigation-hubs branch waits for this change before it bumps appkit (phase E2 of its plan).
- sticker-app pins appkit `d837929`, from before `Appkit::Menu`, and does not use the menu map. It is not affected until it upgrades, and then the `### Upgrading` steps apply.
- mvpa.css styles the tiles as `main nav:not(header nav) > ul > li > a` and the hub column as `nav.rail + nav`. The account pop-up CSS (#54) and the phone bar rule that hides `li:has(> details)` become unused; their cleanup is a separate, non-blocking mvpa.css change.

## Constraints

- Approved permissions: none. Any new gem, package, migration, system tool or deploy file is a stop-and-ask.
- The markup of tiles and hub-column items stays `li > a`, so mvpa.css needs no change for this to look right.
- Removing `account:`, `rail:`, `_account_menu` and the `user_name` local breaks hosts: the CHANGELOG `## Unreleased` entry gets `### Upgrading` steps, one per action, as `AGENTS.md` says.
- Inline RBS signatures, `rbs:check` and Steep stay green.

## In scope

- A hub can name a parent hub. It then has no rail item, and while it is current the rail marks the parent. The map refuses a parent that names no hub, and a parent that has a parent itself.
- A hub's pages can include a submit page (such as Uitloggen) that sends a non-GET request. Its tile and hub-column item look and sit like the others. It has no count, no badge, no filter and no controllers of its own.
- Search (🔍, `Menu#links`) leaves submit pages out and lists each path once.
- The rail no longer holds the account pop-up. `_account_menu` and its `avatar:` option go, `Appkit::Menu` takes no `account:`, and `_nav` takes no `user_name`.
- An origin can name the list a flow started from, so a record opened from that list returns to it after show, edit, save or cancel.
- `### Upgrading` steps in `CHANGELOG.md`, the dummy app and `test/types/host_probe.rb` updated.

## Out of scope

- The mvpa.css cleanup of the pop-up CSS and the phone bar rule (separate change, does not block).
- Journal's own Profiel hub, Consolideren, Importeren and Alles pages (its navigation-hubs branch, phases E1 and E2).
- A confirmation before sign-out.
- Hubs nested deeper than one parent level.

## Acceptance criteria

- With Beheer declared under Profiel, a Beheer page marks Profiel as current in the rail, and the rail lists no Beheer item.
- A map in which Beheer names a parent hub that does not exist, or a parent that has a parent itself, refuses to build.
- The Profiel landing page shows an Uitloggen tile last; clicking it ends the session and shows the sign-in page.
- The Profiel hub column shows Uitloggen as its last item, with no badge; clicking it ends the session and shows the sign-in page.
- The Uitloggen tile and hub-column item are links (`li > a`), like Gegevens and Voorkeuren.
- On a Beheer page the hub column shows Beheer's own pages, not Profiel's.
- Searching for "Uitloggen" finds nothing; searching for "Voorkeuren" finds it once.
- The rail holds no pop-up: no `<details>` and no user name.
- A record opened from a list that combines several pages (Journal's Alles), then edited and saved, returns to that list; the same record opened from its own page (Consolideren) returns to that page.

## Decisions

- Deliver autonomously, no Codex review — same flow as navigation-hubs, fewest tokens.
- Remove the account pop-up for good — one way to build an account hub, less code to keep; only Journal uses `Appkit::Menu`.
- Leave submit pages out of search — a search result never signs out by accident.
- Approve no extra permissions — the change touches only Ruby, ERB, locales, tests, signatures and CHANGELOG.
- Name the terms Parent hub, Submit page and List origin — "action" stays free for the hub's title-bar action, which already uses that word.

## Open questions

None.
