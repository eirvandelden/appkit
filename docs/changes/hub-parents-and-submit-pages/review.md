# Review: hub-parents-and-submit-pages

## Round 1 — 2026-11-12 14:19 UTC — 8f650c0 (claude)

Scope: `git diff origin/main...HEAD` at `8f650c0`, 38 files, no uncommitted changes. All checks are green: 277 tests with 0 failures, RuboCop, erb_lint, `rbs:check` and Steep.

**Compliance**

Acceptance criteria:
- Beheer under Profiel marks Profiel in the rail, and the rail lists no Beheer item: `test/integration/nav_current_page_test.rb` `a page of a hub under a parent marks the parent in the rail` and `a landing page of a hub under a parent marks the parent in the rail`.
- A missing or nested parent refuses to build: `test/models/appkit/menu_test.rb` `a parent that names no hub raises` and `a parent that has a parent raises`.
- The Uitloggen tile is last and signs out: `test/integration/sign_out_entry_test.rb` `the sign-out tile is last and signs out` and `the nav page loads Turbo`. A request test proves this, not a click. Journal's system tests must prove the real click (plan, Risks).
- The Uitloggen hub-column item is last, has no badge and signs out: `test/integration/sign_out_entry_test.rb` `the sign-out hub-column item is last and signs out`.
- The tile and the hub-column item are `li > a`: `sign_out_entry_test.rb` (both tests above) and `test/helpers/appkit/menu_helper_test.rb` `a submit page renders a link with data-turbo-method`.
- A Beheer page shows Beheer's own pages in the hub column: `nav_current_page_test.rb` `a page of a hub under a parent marks the parent in the rail`.
- Search finds no Uitloggen and lists Voorkeuren once: `menu_test.rb` `links skips submit pages and lists each path once`.
- The rail holds no pop-up: `nav_current_page_test.rb` `the rail holds no account pop-up` and `test/helpers/appkit/nav_test.rb` `nav renders no account pop-up`.
- A record from the combined list returns to that list, and a record from its own page returns to that page: `test/integration/origin_flow_test.rb`:
  - `a record opened from a combined list returns to it after edit and save`
  - `a record opened from a combined list in the hub column returns to it`
  - `a record opened from its own page returns to that page after edit and save`
  - `cancel on the edit form keeps the list origin`

Plan Proof tests:
- `page_test.rb`: all 5 named tests exist.
- `menu_test.rb`: all 18 named tests exist.
- `menu_helper_test.rb`: all 3 exist.
- `nav_test.rb`: all 3 exist.
- `nav_queries_test.rb` `a hub with only uncounted pages runs no count`: exists.
- `hub_test.rb`: `rail? is true without a parent`, `rail? is false with a parent` and `page returns its page by key, nil otherwise` exist. `parent is stored` is **missing**: its assertions sit inside the two `rail?` tests.
- `rbs:check` and `steep` pass.
- No existing test is weakened, skipped or deleted. The removed account-menu tests went with the removed feature. The `from=work`: `from=work.admin` change follows the plan.

**Findings**

- [ ] Nit: Two new tests and `private` start at column 0 instead of the class indentation. RuboCop does not flag this — `test/helpers/appkit/nav_test.rb:75` → fixed (Indent the new nav tests and name the parent test)
- [ ] Nit: The plan names a unit test `parent is stored`, but no test has that name. Its assertions are folded into `rail? is true without a parent` and `rail? is false with a parent` — `test/models/appkit/menu/hub_test.rb:43` → fixed (Indent the new nav tests and name the parent test)
- [ ] Nit: `Hub#page` is signed `(Symbol | String) -> Page?`, but the plan's `### Signatures` signs it as `(Symbol) -> Page?`. Update the plan or narrow the method — `app/models/appkit/menu/hub.rb:66` → fixed (docs: sign Hub#page, carry_list and the Turbo pin as built)
- [ ] Nit: In `carry_list`, `origin_hub.pages.include?(page)` is true only when that hub holds the same Page instance as the hub from `placement`. With one Page instance per hub, `list_hub` is always the current hub, so the origin branch has no effect. The test `carry_list names the current page in the origin hub` passes through the current hub. Remove the branch or test it with a shared page — `app/models/appkit/menu.rb:79` → fixed (Write the current hub and page in carry_list)
- [ ] Nit: `menu_entry_to` called without a block becomes `link_to(path, options)`. Rails then treats the options hash as the URL, so the link shows the path as text and points at the current page. Only the signature requires the block; a host without Steep gets no error. Guard the call or reject a missing block — `app/helpers/appkit/menu_helper.rb:67` → fixed (Refuse menu_entry_to without a block)
There are no Important findings. One suspected bug proved wrong: the sign-out link sends DELETE and `destroy` redirects with a 302. turbo-rails' `encodeMethodIntoRequestBody` sends the DELETE as POST with `_method`, so the redirect becomes a GET. Upgrading step 17's explicit importmap pin is also correct: turbo-rails 2.0.23 adds that pin only through its installer, not automatically.
