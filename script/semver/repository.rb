module Semver
  # The git and gh edge. Every external effect passes through here.
  class Repository
    class CommandFailed < StandardError; end

    # The atomic push of the release commit and its tag lost a race with another push to main.
    class Rejected < CommandFailed; end

    TAG_PATTERN = /\A\d+\.\d+\.\d+\z/ #: Regexp
    DEFAULT_RUNNER = lambda do |*cmd|
      out, err, status = Open3.capture3(*cmd)
      raise CommandFailed, "#{cmd.join(' ')} failed: #{err.strip}" unless status.success?

      out
    end #: ^(*String) -> String

    #: (?runner: ^(*String) -> String) -> void
    def initialize(runner: DEFAULT_RUNNER)
      @runner = runner
      @staged = nil
    end

    #: () -> Array[Version]
    def merged_versions
      git("tag", "--merged", "HEAD", "--list", "[0-9]*.[0-9]*.[0-9]*").split("\n").grep(TAG_PATTERN).map { |tag|
 Version.parse(tag) }.sort
    end

    #: (Version) -> bool
    def head_is?(version)
      git("rev-list", "-n1", "refs/tags/#{version.tag}").strip == git("rev-parse", "HEAD").strip
    end

    #: (Version?) -> Array[String]
    def subjects_since(version)
      range = version ? [ "refs/tags/#{version.tag}..HEAD" ] : []
      git("log", "--format=%s", *range).split("\n")
    end

    # The subjects since the version of the first-parent commits that added none of the given paths,
    # so a merge that carried a fragment is not listed a second time.
    #: (Version?, without: Array[String]) -> Array[String]
    def subjects_without(version, without:)
      range = version ? [ "refs/tags/#{version.tag}..HEAD" ] : []
      out = git("-c", "core.quotepath=false", "log", "--first-parent", "-m", "--name-status", "--format=%x1e%s", *range)
      records = out.split("\x1e").drop(1).map { |record| record.lines.map(&:chomp).reject(&:empty?) }
      records.reject { |_subject, *changes| (added_paths(changes) & without).any? }.map(&:first)
    end

    # The paths in the order the first-parent history of main introduced them, so the order of the merges
    # decides, not the date of the branch commit that wrote the file. A filename a release consumed and a
    # later branch reused counts from its latest addition. Fragments one merge added tie, and the path breaks the tie.
    #: (Array[String]) -> Array[String]
    def in_merge_order(paths)
      out = git("-c", "core.quotepath=false", "log", "--first-parent", "-m", "--reverse", "--name-status",
                "--format=%x1e")
      introduced = {} #: Hash[String, Integer]
      out.split("\x1e").drop(1).each_with_index do |record, index|
        added_paths(record.lines.map(&:chomp).reject(&:empty?)).each { |path| introduced[path] = index }
      end
      paths.sort_by { |path| [ introduced.fetch(path, introduced.size), path ] }
    end

    #: (Array[Version]) -> void
    def reconcile(versions)
      existing = @runner.call("gh", "release", "list", "--limit", "1000", "--json", "tagName", "--jq",
                              ".[].tagName").split
      versions.reject { |version|
 existing.include?(version.tag) }.each { |version| ensure_release(version, changelog_notes(version)) }
      versions.group_by(&:major).each_value { |group| move_major_tag(group.max) }
    end

    #: (Version, paths: Array[String]) -> void
    def stage(version, paths:)
      git("add", "-A", "--", *paths)
      @staged = version
    end

    #: () -> void
    def refresh
      git("fetch", "--force", "origin", "main", "--tags")
      git("reset", "--hard", "origin/main")
      git("clean", "-fdq")
      @staged = nil
    end

    #: () -> void
    def publish
      version = @staged or raise "nothing staged"
      git("commit", "-m", "Release #{version}")
      git("tag", version.tag)
      push_atomic(version)
      git("tag", "-f", version.major_tag, version.tag)
      git("push", "--force", "origin", "refs/tags/#{version.major_tag}")
      @staged = nil
    end

    #: (Version, String) -> void
    def ensure_release(version, notes)
      @runner.call("gh", "release", "view", version.tag)
    rescue CommandFailed => error
      raise unless error.message.match?(/not found/i)

      create_release(version, notes)
    end

    private

    def git(*args)
      @runner.call("git", *args)
    end

    # The paths of the `A\t<path>` lines of a `--name-status` listing.
    def added_paths(changes)
      changes.filter_map { |change| change.delete_prefix("A\t") if change.start_with?("A\t") }
    end

    def create_release(version, notes = changelog_notes(version))
      @runner.call("gh", "release", "create", version.tag, "--title", version.tag, "--notes", notes, "--verify-tag")
    end

    def changelog_notes(version)
      return "Release #{version}" unless File.exist?("CHANGELOG.md")

      section = changelog_section(version).join.strip
      section.empty? ? "Release #{version}" : section
    end

    # The lines under `## <version>`, up to the next `## ` heading. Neither heading counts inside a code fence.
    def changelog_section(version)
      fence = Fence.new
      heading = /\A## #{Regexp.escape(version.to_s)}\b/
      lines = File.readlines("CHANGELOG.md").drop_while { |line| fence.code?(line) || !line.match?(heading) }
      lines.drop(1).take_while { |line| fence.code?(line) || !line.start_with?("## ") }
    end

    def move_major_tag(newest)
      return if remote_tag_commit(newest.major_tag) == git("rev-parse", "refs/tags/#{newest.tag}^{commit}").strip

      git("tag", "-f", newest.major_tag, newest.tag)
      git("push", "--force", "origin", "refs/tags/#{newest.major_tag}")
    end

    def remote_tag_commit(tag)
      git("ls-remote", "origin", "refs/tags/#{tag}", "refs/tags/#{tag}^{}").lines.map { |line|
 line.split.first }.last.to_s
    end

    def push_atomic(version)
      git("push", "--atomic", "origin", "refs/heads/main:refs/heads/main",
"refs/tags/#{version.tag}:refs/tags/#{version.tag}")
    rescue CommandFailed => error
      git("tag", "-d", version.tag)
      raise unless error.message.include?("rejected")

      raise Rejected, error.message
    end
  end
end
