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

Further installation and configuration steps (auth, PWA/push, theme)
will be documented as those features land in later tasks.

## Status

This is scaffolding only — no auth, PWA/push, or theme features yet.
