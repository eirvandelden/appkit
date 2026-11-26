module Semver
  # One PR's changelog entry: a level, optional overrides and the changelog text.
  class Fragment
    SECTIONS = %w[Added Changed Fixed Upgrading].freeze #: Array[String]
    FRONT_MATTER = /\A---\n(.*?)\n---\n?(.*)\z/m #: Regexp

    attr_reader :level #: Level
    attr_reader :overrides #: Hash[String, String]
    attr_reader :sections #: Hash[String, Array[String]]
    attr_reader :path #: String?

    #: (String, ?path: String?) -> Fragment
    def self.parse(text, path: nil)
      match = FRONT_MATTER.match(text) or raise ArgumentError, "fragment has no front matter"
      meta = YAML.safe_load(match[1]) || {}
      raise ArgumentError, "fragment front matter must be a mapping" unless meta.is_a?(Hash)
      raise ArgumentError, "fragment has no level" unless meta.key?("level")

      new(level: Level.parse(meta["level"].to_s), overrides: meta["overrides"] || {},
          sections: parse_sections(match[2]), path: path)
    end

    #: (String, ?known_rules: Array[String]?, ?path: String?) -> Fragment
    def self.validate!(text, known_rules: nil, path: nil)
      fragment = parse(text, path: path)
      fragment.validate!(known_rules: known_rules)
      fragment
    end

    #: (String) -> Array[Fragment]
    def self.pending(dir)
      files = Dir.glob(File.join(dir, "**", "*.md"), File::FNM_DOTMATCH).reject { |file| file == File.join(dir, "README.md") }
      files.each { |file| refuse_nested!(file, dir) }
      files.map { |file| validate!(File.read(file), path: file) }
    end

    # A fragment is a top-level file of the directory: the release reads nothing deeper.
    #: (String, String) -> void
    def self.refuse_nested!(file, dir)
      return if File.dirname(file) == dir

      raise ArgumentError, "#{file} is nested: a fragment is a top-level file, #{dir}/<slug>.md"
    end

    # A line that opens or closes a fenced code block, written with backticks or tildes.
    #: (String) -> bool
    def self.fence?(line)
      line.lstrip.start_with?("```", "~~~")
    end

    #: (String) -> Hash[String, Array[String]]
    def self.parse_sections(body)
      sections = {} #: Hash[String, Array[String]]
      current = nil
      fenced = false
      body.each_line(chomp: true) do |line|
        fenced = !fenced if fence?(line)
        if fenced || fence?(line)
          raise ArgumentError, "text before the first section: #{line.inspect}" unless current

          current << line
        elsif (heading = line[/\A {0,3}### (.+)\z/, 1])
          raise ArgumentError, "unknown section #{heading.inspect}" unless SECTIONS.include?(heading)

          current = sections[heading] ||= []
        elsif line.match?(/\A {0,3}\#{1,6} /)
          raise ArgumentError, "only ### section headings are allowed: #{line.inspect}"
        elsif !line.strip.empty?
          raise ArgumentError, "text before the first section: #{line.inspect}" unless current

          current << line
        end
      end
      raise ArgumentError, "a code fence is still open at the end of the body" if fenced

      sections
    end

    private_class_method :parse_sections

    #: (level: Level, overrides: untyped, sections: Hash[String, Array[String]], ?path: String?) -> void
    def initialize(level:, overrides:, sections:, path: nil)
      @level = level
      @overrides = check_overrides(overrides)
      @sections = sections
      @path = path
    end

    #: (?known_rules: Array[String]?) -> void
    def validate!(known_rules: nil)
      raise ArgumentError, "a fragment with an Upgrading section must declare level major" if upgrading? && level < Level::MAJOR
      raise ArgumentError, "an Upgrading section starts with a numbered step" unless numbered_start?

      unknown = overrides.keys - (known_rules || overrides.keys)
      raise ArgumentError, "unknown override rule #{unknown.join(', ')}" unless unknown.empty?
    end

    private

    def check_overrides(overrides)
      raise ArgumentError, "overrides must be a mapping of rule id to reason" unless overrides.is_a?(Hash)

      overrides.each do |rule, reason|
        raise ArgumentError,
"override #{rule} needs a non-blank reason" unless reason.is_a?(String) && !reason.strip.empty?
      end
      overrides.transform_keys(&:to_s)
    end

    def upgrading?
      sections.fetch("Upgrading", []).any?
    end

    def numbered_start?
      first = sections.fetch("Upgrading", []).first
      first.nil? || first.match?(/\A\d+\.\s/)
    end
  end
end
