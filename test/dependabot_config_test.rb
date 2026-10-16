require "test_helper"

class DependabotConfigTest < ActiveSupport::TestCase
  test "declares version 2 with a bundler and a github-actions update at the root" do
    assert_equal 2, config["version"]
    assert_equal "/", update_for("bundler")["directory"]
    assert_equal "/", update_for("github-actions")["directory"]
  end

  test "bundler waits seven days after a release" do
    assert_equal 7, update_for("bundler").dig("cooldown", "default-days")
  end

  test "bundler includes indirect gems" do
    assert_equal [ { "dependency-type" => "all" } ], update_for("bundler")["allow"]
  end

  test "github-actions scans the workflows and waits seven days after a release" do
    update = update_for("github-actions")

    assert_equal "/", update["directory"]
    assert_equal 7, update.dig("cooldown", "default-days")
  end

  test "no update is restricted by type, ignore rule or versioning strategy" do
    restricting = %w[ignore versioning-strategy] + %w[semver-major-days semver-minor-days semver-patch-days]

    config["updates"].each do |update|
      assert_empty restricting & (update.keys + update.fetch("cooldown", {}).keys)
    end
  end

  test "stays minimal" do
    extras = %w[groups labels reviewers assignees ignore]

    config["updates"].each { |update| assert_empty extras & update.keys }
  end

  private
    def config
      @config ||= YAML.safe_load_file(Appkit::Engine.root.join(".github/dependabot.yml"))
    end

    def update_for(ecosystem)
      config["updates"].find { |update| update["package-ecosystem"] == ecosystem }
    end
end
