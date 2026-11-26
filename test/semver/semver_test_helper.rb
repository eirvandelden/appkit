require "active_support"
require "active_support/test_case"
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"
require "date"

$LOAD_PATH.unshift File.expand_path("../../script", __dir__)
require "semver"

# A git repository in a tmp directory, with a bare remote called origin.
class GitFixture
  attr_reader :dir, :remote

  def initialize
    @root = Dir.mktmpdir("semver")
    @remote = File.join(@root, "remote.git")
    @dir = File.join(@root, "work")
    git(@root, "init", "--bare", "--initial-branch=main", @remote)
    git(@root, "init", "--initial-branch=main", @dir)
    configure
    write("README.md", "start\n")
    commit("Start")
    git(@dir, "remote", "add", "origin", @remote)
    git(@dir, "push", "origin", "main")
  end

  def write(path, content)
    full = File.join(@dir, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  def remove(path)
    git(@dir, "rm", "-q", path)
  end

  def commit(message)
    git(@dir, "add", "-A")
    git(@dir, "commit", "-q", "-m", message)
    git(@dir, "rev-parse", "HEAD")
  end

  def branch(name)
    git(@dir, "checkout", "-q", "-b", name)
  end

  def checkout(name)
    git(@dir, "checkout", "-q", name)
  end

  def merge(name, message = "Merge #{name}")
    git(@dir, "merge", "-q", "--no-ff", "-m", message, name)
  end

  def push
    git(@dir, "push", "origin", "main", "--tags")
  end

  def tag(name, ref = "HEAD")
    git(@dir, "tag", name, ref)
  end

  def tags(dir = @dir)
    git(dir, "tag", "--list").split("\n")
  end

  def remote_tags
    git(@dir, "ls-remote", "--tags", "origin").lines.map { |line| line.split.last.delete_prefix("refs/tags/") }
  end

  def head
    git(@dir, "rev-parse", "HEAD")
  end

  def read(path)
    File.read(File.join(@dir, path))
  end

  def git(dir, *args)
    out, status = Open3.capture2e("git", "-C", dir, *args)
    raise "git #{args.join(' ')} failed: #{out}" unless status.success?
    out.strip
  end

  def advance_remote(path, content, message)
    clone = File.join(@root, "other")
    FileUtils.rm_rf(clone)
    git(@root, "clone", "-q", @remote, clone)
    git(clone, "config", "user.name", "Other")
    git(clone, "config", "user.email", "other@example.com")
    git(clone, "config", "commit.gpgsign", "false")
    FileUtils.mkdir_p(File.dirname(File.join(clone, path)))
    File.write(File.join(clone, path), content)
    git(clone, "add", "-A")
    git(clone, "commit", "-q", "-m", message)
    git(clone, "push", "-q", "origin", "main")
  end

  def remote_head
    git(@dir, "ls-remote", "origin", "refs/heads/main").split.first
  end

  def cleanup
    FileUtils.remove_entry(@root)
  end

  private

  def configure
    git(@dir, "config", "user.name", "Test")
    git(@dir, "config", "user.email", "test@example.com")
    git(@dir, "config", "commit.gpgsign", "false")
    git(@dir, "config", "tag.gpgsign", "false")
    git(@dir, "config", "core.excludesFile", "/dev/null")
  end
end

# A command runner that runs git for real and fakes gh, recording every call.
class FakeRunner
  attr_reader :calls, :releases
  def hide_from_list(tag)
    @hidden << tag
  end

  attr_accessor :reject_pushes, :on_reject, :reject_major_pushes

  def initialize(dir)
    @dir = dir
    @calls = []
    @releases = {}
    @hidden = []
    @reject_pushes = 0
    @reject_major_pushes = 0
    @gh_failures = []
  end

  def fail_gh(*words, message)
    @gh_failures << [ words, message ]
  end

  def call(*cmd)
    @calls << cmd
    return gh(cmd) if cmd.first == "gh"
    if major_push?(cmd)
      @reject_major_pushes -= 1
      raise Semver::Repository::CommandFailed, "rejected: the major tag push was refused"
    end
    return git(cmd) unless push_rejected?(cmd)
    raise Semver::Repository::CommandFailed, "rejected: remote has moved"
  end

  def major_push?(cmd)
    cmd[1] == "push" && cmd.include?("--force") && @reject_major_pushes.positive?
  end

  private

  def gh(cmd)
    failure = @gh_failures.find { |words, _| (words - cmd).empty? }
    raise Semver::Repository::CommandFailed, failure.last if failure
    tag = cmd[3]
    case cmd[1..2]
    when %w[release view]
      raise Semver::Repository::CommandFailed, "release not found" unless @releases.key?(tag)
      @releases[tag]
    when %w[release list]
      (@releases.keys - @hidden).join("\n")
    when %w[release create]
      @releases[tag] = cmd[(cmd.index("--notes") || 0) + 1].to_s
    else raise "unexpected gh call: #{cmd.inspect}"
    end
  end

  def push_rejected?(cmd)
    return false unless cmd[1] == "push" && cmd.include?("--atomic") && @reject_pushes.positive?
    @reject_pushes -= 1
    @on_reject&.call
    true
  end

  def git(cmd)
    out, err, status = Open3.capture3(*cmd, chdir: @dir)
    raise Semver::Repository::CommandFailed, "#{cmd.join(' ')}: #{err}" unless status.success?
    out
  end
end

def fragment_text(level, body = "### Added\n- A thing.\n")
  "---\nlevel: #{level}\n---\n#{body}"
end
