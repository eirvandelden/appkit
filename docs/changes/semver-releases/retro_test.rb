# One-off, run by hand: bundle exec ruby -Itest docs/changes/semver-releases/retro_test.rb. Removed by `deliver`.
require_relative "../../../test/semver/semver_test_helper"
require_relative "retro"

class RetroTest < ActiveSupport::TestCase
  Tip = Struct.new(
    :sha,       #: String
    :tip_index  #: Integer
  )

  #: () -> void
  def setup
    @fixture = GitFixture.new
  end

  #: () -> void
  def teardown
    @fixture.cleanup
  end

  #: () -> void
  def test_a_later_edit_of_an_upgrading_step_stays_with_the_release_that_wrote_it
    @fixture.write("CHANGELOG.md", "# Changelog\n\n## Unreleased\n\n")
    baseline = @fixture.commit("Baseline")
    @fixture.write("CHANGELOG.md", "# Changelog\n\n## Unreleased\n\n### Upgrading\n1. Add the menu.\n2. Render it.\n")
    first = @fixture.commit("First change")
    @fixture.write("CHANGELOG.md",
                   "# Changelog\n\n## Unreleased\n\n### Upgrading\n1. Add the menu.\n2. Render the new menu.\n")
    second = @fixture.commit("Second change")

    sections = Dir.chdir(@fixture.dir) do
      Retro.changelog_sections("HEAD", baseline, [ Tip.new(first, 2), Tip.new(second, 3) ])
    end

    assert_equal [ "1. Add the menu.", "2. Render it." ], sections[1]["Upgrading"]
    assert_equal [ "2. Render the new menu." ], sections[2]["Upgrading"]
  end

  #: () -> void
  def test_a_step_reference_prefers_the_step_of_its_own_release
    sections = [
      { "Upgrading" => [ "1. Add the menu.", "2. Render it." ] },
      { "Upgrading" => [ "2. Render the new menu.", "3. Then check step 2." ] }
    ]

    Retro.remap_step_references(sections, [ "5.0.0", "6.0.0" ])

    assert_equal "3. Then check step 1.", sections[1]["Upgrading"].last
  end

  #: () -> void
  def test_a_step_reference_falls_back_to_the_release_that_holds_the_step
    sections = [
      { "Upgrading" => [ "1. Add the menu.", "2. Render it." ] },
      { "Upgrading" => [ "3. Then check step 2." ] }
    ]

    Retro.remap_step_references(sections, [ "5.0.0", "6.0.0" ])

    assert_equal "3. Then check step 2 of 5.0.0.", sections[1]["Upgrading"].last
  end
end
