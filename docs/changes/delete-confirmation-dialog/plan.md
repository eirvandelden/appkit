# Plan: Delete confirmation dialog

From `intent.md` (2026-10-15). Status: accepted.

## Context

This plan is phase A of journal_administration's accepted plan `docs/changes/adopt-mvpa-button-hierarchy/plan.md` (branch `adopt-mvpa-button-hierarchy`, accepted through a Codex critique, decisions recorded by Etienne on 2026-10-15). The sections below are copied from it unchanged. Only phase A applies in this repository. Binding specification: `git -C ~/Developer/dotfiles show origin/rails-ui-action-row-and-tables:claude/.claude/skills/rails-ui/references/interaction-design.md`.

## Design decisions

2. **appkit API for the confirmation.** appkit gets two pieces, because the opener sits inside the edit `<form>` and the `<dialog>` must sit outside it (no nested forms):
   - Helper `Appkit::DeleteConfirmationHelper#delete_confirmation_opener(dialog_id)`. It renders `<button type="button" class="button-danger" command="show-modal" commandfor="<dialog_id>" data-controller="invoker" data-action="invoker#invoke">` with the label `t("appkit.delete_confirmation.open")` (`Delete…`).
   - Partial `appkit/shared/_delete_confirmation.html.erb`, locals `(id:, url:, title:)`. It renders `<dialog id aria-labelledby>` with an `<h2>` title, a `<p>` with `t("appkit.delete_confirmation.irreversible")`, and a `<footer>` holding `<form method="dialog"><button autofocus>Cancel</button></form>` and then `button_to t("appkit.delete_confirmation.confirm"), url, method: :delete, form: { data: { turbo_frame: "_top" } }`. This is the exact mvpa.css demo structure: Cancel is a filled submit and the Return default; the DELETE form's button is red and rightmost.
   - Stimulus controller `appkit/controllers/invoker_controller.js`, pinned in appkit's `config/importmap.rb`. `invoke()` returns at once when the browser supports Invoker Commands (`"commandForElement" in HTMLButtonElement.prototype`); otherwise it calls `showModal()` or `close()` on the element named by `commandfor`, per `command`. The app registers it as `invoker` in `app/javascript/controllers/index.js`, like `auto-submit`.
   - Locale keys in `config/locales/appkit.{en,nl,it}.yml` under `appkit.delete_confirmation`: `open` (`Delete…` / `Verwijderen…` / `Elimina…`), `confirm` (`Delete` / `Verwijderen` / `Elimina`), `cancel` (`Cancel` / `Annuleren` / `Annulla`), `irreversible` (`This cannot be undone.` / `Dit kan niet ongedaan worden gemaakt.` / `Questa azione non può essere annullata.`). The partial uses appkit's own `cancel` key, so it does not depend on a host app's `common.cancel`.
3. **appkit `_confirm_dialog` too.** The shared `data-turbo-confirm` dialog stays for the inline deletes that keep it (household members, transaction splits, receipt unlink). Its `<nav>` becomes a `<footer>`, so mvpa.css lays it out as `Cancel | Delete`; its Cancel becomes `<form method="dialog"><button id="confirm-dialog-cancel" autofocus>`, so it stays filled under #41. Element ids stay, so the app's `Turbo.config.drive.confirmationMethod` in `app/javascript/application.js` keeps working unchanged.

## Files that change

- `app/helpers/appkit/delete_confirmation_helper.rb` — new, the opener helper.
- `app/views/appkit/shared/_delete_confirmation.html.erb` — new, the dialog.
- `app/views/appkit/shared/_confirm_dialog.html.erb` — `<nav>` to `<footer>`, Cancel in a `<form method="dialog">`.
- `app/javascript/appkit/controllers/invoker_controller.js` — new, the fallback.
- `config/importmap.rb` — pin the controller.
- `config/locales/appkit.{en,nl,it}.yml` — `appkit.delete_confirmation.*`.
- `test/helpers/appkit/delete_confirmation_helper_test.rb` — new.
- `README.md`, `CHANGELOG.md` — usage and an Upgrading note (register `invoker`).

## Order of work

The worktree already exists (`.worktrees/delete-confirmation-dialog`).

1. Write `test/helpers/appkit/delete_confirmation_helper_test.rb` for the opener and the partial; run it, watch it fail.
2. Add the helper, partial, locales; green. Then the `_confirm_dialog` change with its test, then the controller and pin.
3. Run appkit's tests and linters (`bin/rails test`, `bundle exec rubocop`, Brakeman, Bundler Audit as its lefthook runs them). Commit, push.

The coordinator runs review and `deliver` for this branch.

## Proof

- appkit `app/helpers/appkit/delete_confirmation_helper.rb`: `delete_confirmation_opener renders a red type=button naming its dialog`, `opener label is translated with an ellipsis`.
- appkit `app/views/appkit/shared/_delete_confirmation.html.erb`: `dialog footer holds Cancel then a DELETE form`, `Cancel carries autofocus in a method=dialog form`, `title labels the dialog`.
- appkit `app/views/appkit/shared/_confirm_dialog.html.erb`: `confirm dialog keeps its ids inside a footer`.
