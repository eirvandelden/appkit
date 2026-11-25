require_relative "semver_test_helper"

class WorkflowsTest < ActiveSupport::TestCase
  def workflow(name)
    YAML.safe_load_file(File.expand_path("../../.github/workflows/#{name}.yml", __dir__))
  end

  def test_release_workflow_uses_concurrency_group_without_cancel
    release = workflow("release")

    assert_equal "release", release["concurrency"]["group"]
    assert_not release["concurrency"]["cancel-in-progress"]
    assert_equal "write", release["permissions"]["contents"]
    assert_equal 0, release.dig("jobs", "release", "steps", 0, "with", "fetch-depth")
    assert release[true].key?("workflow_dispatch")
  end

  def test_check_workflow_runs_on_pull_request
    check = workflow("changelog-check")

    assert check[true].key?("pull_request")
    assert_equal "read", check["permissions"]["contents"]
  end
end
