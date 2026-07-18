require "test_helper"

module Appkit
  class TransferableTest < ActiveSupport::TestCase
    test "transfer_id round-trips to the same user" do
      user = users(:alice)

      assert_equal user, User.find_by_transfer_id(user.transfer_id)
    end

    test "a tampered transfer_id does not resolve to a user" do
      user = users(:alice)

      assert_nil User.find_by_transfer_id(user.transfer_id.reverse)
    end
  end
end
