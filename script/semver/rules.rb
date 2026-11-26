module Semver
  # The repo-specific rule list: the public surface of appkit, as CLAUDE.md "Upgrade instructions" lists it.
  module Rules
    TEMPLATES = "lib/generators/appkit/install/templates" #: String

    CONFIG_ADDED = ->(_key, value) { value == "has_default" ? Level::MINOR : Level::MAJOR } #: Proc
    WORKFLOW_ADDED = lambda do |key, value|
      return Level::MINOR if key.start_with?("inputtype:")

      key.start_with?("input:") && value == "optional" ? Level::MINOR : Level::MAJOR
    end #: Proc

    #: (String, String, Proc, Level?, Level?, Level?) -> Rule
    def self.build(id, glob, parser, added, removed, changed)
      Rule.new(id: id, glob: glob, parser: parser, added: added, removed: removed, changed: changed)
    end

    ALL = [
      build("migrations", "#{TEMPLATES}/*.rb.tt", Parsers.method(:template_files).to_proc, Level::MAJOR, Level::MAJOR, Level::MAJOR),
      build("templates", "#{TEMPLATES}/{public,github}/**/*", Parsers.method(:template_files).to_proc,
            Level::MINOR, Level::MAJOR, Level::PATCH),
      build("config", "lib/appkit/configuration.rb", Parsers.method(:config_options).to_proc, CONFIG_ADDED,
Level::MAJOR, nil),
      build("routes", "config/routes.rb", Parsers.method(:routes).to_proc, Level::MINOR, Level::MAJOR, Level::MAJOR),
      build("rbs", "sig/**/*.rbs", Parsers.method(:rbs).to_proc, Level::MINOR, Level::MAJOR, Level::MAJOR),
      build("gemspec", "appkit.gemspec", Parsers.method(:gemspec_runtime).to_proc, Level::MAJOR, Level::MINOR, Level::MAJOR),
      build("workflow", ".github/workflows/rails-ci.yml", Parsers.method(:workflow_inputs).to_proc,
            WORKFLOW_ADDED, Level::MAJOR, Level::MAJOR),
      build("importmap", "config/importmap.rb", Parsers.method(:importmap_pins).to_proc, Level::MAJOR, Level::MAJOR, Level::PATCH),
      build("locale", "config/locales/*.yml", Parsers.method(:locale_keys).to_proc, Level::PATCH, Level::MAJOR, Level::PATCH)
    ].freeze #: Array[Rule]

    Rule::ALL.replace(ALL)
  end
end
