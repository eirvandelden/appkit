module Semver
  # The Findings of one diff.
  class Findings
    include Enumerable

    #: (Array[Finding]) -> void
    def initialize(list)
      @list = list
    end

    #: () { (Finding) -> void } -> void
    def each(&)
      @list.each(&)
    end

    #: () -> Level
    def floor
      (map(&:level) + [ Level::PATCH ]).max
    end

    #: (declared: Level, ?overrides: Hash[String, String]) -> Array[Finding]
    def unmet(declared:, overrides: {})
      reject { |finding| overrides.key?(finding.rule) }.select { |finding| finding.level > declared }
    end
  end
end
