module Semver
  # A semver number.
  class Version
    include Comparable

    PATTERN = /\A(\d+)\.(\d+)\.(\d+)\z/ #: Regexp

    #: (String) -> Version
    def self.parse(text)
      match = PATTERN.match(text.to_s.strip)
      raise ArgumentError, "not a semver version: #{text.inspect}" unless match

      new(*match.captures.map(&:to_i))
    end

    #: (Integer, Integer, Integer) -> void
    def initialize(major, minor, patch)
      @parts = [ major, minor, patch ]
    end

    #: (Level) -> Version
    def bump(level)
      major, minor, patch = @parts
      case level.to_s
      when "major" then self.class.new(major + 1, 0, 0)
      when "minor" then self.class.new(major, minor + 1, 0)
      else self.class.new(major, minor, patch + 1)
      end
    end

    #: (Version) -> Integer?
    def <=>(other)
      return unless other.is_a?(Version)

      parts <=> other.parts
    end

    #: () -> String
    def to_s
      @parts.join(".")
    end

    #: () -> String
    def tag
      to_s
    end

    #: () -> String
    def major_tag
      @parts.first.to_s
    end

    #: () -> Integer
    def major
      @parts.first
    end

    #: (untyped) -> bool
    def eql?(other)
      other.is_a?(Version) && parts == other.parts
    end

    #: () -> Integer
    def hash
      parts.hash
    end

    protected

    attr_reader :parts #: Array[Integer]
  end
end
