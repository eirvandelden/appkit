require_relative "semver_test_helper"

class CheckTest < ActiveSupport::TestCase
  TEMPLATE = "lib/generators/appkit/install/templates/create_things.rb.tt".freeze

  def setup
    @fixture = GitFixture.new
    @fixture.branch("work")
  end

  def teardown
    @fixture.cleanup
  end

  def check
    Semver::Check.between(base: "main", head: "work", dir: @fixture.dir)
  end

  def breaking_pr(level)
    @fixture.write(TEMPLATE, "class CreateThings; end\n")
    @fixture.write("changelog.d/work.md", fragment_text(level)) if level
    @fixture.commit("Breaking")
  end

  def test_patch_fragment_below_floor_fails_with_file_and_level
    breaking_pr("patch")
    verdict = check.verdict

    assert_not_predicate verdict, :passed?
    assert_match(/#{Regexp.escape(TEMPLATE)}.*needs at least major/, verdict.lines.join)
  end

  def test_major_fragment_passes
    breaking_pr("major")

    assert_predicate check.verdict, :passed?
  end

  def test_no_fragment_and_no_findings_passes
    @fixture.write("README.md", "docs\n")
    @fixture.commit("Docs")

    assert_predicate check.verdict, :passed?
    assert_equal Semver::Level::PATCH, check.declared
  end

  def test_pending_fragment_on_base_does_not_authorize_a_patch_pr
    @fixture.checkout("main")
    @fixture.write("changelog.d/old.md", fragment_text("major"))
    @fixture.commit("Pending major on main")
    @fixture.checkout("work")
    @fixture.git(@fixture.dir, "merge", "-q", "main")
    breaking_pr(nil)

    assert_not_predicate check.verdict, :passed?
  end

  def test_nested_fragment_path_is_refused
    @fixture.write(TEMPLATE, "class CreateThings; end\n")
    @fixture.write("changelog.d/feature/work.md", fragment_text("major"))
    @fixture.commit("Nested fragment")

    error = assert_raises(ArgumentError) { check.verdict }
    assert_match(%r{changelog\.d/feature/work\.md.*changelog\.d/<slug>\.md}, error.message)
  end

  def pending_major_on_main
    @fixture.checkout("main")
    @fixture.write("changelog.d/old.md", fragment_text("major"))
    @fixture.commit("Pending major on main")
    @fixture.checkout("work")
    @fixture.git(@fixture.dir, "merge", "-q", "main")
  end

  def test_deleting_a_pending_fragment_is_a_problem
    pending_major_on_main
    @fixture.remove("changelog.d/old.md")
    @fixture.commit("Drop the pending fragment")

    assert_match(%r{changelog\.d/old\.md.*deleted}, check.fragment_problems.join)
  end

  def test_lowering_a_pending_fragment_is_a_problem
    pending_major_on_main
    @fixture.write("changelog.d/old.md", fragment_text("patch"))
    @fixture.commit("Lower the pending fragment")

    assert_match(%r{changelog\.d/old\.md.*major.*patch}, check.fragment_problems.join)
  end

  def test_raising_a_pending_fragment_is_no_problem
    @fixture.checkout("main")
    @fixture.write("changelog.d/old.md", fragment_text("patch"))
    @fixture.commit("Pending patch on main")
    @fixture.checkout("work")
    @fixture.git(@fixture.dir, "merge", "-q", "main")
    @fixture.write("changelog.d/old.md", fragment_text("minor"))
    @fixture.commit("Raise the pending fragment")

    assert_empty check.fragment_problems
  end

  def test_upgrading_added_to_a_pending_minor_fragment_is_a_problem
    @fixture.checkout("main")
    @fixture.write("changelog.d/old.md", fragment_text("minor"))
    @fixture.commit("Pending minor on main")
    @fixture.checkout("work")
    @fixture.git(@fixture.dir, "merge", "-q", "main")
    @fixture.write("changelog.d/old.md", fragment_text("minor", "### Upgrading\n1. Run x\n"))
    @fixture.commit("Add upgrading steps")

    assert_match(%r{changelog\.d/old\.md.*Upgrading.*major}, check.fragment_problems.join)
  end

  def test_no_problem_without_touching_pending_fragments
    breaking_pr("major")

    assert_empty check.fragment_problems
  end

  def test_override_in_the_fragment_passes
    @fixture.write(TEMPLATE, "class CreateThings; end\n")
    @fixture.write("changelog.d/work.md",
"---\nlevel: patch\noverrides:\n  migrations: not a table\n---\n### Fixed\n- x\n")
    @fixture.commit("Override")

    assert_predicate check.verdict, :passed?
  end
end
