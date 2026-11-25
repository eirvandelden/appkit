require_relative "semver_test_helper"

class FindingsTest < ActiveSupport::TestCase
  def finding(rule, level)
    Semver::Finding.new(rule: rule, path: "p", level: Semver::Level.parse(level), reason: "r")
  end

  def test_empty_findings_floor_is_patch
    assert_equal Semver::Level::PATCH, Semver::Findings.new([]).floor
  end

  def test_floor_is_the_highest_level
    assert_equal Semver::Level::MAJOR, Semver::Findings.new([ finding("a", "minor"), finding("b", "major") ]).floor
  end

  def test_unmet_lists_findings_above_the_declared_level
    findings = Semver::Findings.new([ finding("a", "minor"), finding("b", "major") ])

    assert_equal %w[b], findings.unmet(declared: Semver::Level::MINOR).map(&:rule)
  end

  def test_override_with_reason_silences_rule
    findings = Semver::Findings.new([ finding("a", "major") ])

    assert_empty findings.unmet(declared: Semver::Level::PATCH, overrides: { "a" => "optional" })
  end
end
