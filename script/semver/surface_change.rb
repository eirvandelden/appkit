module Semver
  # Read-only view of a repository at one ref. The only detection code that runs git.
  class Snapshot
    #: (String, ?dir: String) -> Snapshot
    def self.at(ref, dir: Dir.pwd)
      new(ref, dir)
    end

    #: (String, String) -> void
    def initialize(ref, dir)
      @ref = ref
      @dir = dir
    end

    #: () -> Array[String]
    def paths
      git("ls-tree", "-r", "--name-only", @ref).split("\n")
    end

    #: (String) -> String?
    def read(path)
      out, _err, status = Open3.capture3("git", "-C", @dir, "show", "#{@ref}:#{path}")
      status.success? ? out : nil
    end

    #: (*String) -> String
    def git(*args)
      out, err, status = Open3.capture3("git", "-C", @dir, "-c", "core.quotepath=false", *args)
      raise Repository::CommandFailed, "git #{args.join(' ')}: #{err.strip}" unless status.success?

      out
    end
  end

  # The outcome of a check: whether the declared level is enough, and one line per finding.
  class Verdict
    #: (Findings, declared: Level, ?overrides: Hash[String, String]) -> void
    def initialize(findings, declared:, overrides: {})
      @findings = findings
      @declared = declared
      @overrides = overrides
    end

    #: () -> bool
    def passed?
      @findings.unmet(declared: @declared, overrides: @overrides).empty?
    end

    #: () -> Array[String]
    def lines
      @findings.map { |finding| line(finding) }
    end

    private

    def line(finding)
      if @overrides.key?(finding.rule)
        return "overridden: #{@overrides[finding.rule]} (#{finding.rule}, #{finding.path}: #{finding.reason})"
      end

      status = finding.level > @declared ? "FAIL" : "ok"
      "#{status} #{finding.path}: #{finding.reason} needs at least #{finding.level}, " \
        "declared #{@declared} (#{finding.rule})"
    end
  end

  # What a diff changes in the public surface: the Rules applied to two Snapshots, base taken at the fork point.
  class SurfaceChange
    #: (base: String, head: String, ?rules: Array[Rule], ?dir: String) -> SurfaceChange
    def self.between(base:, head:, rules: Rule::ALL, dir: Dir.pwd)
      fork = Snapshot.at(base, dir: dir).git("merge-base", base, head).strip
      new(before: Snapshot.at(fork, dir: dir), after: Snapshot.at(head, dir: dir), fork: fork, head: head, rules: rules)
    end

    #: (before: Snapshot, after: Snapshot, fork: String, head: String, rules: Array[Rule]) -> void
    def initialize(before:, after:, fork:, head:, rules:)
      @before = before
      @after = after
      @fork = fork
      @head = head
      @rules = rules
    end

    #: () -> Findings
    def findings
      Findings.new(changed_paths.flat_map { |path| path_findings(path) })
    end

    #: (Level, ?overrides: Hash[String, String]) -> Verdict
    def check(declared, overrides: {})
      Verdict.new(findings, declared: declared, overrides: overrides)
    end

    # Files under prefix that the diff adds, from the fork point.
    #: (String) -> Array[String]
    def added_paths(prefix)
      @after.git("diff", "--diff-filter=A", "--name-only", "--no-renames", @fork, @head, "--", prefix).split("\n")
    end

    # Files under prefix that exist at the fork point and that the diff edits or deletes: path, text before, text
    # after (nil when deleted).
    #: (String) -> Array[[String, String, String?]]
    def edited(prefix)
      out = @after.git("diff", "--diff-filter=MD", "--name-only", "--no-renames", @fork, @head, "--", prefix)
      out.split("\n").map { |path| [ path, @before.read(path).to_s, @after.read(path) ] }
    end

    private

    def changed_paths
      @after.git("diff", "--name-only", "--no-renames", @fork, @head).split("\n")
    end

    def path_findings(path)
      @rules.select { |rule| rule.match?(path) }.flat_map do |rule|
        rule.findings(path: path, before: @before.read(path), after: @after.read(path))
      end
    end
  end
end
