require_relative "semver_test_helper"

class RemoteTest < ActiveSupport::TestCase
  def setup
    @fixture = GitFixture.new
    @runner = FakeRunner.new(@fixture.dir)
    @fixture.write("CHANGELOG.md", "# Changelog\n")
    @fixture.write("lib/appkit/version.rb", "module Appkit\n  VERSION = \"1.0.0\"\nend\n")
    @fixture.commit("Baseline")
    @fixture.tag("1.0.0")
    @fixture.tag("1")
    @fixture.push
  end

  def teardown
    @fixture.cleanup
  end

  def merge_fragment(name, level)
    @fixture.branch(name)
    @fixture.write("changelog.d/#{name}.md", fragment_text(level))
    @fixture.commit("Add #{name}")
    @fixture.checkout("main")
    @fixture.merge(name)
    @fixture.push
  end

  def cut
    Dir.chdir(@fixture.dir) { Semver::Release.pending(repository: Semver::Repository.new(runner: @runner)).cut }
  end

  def test_two_runs_release_two_versions
    merge_fragment("one", "minor")
    cut
    merge_fragment("two", "minor")
    cut

    assert_equal %w[1 1.0.0 1.1.0 1.2.0], @fixture.remote_tags.sort
  end

  def test_the_moving_major_tag_follows_the_newest_release
    merge_fragment("one", "minor")
    cut

    assert_equal @fixture.git(@fixture.dir, "rev-parse", "1.1.0^{commit}"),
@fixture.git(@fixture.dir, "ls-remote", "origin", "refs/tags/1").split.first
  end

  def test_rejected_atomic_push_changes_nothing
    merge_fragment("one", "minor")
    before = [ @fixture.remote_head, @fixture.remote_tags.sort ]
    @runner.reject_pushes = 3
    assert_raises(Semver::Repository::CommandFailed) { cut }

    assert_equal before, [ @fixture.remote_head, @fixture.remote_tags.sort ]
  end

  def test_run_fails_after_three_rejected_attempts
    merge_fragment("one", "minor")
    @runner.reject_pushes = 3

    error = assert_raises(Semver::Repository::CommandFailed) { cut }
    assert_match(/after 3 attempts/, error.message)
    assert_equal 3, @runner.calls.count { |call| call[1] == "push" && call.include?("--atomic") }
  end

  def test_rejected_push_replans_from_the_advanced_remote_tip
    merge_fragment("one", "minor")
    @runner.reject_pushes = 1
    @runner.on_reject = -> { @fixture.advance_remote("changelog.d/big.md", fragment_text("major"), "Add big") }
    cut

    assert_includes @fixture.remote_tags, "2.0.0"
    assert_not_includes @fixture.remote_tags, "1.1.0"
  end

  def test_missing_release_is_repaired_after_a_later_merge
    merge_fragment("one", "minor")
    @runner.fail_gh("create", "1.1.0", "boom")
    assert_raises(Semver::Repository::CommandFailed) { cut }
    @runner.instance_variable_set(:@gh_failures, [])
    merge_fragment("two", "patch")
    cut

    assert_equal %w[1.0.0 1.1.0 1.1.1], @runner.releases.keys.sort
    assert_includes @fixture.remote_tags, "1"
  end

  def test_rejected_major_tag_push_fails_the_run_and_the_next_run_repairs_it
    merge_fragment("one", "minor")
    @runner.reject_major_pushes = 1
    error = assert_raises(Semver::Repository::CommandFailed) { cut }
    assert_match(/major tag push was refused/, error.message)
    assert_equal 1, @runner.calls.count { |call| call[1] == "push" && call.include?("--atomic") }

    cut

    assert_equal %w[1.0.0 1.1.0], @runner.releases.keys.sort
    assert_equal @fixture.git(@fixture.dir, "rev-parse", "1.1.0^{commit}"),
@fixture.git(@fixture.dir, "ls-remote", "origin", "refs/tags/1").split.first
  end

  def test_github_release_notes_match_the_changelog_for_a_merge_without_fragment
    @fixture.write("lib/thing.rb", "x\n")
    @fixture.commit("Fix the thing")
    @fixture.push
    cut

    assert_includes @runner.releases["1.0.1"], "- Fix the thing"
    assert_not_includes @runner.releases["1.0.1"], "Release 1.0.1"
    assert_not_includes @fixture.read("CHANGELOG.md"), "- Release 1.0.1"
  end
end
