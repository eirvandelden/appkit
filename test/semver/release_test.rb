require_relative "semver_test_helper"

class ReleaseTest < ActiveSupport::TestCase
  def setup
    @fixture = GitFixture.new
    @runner = FakeRunner.new(@fixture.dir)
    @fixture.write("CHANGELOG.md", "# Changelog\n\n## 1.0.0 - 2026-01-01\n\n### Fixed\n- Old.\n")
    @fixture.write("lib/appkit/version.rb", "module Appkit\n  VERSION = \"1.0.0\"\nend\n")
    @fixture.commit("Baseline")
    @fixture.tag("1.0.0")
    @fixture.push
  end

  def teardown
    @fixture.cleanup
  end

  def repository
    Semver::Repository.new(runner: @runner)
  end

  def merge_fragment(name, level, body = "### Added\n- #{name}.\n")
    @fixture.branch(name)
    @fixture.write("changelog.d/#{name}.md", fragment_text(level, body))
    @fixture.commit("Add #{name}")
    @fixture.checkout("main")
    @fixture.merge(name)
    @fixture.push
  end

  def release
    Dir.chdir(@fixture.dir) { Semver::Release.pending(repository: repository, today: Date.new(2026, 3, 1)) }
  end

  def cut
    Dir.chdir(@fixture.dir) { release.cut }
  end

  def test_highest_level_wins_in_either_order
    [ %w[major patch], %w[patch major] ].each_with_index do |order, index|
      fixture = GitFixture.new
      fixture.write("CHANGELOG.md", "# Changelog\n")
      fixture.write("lib/appkit/version.rb", "module Appkit\n  VERSION = \"1.0.0\"\nend\n")
      fixture.commit("Baseline")
      fixture.tag("1.0.0")
      order.each { |level| merge_into(fixture, "#{level}#{index}", level) }
      runner = FakeRunner.new(fixture.dir)
      Dir.chdir(fixture.dir) { Semver::Release.pending(repository: Semver::Repository.new(runner: runner)).cut }

      assert_includes fixture.remote_tags, "2.0.0", "order #{order.inspect}"
      fixture.cleanup
    end
  end

  def test_no_fragment_releases_patch_from_commit_subjects
    @fixture.write("docs.md", "x\n")
    @fixture.commit("Fix a typo")
    @fixture.push
    cut

    assert_includes @fixture.remote_tags, "1.0.1"
    assert_includes @fixture.read("CHANGELOG.md"), "### Changed\n- Fix a typo"
  end

  def test_rerun_on_release_commit_creates_no_second_tag
    merge_fragment("shiny", "minor")
    cut
    tags = @fixture.remote_tags.sort
    cut

    assert_equal tags, @fixture.remote_tags.sort
  end

  def test_missing_github_release_is_repaired
    merge_fragment("shiny", "minor")
    @runner.fail_gh("create", "1.1.0", "boom")
    assert_raises(Semver::Repository::CommandFailed) { cut }
    assert_includes @fixture.remote_tags, "1.1.0"
    @runner.instance_variable_set(:@gh_failures, [])
    cut

    assert_includes @runner.releases.keys, "1.1.0"
  end

  def test_upgrading_steps_follow_fragment_add_order
    merge_fragment("zeta", "major", "### Upgrading\n1. Run zeta.\n")
    merge_fragment("alpha", "major", "### Upgrading\n1. Run alpha.\n")
    cut

    assert_includes @fixture.read("CHANGELOG.md"), "### Upgrading\n1. Run zeta.\n2. Run alpha."
  end

  def test_not_due_when_head_is_the_last_release
    assert_not_predicate release, :due?
  end

  def test_release_builds_in_plain_ruby_without_active_support
    merge_fragment("shiny", "minor")
    code = "require 'semver'; r = Semver::Release.pending(repository: Semver::Repository.new); puts r.version"
    out, err, status = Open3.capture3(RbConfig.ruby, "-I", File.expand_path("../../script", __dir__), "-e", code,
                                      chdir: @fixture.dir)

    assert_predicate status, :success?, err
    assert_equal "1.1.0", out.strip
  end

  def test_upgrade_code_block_stays_inside_its_step
    merge_fragment("blocky", "major", "### Upgrading\n1. Add this:\n   ```ruby\n   config.x = 1\n   ```\n2. Restart.\n")
    cut

    assert_includes @fixture.read("CHANGELOG.md"),
                    "1. Add this:\n   ```ruby\n   config.x = 1\n   ```\n2. Restart."
  end

  def test_release_refuses_when_no_version_tag_exists
    fixture = GitFixture.new
    runner = FakeRunner.new(fixture.dir)
    error = assert_raises(Semver::Release::NoBaseline) do
      Dir.chdir(fixture.dir) { Semver::Release.pending(repository: Semver::Repository.new(runner: runner)).cut }
    end

    assert_match(/retro/i, error.message)
    fixture.cleanup
  end

  def test_a_bad_fragment_fails_before_anything_is_written
    @fixture.write("changelog.d/bad.md", "no front matter\n")
    @fixture.commit("Bad fragment")
    @fixture.push

    assert_raises(ArgumentError) { cut }
    assert_equal [ "1.0.0" ], @fixture.remote_tags
  end

  private

  def merge_into(fixture, name, level)
    fixture.branch(name)
    fixture.write("changelog.d/#{name}.md", fragment_text(level))
    fixture.commit("Add #{name}")
    fixture.checkout("main")
    fixture.merge(name)
    fixture.push
  end
end
