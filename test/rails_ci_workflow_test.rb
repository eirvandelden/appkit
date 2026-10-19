require "test_helper"

class RailsCiWorkflowTest < ActiveSupport::TestCase
  test "test job installs javascript packages with npm ci before running tests" do
    names = steps.map { |step| step["name"] }
    install = steps.find { |step| step["name"] == "Install JavaScript packages" }

    assert_equal "if [ -f package-lock.json ]; then npm ci; fi", install["run"]
    assert_operator names.index("Install JavaScript packages"), :<, names.index("Run tests")
  end

  test "test job does not cache npm, since calling repos may have no lockfile" do
    assert_nil steps.find { |step| step["uses"].to_s.start_with?("actions/setup-node") }.dig("with", "cache")
  end

  private
    def steps
      workflow.dig("jobs", "test", "steps")
    end

    def workflow
      @workflow ||= YAML.safe_load_file(Appkit::Engine.root.join(".github/workflows/rails-ci.yml"))
    end
end
