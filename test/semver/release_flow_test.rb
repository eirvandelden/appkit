require_relative "semver_test_helper"

class ReleaseFlowTest < ActiveSupport::TestCase
  def setup
    @fixture = GitFixture.new
    @runner = FakeRunner.new(@fixture.dir)
    @fixture.write("CHANGELOG.md", "# Changelog\n\n## 1.2.3 - 2026-01-01\n\n### Fixed\n- Old.\n")
    @fixture.write("lib/appkit/version.rb", "module Appkit\n  VERSION = \"1.2.3\"\nend\n")
    @fixture.commit("Baseline")
    @fixture.tag("1.2.3")
    @fixture.push
  end

  def teardown
    @fixture.cleanup
  end

  def test_minor_fragment_releases_next_minor_tag_and_release
    @fixture.branch("feature")
    @fixture.write("changelog.d/feature.md", fragment_text("minor", "### Added\n- Shiny.\n"))
    @fixture.commit("Add shiny")
    @fixture.checkout("main")
    @fixture.merge("feature")
    @fixture.push

    Dir.chdir(@fixture.dir) do
      Semver::Release.pending(repository: Semver::Repository.new(runner: @runner), today: Date.new(2026, 2, 3)).cut
    end

    assert_includes @fixture.remote_tags, "1.3.0"
    assert_includes @runner.releases.keys, "1.3.0"
    assert_includes @fixture.read("lib/appkit/version.rb"), 'VERSION = "1.3.0"'
    assert_includes @fixture.read("CHANGELOG.md"), "## 1.3.0 - 2026-02-03\n\n### Added\n- Shiny."
    refute_path_exists File.join(@fixture.dir, "changelog.d/feature.md")
  end
end
