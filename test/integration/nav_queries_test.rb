require "test_helper"

class NavQueriesTest < ActionDispatch::IntegrationTest
  setup do
    users(:alice).update!(role: :administrator)
    sign_in_as users(:alice)
  end

  test "nav_runs_each_current_hub_count_once" do
    counts = count_queries { get hub_url("work") }

    assert_equal 2, counts.size
    assert_equal [ 1, 1 ], counts.values
  end

  test "a hub without pages runs no count" do
    assert_empty count_queries { get root_url }
  end

  private
    def count_queries(&block)
      counts = Hash.new(0)
      subscriber = ->(*, payload) {
 counts[[ payload[:sql], payload[:type_casted_binds] ]] += 1 if payload[:sql].include?("COUNT(") }
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record", &block)
      counts
    end
end
