module Semver
  # An ordered bump level.
  class Level
    include Comparable

    NAMES = %w[patch minor major].freeze #: Array[String]

    #: (String | Level) -> Level
    def self.parse(name)
      return name if name.is_a?(Level)
      raise ArgumentError,
"unknown level #{name.inspect}, expected one of #{NAMES.join(', ')}" unless NAMES.include?(name)

      new(name)
    end

    #: (String) -> void
    def initialize(name)
      @name = name
    end

    #: (Level) -> Integer?
    def <=>(other)
      return unless other.is_a?(Level)

      NAMES.index(to_s) <=> NAMES.index(other.to_s)
    end

    #: () -> String
    def to_s
      @name
    end

    PATCH = parse("patch") #: Level
    MINOR = parse("minor") #: Level
    MAJOR = parse("major") #: Level
  end
end
