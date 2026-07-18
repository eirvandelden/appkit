# Appkit

A non-isolated Rails engine bundling session-based authentication, PWA
installability with web push notifications, and theme/preferences
management for host Rails applications.

Appkit requires [`mvpa-css`](https://github.com/eirvandelden/mvpa.css) as
a co-gem for its themed UI components. `mvpa-css` is not declared in
`appkit.gemspec` — gemspecs cannot declare git-sourced dependencies, so
it is declared in this repo's `Gemfile` instead. Consuming apps must add
`mvpa-css` to their own `Gemfile` as well.

The engine is deliberately **not** `isolate_namespace`d: host apps' URL
helpers (`root_url`, etc.) need to work from inside engine controllers
and views.

## Installation

```ruby
gem "appkit", github: "eirvandelden/appkit"
gem "mvpa-css", github: "eirvandelden/mvpa.css"
```

Further installation and configuration steps (PWA/push, theme) will be
documented as those features land in later tasks.

Host apps should add this one-line directive to their own
`ApplicationController` — it's not part of the engine itself:

```ruby
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges,
  # import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
```

## Status

Session-based authentication (login, FirstRun bootstrap, session
transfer/QR handoff), VersionHeaders, Authorization, and static error
pages are implemented. PWA/push and theme/preferences features are not
yet built.

## Third-party notices

Some of appkit's auth code is adapted from Basecamp's
[Writebook](https://github.com/basecamp/writebook) (MIT license). See
`THIRD_PARTY_NOTICES.md` for details.
