require "test_helper"

module Appkit
  class PushSubscriptionTest < ActiveSupport::TestCase
    test "requires an endpoint" do
      subscription = PushSubscription.new(user: users(:alice))

      assert_not subscription.valid?
      assert_includes subscription.errors[:endpoint], "can't be blank"
    end

    test "endpoints are unique" do
      PushSubscription.create!(user: users(:alice), endpoint: "https://push.example.com/abc")
      duplicate = PushSubscription.new(user: users(:bob), endpoint: "https://push.example.com/abc")

      assert_not duplicate.valid?
      assert_includes duplicate.errors[:endpoint], "has already been taken"
    end

    test "belongs to a user" do
      subscription = PushSubscription.create!(user: users(:alice), endpoint: "https://push.example.com/xyz")

      assert_equal users(:alice), subscription.user
    end
  end
end
