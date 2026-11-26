require_relative "semver_test_helper"

class RuleTest < ActiveSupport::TestCase
  def rule(**levels)
    defaults = { added: Semver::Level::MINOR, removed: Semver::Level::MAJOR, changed: Semver::Level::PATCH }
    Semver::Rule.new(id: "importmap", glob: "config/*.rb", parser: Semver::Parsers.method(:importmap_pins).to_proc,
                     **defaults, **levels)
  end

  def levels(before, after)
    rule.findings(path: "config/importmap.rb", before: before, after: after).map { |finding| finding.level.to_s }
  end

  def test_findings_for_added_removed_and_changed_facts
    assert_equal %w[minor], levels(nil, "pin \"a\", to: \"a.js\"\n")
    assert_equal %w[major], levels("pin \"a\", to: \"a.js\"\n", nil)
    assert_equal %w[patch], levels("pin \"a\", to: \"a.js\"\n", "pin \"a\", to: \"b.js\"\n")
  end

  def test_a_nil_level_is_not_detected
    assert_empty rule(changed: nil).findings(path: "p", before: "pin \"a\", to: \"a\"\n",
after: "pin \"a\", to: \"b\"\n")
  end

  def test_match_follows_the_glob
    assert_equal [ true, false ], [ "config/importmap.rb", "lib/config/importmap.rb" ].map { |path| rule.match?(path) }
  end

  def test_a_callable_level_sees_the_fact_value
    config = Semver::Rules::ALL.find { |candidate| candidate.id == "config" }
    findings = config.findings(path: "lib/appkit/configuration.rb", before: "", after: "attr_accessor :a\n")

    assert_equal "major", findings.first.level.to_s
  end

  def test_losing_a_config_default_is_major_and_gaining_one_is_not_detected
    config = Semver::Rules::ALL.find { |candidate| candidate.id == "config" }
    with = "attr_accessor :a\ndef initialize\n  @a = 1\nend\n"
    without = "attr_accessor :a\ndef initialize\nend\n"
    path = "lib/appkit/configuration.rb"

    assert_equal %w[major], config.findings(path: path, before: with, after: without).map { |f| f.level.to_s }
    assert_empty config.findings(path: path, before: without, after: with)
  end
end
