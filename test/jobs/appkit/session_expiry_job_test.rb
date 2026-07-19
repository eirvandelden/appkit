require "test_helper"

module Appkit
  class SessionExpiryJobTest < ActiveJob::TestCase
    test "destroys sessions idle past the configured expiry" do
      stale = sessions(:bob_session)
      stale.update!(last_active_at: (Appkit.config.session_expiry + 1.day).ago)

      SessionExpiryJob.perform_now

      assert_raises(ActiveRecord::RecordNotFound) { stale.reload }
    end

    test "leaves sessions within the configured expiry alone" do
      fresh = sessions(:bob_session)
      fresh.update!(last_active_at: (Appkit.config.session_expiry - 1.day).ago)

      SessionExpiryJob.perform_now

      assert fresh.reload.persisted?
    end
  end
end
