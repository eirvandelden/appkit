# Glossary

- **List origin** — an origin that also names the list a flow started from, such as Alles; a record opened from that list returns to it.
- **Parent hub** — the rail hub that the rail marks while a hub without a rail item of its own is current, such as Profiel for Beheer.
- **Submit page** — a page whose tile and hub-column item send one non-GET request, such as Uitloggen; it owns no controller, has no count, badge or filter, and search leaves it out. Avoid: action page.
- **Fragment** — a file `changelog.d/<branch-slug>.md` that one change adds; its front matter declares the release `level` and its body holds the changelog lines. The release run turns all pending fragments into one version.
- **Level** — how much a change affects apps: `major` (breaking, apps must act), `minor` (opt-in feature) or `patch` (bug or security fix). The highest level among pending fragments decides the next version. Avoid: severity, bump size.
- **Floor** — the lowest level that a diff of the public surface allows; a fragment may declare a higher level, never a lower one.
- **Public surface** — everything an app can depend on: migration templates, generator templates, config options, routes, RBS signatures, the gemspec, the reusable workflow, importmap pins and locale keys.
- **Override** — an entry in a fragment's `overrides` that lets a change pass below a rule's floor, with a written reason; the check shows the reason.
- **Last release** — the newest `X.Y.Z` tag reachable from `main`; the next version is this one bumped by the pending level.
