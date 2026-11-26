require_relative "semver_test_helper"

class RepositoryTest < ActiveSupport::TestCase
  def setup
    @fixture = GitFixture.new
    @fixture.tag("1.0.0")
    @fixture.tag("1")
    @fixture.tag("v9.9.9")
    @runner = FakeRunner.new(@fixture.dir)
    @repository = Semver::Repository.new(runner: @runner)
  end

  def teardown
    @fixture.cleanup
  end

  def test_merged_versions_lists_only_plain_semver_tags
    assert_equal [ "1.0.0" ], @repository.merged_versions.map(&:to_s)
  end

  def test_runs_the_commands_through_the_injected_runner
    @repository.head_is?(Semver::Version.parse("1.0.0"))

    assert(@runner.calls.all? { |call| call.first == "git" })
    assert_includes @runner.calls, %w[git rev-parse HEAD]
  end

  def test_head_is_the_tagged_commit
    assert @repository.head_is?(Semver::Version.parse("1.0.0"))
    @fixture.write("a.md", "x\n")
    @fixture.commit("More")

    assert_not @repository.head_is?(Semver::Version.parse("1.0.0"))
    assert_equal [ "More" ], @repository.subjects_since(Semver::Version.parse("1.0.0"))
  end

  def test_publish_uses_the_staged_version
    @fixture.write("a.md", "x\n")
    @repository.stage(Semver::Version.parse("1.1.0"), paths: [ "a.md" ])
    @repository.publish

    assert_includes @fixture.remote_tags, "1.1.0"
  end

  def test_publish_without_stage_raises
    assert_raises(RuntimeError) { @repository.publish }
  end

  def test_refresh_clears_staged_state
    @fixture.write("a.md", "x\n")
    @repository.stage(Semver::Version.parse("1.1.0"), paths: [ "a.md" ])
    @repository.refresh

    assert_raises(RuntimeError) { @repository.publish }
  end

  def test_refresh_moves_to_the_remote_main
    @fixture.push
    @fixture.advance_remote("b.md", "y\n", "Remote commit")
    @repository.refresh

    assert_equal [ "Remote commit" ], @repository.subjects_since(Semver::Version.parse("1.0.0"))
  end

  def test_reconcile_lists_releases_once_whatever_the_number_of_tags
    %w[1.0.1 1.0.2 1.0.3].each { |tag| @fixture.tag(tag) }
    @repository.reconcile(@repository.merged_versions)

    assert_equal 1, @runner.calls.count { |call| call[1..2] == %w[release list] }
    assert_equal 4, @runner.calls.count { |call| call[1..2] == %w[release create] }
    assert_equal 0, @runner.calls.count { |call| call[1..2] == %w[release view] }
  end

  def test_reconcile_creates_only_the_missing_releases
    @repository.ensure_release(Semver::Version.parse("1.0.0"), "notes")
    @fixture.tag("1.0.1")
    @repository.reconcile(@repository.merged_versions)

    assert_equal [ "1.0.0", "1.0.1" ], @runner.releases.keys.sort
  end

  def test_ensure_release_creates_only_when_missing
    version = Semver::Version.parse("1.0.0")
    @repository.ensure_release(version, "notes")
    @repository.ensure_release(version, "notes")

    assert_equal 1, @runner.calls.count { |call| call[1..2] == %w[release create] }
  end

  def test_ensure_release_reraises_other_failures
    @runner.fail_gh("view", "network down")

    assert_raises(Semver::Repository::CommandFailed) { @repository.ensure_release(Semver::Version.parse("1.0.0"), "n") }
  end
end
