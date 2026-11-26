require_relative "semver_test_helper"

class SurfaceChangeTest < ActiveSupport::TestCase
  TEMPLATES = "lib/generators/appkit/install/templates".freeze

  def setup
    @fixture = GitFixture.new
    @fixture.write("config/routes.rb", "Rails.application.routes.draw do\n  resource :session\nend\n")
    @fixture.write("sig/appkit/a.rbs", "module Appkit\n  class A\n    def go: () -> void\n  end\nend\n")
    @fixture.commit("Surface")
    @fixture.branch("work")
  end

  def teardown
    @fixture.cleanup
  end

  def change(base: "main")
    Semver::SurfaceChange.between(base: base, head: "work", dir: @fixture.dir)
  end

  def test_added_template_floor_is_major
    @fixture.write("#{TEMPLATES}/create_things.rb.tt", "class CreateThings; end\n")
    @fixture.commit("Add migration")

    assert_equal Semver::Level::MAJOR, change.findings.floor
    assert_equal "migrations", change.findings.first.rule
  end

  def test_removed_route_floor_is_major
    @fixture.write("config/routes.rb", "Rails.application.routes.draw do\nend\n")
    @fixture.commit("Drop route")

    assert_equal Semver::Level::MAJOR, change.findings.floor
  end

  def test_removing_a_resource_action_floor_is_major
    @fixture.write("config/routes.rb",
"Rails.application.routes.draw do\n  resource :session, only: %i[new create destroy]\nend\n")
    @fixture.commit("Base routes")
    @fixture.checkout("main")
    @fixture.merge("work")
    @fixture.branch("work2")
    @fixture.write("config/routes.rb",
"Rails.application.routes.draw do\n  resource :session, only: %i[new create]\nend\n")
    @fixture.commit("Drop destroy")

    assert_equal Semver::Level::MAJOR,
Semver::SurfaceChange.between(base: "main", head: "work2", dir: @fixture.dir).findings.floor
  end

  def test_changing_a_workflow_input_type_floor_is_major
    path = ".github/workflows/rails-ci.yml"
    spec = ->(type) {
 "on:\n  workflow_call:\n    inputs:\n      flag:\n        type: #{type}\n        default: true\n" }
    @fixture.write(path, spec.call("boolean"))
    @fixture.commit("Workflow")
    @fixture.checkout("main")
    @fixture.merge("work")
    @fixture.branch("work2")
    @fixture.write(path, spec.call("string"))
    @fixture.commit("Change type")

    assert_equal Semver::Level::MAJOR,
Semver::SurfaceChange.between(base: "main", head: "work2", dir: @fixture.dir).findings.floor
  end

  def test_added_paths_lists_files_the_branch_adds_under_a_prefix
    @fixture.write("changelog.d/new.md", "x\n")
    @fixture.write("other/new.md", "x\n")
    @fixture.commit("Add files")

    assert_equal [ "changelog.d/new.md" ], change.added_paths("changelog.d")
  end

  def test_renaming_a_route_helper_floor_is_major
    @fixture.write("config/routes.rb",
"Rails.application.routes.draw do\n  resource :session, as: :login\nend\n")
    @fixture.commit("Rename the helper")

    assert_equal Semver::Level::MAJOR, change.findings.floor
  end

  def test_added_route_floor_is_minor
    @fixture.write("config/routes.rb",
"Rails.application.routes.draw do\n  resource :session\n  resource :other\nend\n")
    @fixture.commit("Add route")

    assert_equal Semver::Level::MINOR, change.findings.floor
  end

  def test_changed_rbs_signature_floor_is_major
    @fixture.write("sig/appkit/a.rbs", "module Appkit\n  class A\n    def go: (Integer) -> void\n  end\nend\n")
    @fixture.commit("Change signature")

    assert_equal Semver::Level::MAJOR, change.findings.floor
  end

  def test_rename_is_remove_plus_add
    @fixture.remove("sig/appkit/a.rbs")
    @fixture.write("sig/appkit/b.rbs", "module Appkit\n  class B\n    def go: () -> void\n  end\nend\n")
    @fixture.commit("Rename class")

    assert_equal %w[major minor], change.findings.map { |finding| finding.level.to_s }.uniq.sort
  end

  def test_ignores_changes_main_made_after_the_fork
    @fixture.checkout("main")
    @fixture.write("config/routes.rb", "Rails.application.routes.draw do\nend\n")
    @fixture.commit("Main drops a route")
    @fixture.checkout("work")
    @fixture.write("README.md", "docs\n")
    @fixture.commit("Docs")

    assert_equal Semver::Level::PATCH, change.findings.floor
  end

  def test_overridden_rule_line_shows_the_reason
    @fixture.write("config/routes.rb", "Rails.application.routes.draw do\nend\n")
    @fixture.commit("Drop route")
    verdict = change.check(Semver::Level::PATCH, overrides: { "routes" => "internal route" })

    assert_predicate verdict, :passed?
    assert_match(/overridden: internal route/, verdict.lines.join)
  end

  def test_verdict_fails_and_names_the_file_and_level
    @fixture.write("config/routes.rb", "Rails.application.routes.draw do\nend\n")
    @fixture.commit("Drop route")
    verdict = change.check(Semver::Level::PATCH)

    assert_not_predicate verdict, :passed?
    assert_match(%r{FAIL config/routes.rb.*needs at least major}, verdict.lines.join)
  end

  def test_snapshot_reads_paths_and_nil_for_an_absent_file
    snapshot = Semver::Snapshot.at("main", dir: @fixture.dir)

    assert_includes snapshot.paths, "config/routes.rb"
    assert_nil snapshot.read("nope.rb")
  end
end
