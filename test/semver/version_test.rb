require_relative "semver_test_helper"

class VersionTest < ActiveSupport::TestCase
  def version(text = "1.2.3")
    Semver::Version.parse(text)
  end

  def test_bump_major_zeroes_lower_parts
    assert_equal "2.0.0", version.bump(Semver::Level::MAJOR).to_s
  end

  def test_bump_minor_zeroes_patch
    assert_equal "1.3.0", version.bump(Semver::Level::MINOR).to_s
  end

  def test_bump_patch
    assert_equal "1.2.4", version.bump(Semver::Level::PATCH).to_s
  end

  def test_tag_has_no_prefix_and_major_tag_is_the_bare_number
    assert_equal "1.2.3", version.tag
    assert_equal "1", version.major_tag
  end

  def test_parse_refuses_bad_text_and_a_prefix
    [ "1.2", "v1.2.3", "one", "1.2.3.4" ].each { |text| assert_raises(ArgumentError) { version(text) } }
  end

  def test_orders_numerically
    assert_operator version("1.10.0"), :>, version("1.9.9")
  end
end
