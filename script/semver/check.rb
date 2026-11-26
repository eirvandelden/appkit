module Semver
  # The PR check: the level the PR's own fragments declare, against the floor its diff sets.
  class Check
    DIR = "changelog.d" #: String

    #: (base: String, head: String, ?dir: String) -> Check
    def self.between(base:, head:, dir: Dir.pwd)
      new(surface: SurfaceChange.between(base: base, head: head, dir: dir), head: head, dir: dir)
    end

    #: (surface: SurfaceChange, head: String, dir: String) -> void
    def initialize(surface:, head:, dir:)
      @surface = surface
      @head = head
      @dir = dir
    end

    #: () -> Verdict
    def verdict
      @surface.check(declared, overrides: fragments.reduce({}) { |all, fragment| all.merge(fragment.overrides) })
    end

    #: () -> Level
    def declared
      (fragments.map(&:level) + [ Level::PATCH ]).max
    end

    #: () -> Array[Fragment]
    def fragments
      @fragments ||= added_paths.filter_map do |path|
        text = snapshot.read(path) or next
        Fragment.validate!(text, known_rules: Rule::ALL.map(&:id), path: path)
      end
    end

    # What the PR does to fragments that are already pending: deleting one or lowering its level lowers the next
    # release without a finding from the surface rules.
    #: () -> Array[String]
    def fragment_problems
      @surface.edited(DIR).filter_map do |path, before, after|
        next unless fragment_path?(path)

        invalid(path, after) || problem(path, Fragment.parse(before).level, after && Fragment.parse(after).level)
      end
    end

    private

    def added_paths
      paths = @surface.added_paths(DIR).select { |path| fragment_path?(path) }
      paths.each { |path| Fragment.refuse_nested!(path, DIR) }
    end

    def fragment_path?(path)
      path.end_with?(".md") && path != "#{DIR}/README.md"
    end

    def snapshot
      Snapshot.at(@head, dir: @dir)
    end

    # An edited fragment must stay valid, or the release run rejects it and nothing is published.
    def invalid(path, text)
      return unless text

      Fragment.validate!(text, known_rules: Rule::ALL.map(&:id), path: path)
      nil
    rescue ArgumentError => error
      "#{path}: #{error.message}"
    end

    def problem(path, was, now)
      return "#{path}: a fragment already pending on the base branch is deleted" unless now

      "#{path}: the level of a pending fragment is lowered from #{was} to #{now}" if now < was
    end
  end
end
