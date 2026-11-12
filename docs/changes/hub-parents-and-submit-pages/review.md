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

## Round 2 — 2026-11-12 14:24 UTC — 0b2c11b (claude)

Scope: `git diff origin/main...HEAD` at `0b2c11b`, 39 files, no uncommitted changes. 279 tests pass with 0 failures. RuboCop, erb_lint, `rbs:check` and Steep pass. All five round-1 closures hold in the code: the nav tests are indented, `parent is stored` exists, the plan signs `Hub#page` with `Symbol | String`, `carry_list` uses only `placement`, and `menu_entry_to` refuses a missing block.
- [ ] Important: A submit page's `data-turbo-method` link needs a CSRF token from `<%= csrf_meta_tags %>` in the layout. Turbo reads the token from that meta tag for a non-GET request. The removed `button_to` embedded the token itself. A host layout without the tag gets a 422 `InvalidAuthenticityToken` on sign-out. Upgrading step 17 does not name this requirement. The dummy layout has no `csrf_meta_tags` either, and `allow_forgery_protection = false` in the test environment hides the failure. — `CHANGELOG.md:47` → fixed (Require the CSRF meta tag for submit pages)
- [ ] Nit: The blank line between `def hub … end` and `def page` is removed. The task does not need this whitespace change, and the other helper methods have a blank line between them. — `test/models/appkit/menu_test.rb:311` → fixed (Name the carry_list test after what it proves)
- [ ] Nit: The test name `carry_list names the current page in the origin hub` no longer describes the code. After the round-1 fix, `carry_list` always names the current hub and ignores the origin. The test passes only because the current hub is also the origin hub. — `test/models/appkit/menu_test.rb:257` → fixed (Name the carry_list test after what it proves)

## Round 3 — 2026-11-12 14:38 UTC — 8548752 (claude)

Scope: `git diff origin/main...HEAD` at `8548752`, 39 files; the only uncommitted change is `review.md`. RuboCop, erb_lint, `rbs:check` and Steep pass. One full test run reported 1 error out of 280 runs. Seven more runs all passed with 0 errors, so the cause is unknown. All round-1 and round-2 closures hold in the code: Upgrading step 17 and the dummy layout name `csrf_meta_tags`, a test proves the token, the blank line is back in `menu_test.rb`, and the plan's Proof lists the renamed `carry_list` test.
- [ ] Nit: The new test `the sign-out link sends the page's CSRF token, as Turbo does` starts at column 0, not at the class indentation. Round 1 fixed the same problem in `nav_test.rb`, and RuboCop does not flag it — `test/integration/sign_out_entry_test.rb:36` → fixed (Indent the CSRF test and restore forgery protection as it was)
- [ ] Nit: `with_forgery_protection` sets `ActionController::Base.allow_forgery_protection` back to a hard-coded `false`, not to the value it had before. Save the old value and restore it in `ensure`, so the helper does not depend on `config/environments/test.rb` — `test/integration/sign_out_entry_test.rb:53` → fixed (Indent the CSRF test and restore forgery protection as it was)

Coordinator note on the one test error: three further sequential full runs at the fix commit passed (280 runs, 0 errors, 0 failures). The test database is in memory and tests run serially; the reviewer ran the suite while the coordinator ran it in the same worktree, so a shared tmp cache is the likely cause, not verified.

## Round 4 — 2026-11-12 14:43 UTC — aa3e0a8 (claude)

Scope: `git diff origin/main...HEAD` at `aa3e0a8`, 39 files; the only uncommitted change is `review.md`. The test suite was not run, as instructed. All round-1, round-2 and round-3 closures hold in the code: the CSRF test is indented, `with_forgery_protection` restores the saved value in `ensure`, `csrf_meta_tags` is in the dummy layout and in Upgrading step 17, and every test named in the plan's Proof exists.
- [ ] Nit: `Appkit::Menu` grows from about 143 to 219 lines, past the playbook's ~100-line class target. Origin parsing (`origin_parts`, `parse_origin`, `list_page`, `list_key`) is a candidate for its own small value object in a later change — `app/models/appkit/menu.rb:3` → fixed (Parse the from value in Appkit::Menu::Origin)

## Round 5 — 2026-11-12 14:46 UTC — eb03cbc (claude)

Scope: `git diff origin/main...HEAD` at `eb03cbc`, 42 files. The only uncommitted change is `review.md`. The test suite was not run, as instructed. All closures from rounds 1 to 4 hold in the code. `Appkit::Menu::Origin` holds the origin parsing, and its six unit tests named in the plan's Proof exist. The Origin parsing still turns an unknown or submit page into a hub origin and an unknown hub into nil. No avoided glossary word appears in the diff.
- [ ] Nit: The plan's `### Signatures` and the "After" class diagram do not sign `Appkit::Menu::Origin`. Its public `Origin.parse`, `#initialize`, `#hub`, `#page` and `#key` appear only in `## Files that change`. Add the signed class and its link from `Menu` to the plan — `app/models/appkit/menu/origin.rb:12` → fixed (docs: sign Appkit::Menu::Origin and the Menu size in the plan)
- [ ] Nit: The plan says that `Origin` keeps `Menu` "near its size target". `Appkit::Menu` is still 196 lines, about twice the ~100-line class target. Correct the plan text, or record the remaining size as a known exception — `docs/changes/hub-parents-and-submit-pages/plan.md:255` → fixed (docs: sign Appkit::Menu::Origin and the Menu size in the plan)

## Round 6 — 2026-11-12 14:50 UTC — 954f85e (claude)

Scope: `git diff origin/main...HEAD` at `954f85e`, 42 files. The only uncommitted change is `review.md`. The test suite was not run, as instructed. All closures from rounds 1 to 5 still hold in the code. The plan signs `Appkit::Menu::Origin`, its "After" diagram shows it, and its known-exception line on the Menu size is correct (118 code lines now, 98 at `709fcac`). Every test that the plan's Proof names exists. turbo-rails 2.0.23's `engine.rb` adds no importmap pin, so Upgrading step 17 is correct. No glossary word marked "Avoid:" appears outside `GLOSSARY.md`.
- [ ] Nit: The plan's "After" class diagram still shows `Hub` with `+page(Symbol) Page?`, but `### Signatures` and the code take `(Symbol | String)`. Round 1 updated the signature but not the diagram — `docs/changes/hub-parents-and-submit-pages/plan.md:76` → fixed (docs: show Hub#page with a String key in the plan diagram)

## Round 7 — 2026-11-12 14:52 UTC — 08fb9e4 (claude)

Scope: `git diff origin/main...HEAD` at `08fb9e4`, 42 files. The only uncommitted change is `review.md`. I did not run the test suite, as instructed. RuboCop passes on the 22 changed Ruby files, and erb_lint passes on the 8 changed ERB files. Every closure from rounds 1 to 6 still holds. The plan's "After" diagram now shows `page(Symbol or String)`. Each acceptance criterion maps to an existing test, and every test that the plan's Proof names exists. No old reference to `account:`, `rail: false`, `user_name` or `_account_menu` is left outside the CHANGELOG Upgrading steps and the change docs. No word that the glossary marks "Avoid:" appears outside `GLOSSARY.md`.
No findings.
