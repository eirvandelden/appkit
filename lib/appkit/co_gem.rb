module Appkit
  # Raised at boot when a co-gem is missing from the host app's bundle.
  class MissingCoGem < StandardError; end

  # A gem that appkit needs at runtime but that each host app declares in its own Gemfile.
  class CoGem
    #: (name: String, github: String) -> void
    def initialize(name:, github:)
      @name = name
      @github = github
    end

    # Loads the co-gem, or raises MissingCoGem with the Gemfile line to add.
    #: () -> void
    def ensure_loaded
      require name
    rescue LoadError => error
      raise unless error.path == name

      raise MissingCoGem, missing_message
    end

    private
      attr_reader :name #: String
      attr_reader :github #: String

      #: () -> String
      def missing_message
        "appkit needs the #{name} gem, but the bundle does not have it. " \
          "Add this line to the Gemfile and run bundle install:\n\n  #{gemfile_line}"
      end

      #: () -> String
      def gemfile_line
        %(gem "#{name}", github: "#{github}")
      end
  end
end
