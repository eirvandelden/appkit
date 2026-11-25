module Semver
  # One surface rule: a glob, a parser and a level per kind of change.
  # A level is a Level, nil (not detected) or a callable (key, value) -> Level?.
  class Rule
    attr_reader :id #: String

    ALL = [] #: Array[Rule]

    #: (id: String, glob: String, parser: Proc, added: untyped, removed: untyped, changed: untyped) -> void
    def initialize(id:, glob:, parser:, added:, removed:, changed:)
      @id = id
      @glob = glob
      @parser = parser
      @levels = { added: added, removed: removed, changed: changed }
    end

    #: (String) -> bool
    def match?(path)
      File.fnmatch?(@glob, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
    end

    #: (path: String, before: String?, after: String?) -> Array[Finding]
    def findings(path:, before:, after:)
      old = facts(before)
      current = facts(after)
      (current.keys - old.keys).filter_map { |key| finding(:added, path, key, current[key]) } +
        (old.keys - current.keys).filter_map { |key| finding(:removed, path, key, old[key]) } +
        (current.keys & old.keys).reject { |key|
 old[key] == current[key] }.filter_map { |key| finding(:changed, path, key, current[key]) }
    end

    private

    def facts(text)
      text ? @parser.call(text) : {}
    end

    def finding(kind, path, key, value)
      level = key.start_with?("unparsed:") ? Level::MAJOR : level_for(kind, key, value)
      Finding.new(rule: id, path: path, level: level, reason: "#{kind} #{key}") if level
    end

    def level_for(kind, key, value)
      spec = @levels.fetch(kind)
      spec.respond_to?(:call) ? spec.call(key, value) : spec
    end
  end
end
