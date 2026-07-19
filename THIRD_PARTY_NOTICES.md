# Third-Party Notices

This project adapts portions of its code from
[basecamp/writebook](https://github.com/basecamp/writebook), which is
MIT-licensed.

The following files are adapted (ported and generalized/namespaced under
`Appkit::`) from Writebook:

- `app/models/appkit/first_run.rb` and `app/controllers/appkit/first_runs_controller.rb`
  (adapted from `app/models/first_run.rb` and `app/controllers/first_runs_controller.rb`)
- `app/models/appkit/qr_code_link.rb` (ported near-verbatim from `app/models/qr_code_link.rb`)
- `app/controllers/appkit/qr_code_controller.rb` (ported near-verbatim from
  `app/controllers/qr_code_controller.rb`)
- `app/controllers/concerns/appkit/version_headers.rb` (ported verbatim from
  `app/controllers/concerns/version_headers.rb`)
- `app/models/concerns/appkit/authorization.rb` (ported verbatim from
  `app/models/concerns/authorization.rb`)
- `app/helpers/appkit/forms_helper.rb` (ported near-verbatim from `app/helpers/forms_helper.rb`)
- `app/javascript/appkit/controllers/auto_submit_controller.js` (ported verbatim from
  Writebook's `app/javascript/controllers/auto_submit_controller.js`)
- `app/views/appkit/sessions/transfers/show.html.erb` (adapted from
  `app/views/sessions/transfers/show.html.erb`)
- `lib/generators/appkit/install/templates/public/404.html`,
  `406-unsupported-browser.html`, `422.html`, `500.html`, `502.html`
  (adapted from Writebook's static `public/*.html` error pages, restyled with
  mvpa-css's Solunized color tokens; text genericized where it referenced
  "Writebook" by name)

The MIT license text below applies to the above files:

```
Copyright (c) 37signals, LLC

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
