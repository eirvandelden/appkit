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

## Shared confirm dialog (mvpa-css 77697d4, Chrome 155)

Setup: the real `appkit/shared/_confirm_dialog` partial, rendered in the dummy app with locale nl. The dummy app has no `common.cancel` or `common.delete` keys, so I supplied the journal app's nl values (`Annuleren`, `Verwijderen`) at render time. The `Turbo.config.drive.confirmationMethod` function was copied verbatim from the journal app's `application.js` (lines 6 to 31) and exposed as `window.confirmationMethod`. The script calls `await confirmationMethod("Weet je het zeker?", trigger)`, where the trigger has `data-confirm-verb="Verwijderen"`. The page is served over http on 127.0.0.1.

- Cancel has focus when the dialog opens (`document.activeElement.id` is `confirm-dialog-cancel`). The dialog is modal.
- The message is "Weet je het zeker?". The confirm button label is "Verwijderen", the confirm verb.
- Cancel background is `oklch(0.5241 0.1709 254.71)`, equal to a plain "Opslaan" submit button on the same page (filled default).
- The confirm button background is `oklch(0.5303 0.1989 26.57)` (red).
- Cancel spans x 399 to 525 and the confirm button spans x 535 to 673, both at top 285. The confirm button is right of Cancel.
- Click Cancel: the promise resolves false and the dialog closes. The URL is unchanged and no other submit is recorded.
- Return: resolves false, the dialog closes.
- Esc: resolves false, the dialog closes.
- Click the confirm button: resolves true, the dialog closes.
- The confirm function only resolves the promise. The page did not submit anything and did not navigate.

## Invoker fallback path (mvpa-css 77697d4)

The fallback branch of `invoker_controller.js` was NOT exercised. Chrome 155 cannot turn Invoker Commands off.

- I tried `--disable-blink-features` with `HTMLInvokeTargetAttribute`, `HTMLCommandAttributes`, `HTMLInvokerCommands`, `CommandAttributes` and `InvokerCommands`. I also tried `--disable-features` with `HTMLInvokeTargetAttribute`, `InvokerCommands` and `HTMLCommandAttributes`. In every run `"commandForElement" in HTMLButtonElement.prototype` stayed true.
- The Chrome binary has no runtime feature name for Invoker Commands (the feature has shipped, so its flag is gone). Only `HTMLCommandElementRemoval`, `HTMLCommandActionsV2` and `HTMLCommandForScrollCommands` exist, and these are unrelated.
- Every browser on this machine supports Invoker Commands: Chrome 155, Chrome for Testing 143 to 150, Edge 155, Firefox 149 and Safari 27. No older engine was available, and I did not delete prototype properties to fake it.

What I did run: the first page again, plus Stimulus (the vendored `stimulus.js` from stimulus-rails 1.3.4) with the real `invoker_controller.js` registered as `invoker`. Native Invoker Commands stayed on, so the controller returns early.

- (a) Click "Verwijderen…": the dialog is modal and "Annuleren" has focus.
- (b) Return: the dialog closes and nothing is submitted.
- (c) Reopen, Esc: the dialog closes and nothing is submitted.
- (d) Reopen, click Delete: one submit, action `/things/1`, `_method` `delete`.
- So the controller loads without breaking the native path. It does not double-open or throw.

## Not exercised

- The invoker fallback branch (`showModal`/`close` called by the controller). No browser here lacks Invoker Commands, and no flag turns the feature off. See above.
- Turbo: the page has no Turbo, so `data-turbo-frame="_top"`, Turbo's own call to `confirmationMethod` and a real DELETE request were not exercised. Submits were intercepted before sending.
- Other browsers' behaviour was not compared. Only Chrome 155 ran the checks.
- The eink themes.
