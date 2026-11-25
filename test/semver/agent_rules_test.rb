require_relative "semver_test_helper"

class AgentRulesTest < ActiveSupport::TestCase
  def test_agents_md_names_fragment_folder_and_level_rules
    text = File.read(File.expand_path("../../AGENTS.md", __dir__))

    assert_includes text, "changelog.d/<branch-slug>.md"
    %w[major minor patch].each { |level| assert_match(/`level: #{level}`/, text) }
    assert_match(/never edit `lib\/appkit\/version\.rb`/i, text)
  end
end
