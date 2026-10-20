module Appkit
  # Names the installed appkit commit. A Bundler git source knows its full SHA
  # without a .git directory, so this also works in Docker builds that delete it.
  class Revision
    #: (spec: Gem::BasicSpecification?) -> void
    def initialize(spec:)
      @spec = spec
    end

    #: () -> String
    def to_s
      source = @spec&.source
      source.respond_to?(:revision) ? source.revision : VERSION
    end
  end
end
