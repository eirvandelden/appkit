source "https://gem.coop"

gemspec

# mvpa-css can't be declared in the gemspec: it's sourced from a git branch, and
# gemspecs can't declare git dependencies (RubyGems requires released gem sources
# there). Consuming apps must add this same line to their own Gemfile too.
gem "mvpa-css", github: "eirvandelden/mvpa.css"
