require_relative "semver_test_helper"

class FragmentTest < ActiveSupport::TestCase
  def test_parse_reads_level_and_sections
    fragment = Semver::Fragment.parse(fragment_text("major", "### Added\n- One.\n\n### Upgrading\n1. Run it.\n"))

    assert_equal Semver::Level::MAJOR, fragment.level
    assert_equal({ "Added" => [ "- One." ], "Upgrading" => [ "1. Run it." ] }, fragment.sections)
  end

  def test_parse_refuses_an_unknown_level
    assert_raises(ArgumentError) { Semver::Fragment.parse(fragment_text("huge")) }
  end

  def test_parse_refuses_a_missing_level
    assert_raises(ArgumentError) { Semver::Fragment.parse("---\nfoo: 1\n---\n### Added\n- x\n") }
  end

  def test_parse_refuses_an_unknown_section
    assert_raises(ArgumentError) { Semver::Fragment.parse(fragment_text("minor", "### Removed\n- x\n")) }
  end

  def test_parse_refuses_an_h2_heading
    assert_raises(ArgumentError) { Semver::Fragment.parse(fragment_text("patch", "## Upgrading\n1. Run x\n")) }
  end

  def test_parse_refuses_text_before_the_first_section
    assert_raises(ArgumentError) { Semver::Fragment.parse(fragment_text("patch", "Loose text.\n### Added\n- x\n")) }
  end

  def test_blank_override_reason_raises
    text = "---\nlevel: major\noverrides:\n  config: \"  \"\n---\n### Added\n- x\n"

    assert_raises(ArgumentError) { Semver::Fragment.parse(text) }
  end

  def test_patch_with_upgrading_is_refused
    assert_raises(ArgumentError) { Semver::Fragment.validate!(fragment_text("patch", "### Upgrading\n1. Do it.\n")) }
  end

  def test_unknown_override_rule_is_refused
    text = "---\nlevel: major\noverrides:\n  nope: because\n---\n### Added\n- x\n"

    assert_raises(ArgumentError) { Semver::Fragment.validate!(text, known_rules: %w[config]) }
  end

  def test_valid_override_is_kept
    text = "---\nlevel: patch\noverrides:\n  config: optional option\n---\n### Added\n- x\n"

    assert_equal({ "config" => "optional option" }, Semver::Fragment.validate!(text, known_rules: %w[config]).overrides)
  end

  def test_pending_refuses_a_nested_fragment
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "feature"))
      File.write(File.join(dir, "feature", "work.md"), fragment_text("major"))

      assert_raises(ArgumentError) { Semver::Fragment.pending(dir) }
    end
  end

  def test_headings_inside_a_code_fence_are_text
    body = "### Upgrading\n1. Add this:\n```ruby\n# config/initializers/appkit.rb\n### Added\n```\n"
    fragment = Semver::Fragment.parse("---\nlevel: major\n---\n#{body}")

    assert_equal [ "Upgrading" ], fragment.sections.keys
    assert_includes fragment.sections["Upgrading"], "# config/initializers/appkit.rb"
  end

  def test_a_code_fence_left_open_is_refused
    text = "---\nlevel: patch\n---\n### Fixed\n- x\n```ruby\nfoo\n### Upgrading\n1. Run y\n"

    assert_raises(ArgumentError) { Semver::Fragment.validate!(text) }
  end

  def test_upgrading_line_before_the_first_numbered_step_is_refused
    text = "---\nlevel: major\n---\n### Upgrading\n- Note first\n1. Run x\n"

    assert_raises(ArgumentError) { Semver::Fragment.validate!(text) }
  end

  def test_parse_reads_a_heading_indented_by_up_to_three_spaces
    body = "### Fixed\n- x\n   ### Upgrading\n1. Run y\n"

    assert_raises(ArgumentError) { Semver::Fragment.validate!(fragment_text("patch", body)) }
  end
end
