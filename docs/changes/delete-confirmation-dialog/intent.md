# Intent: Delete confirmation dialog

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-15). Type: feature. Delivery: autonomous.

## Problem

Apps on appkit confirm a delete through the shared `data-turbo-confirm` dialog. It cannot follow the agreed `Cancel | Delete` layout with mvpa.css PR #41: its Cancel is a `type="button"`, so it turns plain, and it sits in a `<nav>`, not an action row. There is no reusable `Delete…` opener and dialog for an edit page.

## Proposed outcome

appkit offers a `Delete…` opener and a confirmation dialog that follow the rails-ui reference `interaction-design.md` (dotfiles PR #194): a filled, autofocused `Cancel` and a red `Delete` rightmost. The shared `data-turbo-confirm` dialog gets the same layout and keeps its element ids.

## Affected users and systems

- Every app on appkit; first journal_administration (change `adopt-mvpa-button-hierarchy`, phase B).

## Constraints

- This is phase A of journal_administration's accepted intent `adopt-mvpa-button-hierarchy` (2026-10-15). That intent and its plan are the source; this file and `plan.md` carry the appkit part.
- No new gems or packages. Translations in en, nl and it.

## In scope

- The opener helper, the dialog partial, the `invoker` fallback controller and its pin, locales, the `_confirm_dialog` layout change, README and CHANGELOG.

## Out of scope

- Any app-side change. Moving `confirmationMethod` into appkit.

## Acceptance criteria

- An edit page that renders the opener shows a red `Verwijderen…` button; clicking it opens the dialog.
- The dialog names the record and says it cannot be undone, with `Annuleren` filled and a red `Verwijderen` to its right.
- Pressing Return or Esc in the dialog closes it and deletes nothing; clicking `Verwijderen` sends the DELETE.
- The shared `data-turbo-confirm` dialog shows `Annuleren` filled and the red confirm button to its right, and an app's existing `confirmationMethod` keeps working.

## Open questions

None.
