require "test_helper"

class CiWorkflowTest < ActiveSupport::TestCase
  test "the types job runs rbs:check" do
    assert_includes commands, "bundle exec rake rbs:check"
  end

  test "the types job runs steep" do
    assert_includes commands, "bundle exec rake steep"
  end

  private
    def commands
      workflow.dig("jobs", "types", "steps").filter_map { |step| step["run"]&.strip }
    end

    def workflow
      @workflow ||= YAML.safe_load_file(Appkit::Engine.root.join(".github/workflows/ci.yml"))
    end
end
