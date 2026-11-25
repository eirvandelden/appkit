module Semver
  # The PR check: the level the PR's own fragments declare, against the floor its diff sets.
  class Check
    DIR = "changelog.d" #: String

    #: (base: String, head: String, ?dir: String) -> Check
    def self.between(base:, head:, dir: Dir.pwd)
      new(surface: SurfaceChange.between(base: base, head: head, dir: dir), base: base, head: head, dir: dir)
    end

    #: (surface: SurfaceChange, base: String, head: String, dir: String) -> void
    def initialize(surface:, base:, head:, dir:)
      @surface = surface
      @base = base
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

    private

    def added_paths
      fork = snapshot.git("merge-base", @base, @head).strip
      snapshot.git("diff", "--diff-filter=A", "--name-only", "--no-renames", fork, @head, "--", DIR).split("\n")
              .select { |path| path.end_with?(".md") && File.basename(path) != "README.md" }
    end

    def snapshot
      Snapshot.at(@head, dir: @dir)
    end
  end
end
