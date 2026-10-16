# Browser evidence: delete confirmation dialog

Date: 2026-10-16.
Browser: headless Google Chrome 155.0.8059.85, driven by selenium-webdriver (from the journal_administration bundle), locale nl.
HTML source: the real output of `delete_confirmation_opener("delete-dialog")` and `render "appkit/shared/delete_confirmation", id: "delete-dialog", url: "/things/1", title: "Verwijder ding?"`, rendered in the dummy app. Nothing is hand-written.
Page: the opener sits inside a `<form>` with a text input and a submit "Opslaan". The dialog sits outside that form. A capture-phase `submit` listener records the form action and `_method` in `window.__submitted` and calls `preventDefault`. The `dialog` method forms are ignored by the listener.
Two mvpa-css revisions were tested: 77697d4 (the revision the journal app bumps to) and 412cc74 (the revision locked in appkit's `Gemfile.lock`).

## Results with mvpa-css 77697d4

- (a) Click "Verwijderen…": `dialog.open` is true, `:modal` matches, the focused element is "Annuleren" (Cancel).
- (b) Press Return: the dialog closes and `window.__submitted` is empty.
- (c) Reopen (it opened again), press Esc: the dialog closes and `window.__submitted` is empty.
- (d) Reopen, click the red "Verwijderen": one submit is recorded, action `/things/1`, `_method` `delete`.
- (e) Computed background colours: opener `oklch(0.5303 0.1989 26.57)` (red), Delete `oklch(0.5303 0.1989 26.57)` (red), Cancel `oklch(0.5241 0.1709 254.71)` (the filled default blue, the same as the "Opslaan" submit).
- (e) Layout: Cancel spans x 399 to 525, Delete spans x 535 to 673, both at top 320. Delete sits right of Cancel on one row.

## Results with mvpa-css 412cc74 (appkit's locked revision)

- (a) to (d) give the same results as above: the dialog opens modally with Cancel focused, Return and Esc submit nothing, Delete records `/things/1` with `delete`.
- (e) Colours are the same as above.
- (e) FAILS for layout: Cancel is at x 39 to 163, top 210. Delete is at x 39 to 175, top 294. Delete is below Cancel, not right of it.
- Cause: revision 412cc74 has no `dialog` or `dialog > footer` rules. Revision 77697d4 adds them. The "Delete is rightmost" claim holds only from 77697d4 on.

## Not exercised

- The invoker fallback path. Chrome 155 supports Invoker Commands natively (`"commandForElement" in HTMLButtonElement.prototype` is true), so the `invoker` Stimulus controller did not run. No Stimulus was loaded on the page.
- Turbo: the page has no Turbo, so `data-turbo-frame="_top"` and a real DELETE request were not exercised. The submit was intercepted before sending.
- Other browsers (Safari, Firefox) and the eink themes.
- The `_confirm_dialog` partial.
