require "test_helper"

module Appkit
  module OkComputer
    class SolidQueueCheckTest < ActiveSupport::TestCase
      setup { SolidQueue::Process.delete_all }

      test "passes when a Solid Queue process has heartbeated recently" do
        SolidQueue::Process.create!(
          kind: "Worker", last_heartbeat_at: 1.minute.ago, pid: 1, name: "worker-a", created_at: Time.current
        )

        check = SolidQueueCheck.new
        check.run

        assert check.success?
      end

      test "fails with a mark_failure message when no process has a recent heartbeat" do
        check = SolidQueueCheck.new
        check.run

        assert_not check.success?
        assert_match(/no.*heartbeat/i, check.message)
      end

      test "fails when the only process heartbeat is older than the alive threshold" do
        SolidQueue::Process.create!(
          kind: "Worker", last_heartbeat_at: 1.hour.ago, pid: 1, name: "worker-b", created_at: Time.current
        )

        check = SolidQueueCheck.new
        check.run

        assert_not check.success?
      end
    end
  end
end
