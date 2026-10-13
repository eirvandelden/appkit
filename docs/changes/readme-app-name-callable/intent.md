# Intent: app_name accepts a string, a callable or a translation

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-13). Type: bugfix. Delivery: autonomous.

## Problem

A host app developer who follows the README sets `config.app_name = "My App"`. Every page that shows the app name then crashes with `NoMethodError`: the login layout title, the first-run page, the nav, the sign-in page and the PWA manifest. The engine only works when `app_name` is a callable, and the README never says so. A host app that sets no `app_name` crashes on the same pages, because the documented default is `nil`. The README also says the name appears only in the PWA manifest, which is wrong. A host app also cannot show a different name per locale without writing its own callable.

## Proposed outcome

A host app developer can set `app_name` to a plain string, as the README shows, and every page shows that name. A callable still works. A host app can give a translated name per locale through a top-level `app_name` locale key. A host app that sets nothing shows a name derived from its Rails application module. The README describes the accepted values, the order in which the name is chosen, and every place the name appears.

The name is chosen in this order, for the current request locale:

1. The top-level `app_name` locale key, when the current locale defines it.
2. The configured `app_name`, a string or a callable, when it gives a non-blank name.
3. The host Rails application module name, split into words.

## Affected users and systems

- Host app developers who configure Appkit.
- End users who see the app name on the sign-in page, first-run page, nav, page titles and installed PWA.
- The engine views that render the app name, the configuration, the README, the CHANGELOG and the dummy app initializer.

## Constraints

- Backwards compatible: a host app that passes a callable keeps working unchanged.
- Appkit's own `en`, `nl` and `it` locale files do not define the `app_name` key, so the configured name and the fallback still apply when a host app does not set it.
- Approved permissions for autonomous delivery: none. No new gems or packages, system tools, destructive migrations, deploy files or CI files.

## In scope

- `app_name` accepts a string or a callable.
- A top-level `app_name` locale key in the host app overrides the configured name for that locale.
- A blank configured name (`""`, or a callable that returns `nil` or `""`) counts as unset.
- A fallback name from the host Rails application module when no name is configured.
- The PWA manifest uses the locale of the request that fetched it, like the other pages.
- README: the configuration example and the `app_name` table row (accepted values, the locale key, the order above, the real default, every place the name appears).
- CHANGELOG entry under Unreleased.
- The dummy app initializer sets a plain string.

## Out of scope

- The other configuration options (`user_class`, `session_class`, `user_scope`, `brand_color` and the rest) keep their current types and behaviour.
- README sections other than the configuration example and the `app_name` row.

## Acceptance criteria

- A host app sets `app_name = "My App"`; the sign-in page, first-run page, nav, page title and PWA manifest show "My App".
- A host app sets `app_name = -> { "My App" }`; the same pages show "My App".
- A host app whose application module is `MyRecipeBook` sets no `app_name`; those pages show "My Recipe Book".
- A host app whose application module is `MyRecipeBook` sets `app_name = ""`; those pages show "My Recipe Book".
- A host app whose application module is `MyRecipeBook` sets `app_name = -> { nil }`; those pages show "My Recipe Book".
- A host app sets `app_name = "Recipe Book"` and defines `app_name: "Receptenboek"` in its `nl` locale file only; a Dutch visitor sees "Receptenboek" and an English visitor sees "Recipe Book".
- A Dutch visitor fetches the PWA manifest of that host app; the manifest name is "Receptenboek".
- The README `app_name` row states that a string or a callable is accepted, names the `app_name` locale key, gives the order in which the name is chosen, gives the module-name fallback as the default, and lists every place the name appears.

## Flagged concerns

- A top-level `app_name` locale key can collide with a key a host app already uses for something else; that host app would see its existing translation as the app name. Etienne chose the top-level key over a namespaced `appkit.app_name` key.
- The browser caches the PWA manifest, so an installed app keeps the name of the locale it was installed in. Etienne chose the request locale over a fixed default locale.

## Open questions

None.
