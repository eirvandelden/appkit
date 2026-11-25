require_relative "semver_test_helper"

class LevelTest < ActiveSupport::TestCase
  def test_parse_accepts_the_three_names
    assert_equal %w[patch minor major], %w[patch minor major].map { |name| Semver::Level.parse(name).to_s }
  end

  def test_parse_refuses_other_names
    assert_raises(ArgumentError) { Semver::Level.parse("none") }
  end

  def test_orders_patch_below_major
    assert_operator Semver::Level.parse("patch"), :<, Semver::Level.parse("major")
    assert_equal Semver::Level::MAJOR, [ Semver::Level::MINOR, Semver::Level::MAJOR, Semver::Level::PATCH ].max
  end
end
