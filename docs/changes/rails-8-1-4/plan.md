Loosen the gemspec's rails constraint only if it blocks 8.1.4, run `bundle update rails --conservative`, then run tests, rubocop, bundler-audit, and brakeman.

Update json to 3.x together with rubocop (1.89 requires `json ~> 2.3`) with `bundle update json rubocop --conservative`, then run the tests, rubocop and bundler-audit on json 3.x.
