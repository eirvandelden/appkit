module Semver
  # The git and gh edge. Every external effect passes through here.
  class Repository
    class CommandFailed < StandardError; end

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

    #: (Array[String]) -> Array[String]
    def in_merge_order(paths)
      position = git("rev-list", "--reverse", "HEAD").split("\n").each_with_index.to_h
      paths.sort_by { |path|
 position.fetch(git("log", "--diff-filter=A", "--format=%H", "-1", "--", path).strip, position.size) }
    end

    #: (Array[Version]) -> void
    def reconcile(versions)
      versions.each { |version| ensure_release(version, changelog_notes(version)) }
      versions.group_by(&:major).each_value { |group| move_major_tag(group.max) }
    end

    #: (Version, paths: Array[String]) -> void
    def stage(version, paths:)
      git("add", "-A", "--", *paths)
      @staged = version
    end

    #: () -> void
    def refresh
      git("fetch", "origin", "main", "--tags")
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

      @runner.call("gh", "release", "create", version.tag, "--title", version.tag, "--notes", notes, "--verify-tag")
    end

    private

    def git(*args)
      @runner.call("git", *args)
    end

    def changelog_notes(version)
      return "Release #{version}" unless File.exist?("CHANGELOG.md")

      section = File.read("CHANGELOG.md")[/^## #{Regexp.escape(version.to_s)}\b.*?\n(.*?)(?=^## |\z)/m, 1]
      section.to_s.strip.empty? ? "Release #{version}" : section.strip
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
    rescue CommandFailed
      git("tag", "-d", version.tag)
      raise
    end
  end
end
