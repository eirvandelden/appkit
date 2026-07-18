require "test_helper"

module Appkit
  class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
    test "creates a subscription scoped to the current user" do
      sign_in_as users(:alice)

      assert_difference -> { PushSubscription.count }, 1 do
        post push_subscription_url, params: {
          endpoint: "https://push.example.com/abc",
          keys: { p256dh: "p256dh-key", auth: "auth-key" }
        }
      end

      assert_response :no_content
      subscription = PushSubscription.last
      assert_equal users(:alice), subscription.user
      assert_equal "p256dh-key", subscription.p256dh_key
      assert_equal "auth-key", subscription.auth_key
    end

    test "does not create a duplicate row for a repeated endpoint" do
      sign_in_as users(:alice)
      post push_subscription_url, params: { endpoint: "https://push.example.com/abc", keys: { p256dh: "a", auth: "b" } }

      assert_no_difference -> { PushSubscription.count } do
        post push_subscription_url, params: { endpoint: "https://push.example.com/abc", keys: { p256dh: "a", auth: "b" } }
      end

      assert_response :no_content
    end

    test "create requires authentication" do
      post push_subscription_url, params: { endpoint: "https://push.example.com/abc", keys: { p256dh: "a", auth: "b" } }

      assert_response :redirect
    end

    test "destroy removes the subscription" do
      sign_in_as users(:alice)
      subscription = PushSubscription.create!(user: users(:alice), endpoint: "https://push.example.com/abc")

      assert_difference -> { PushSubscription.count }, -1 do
        delete push_subscription_url, params: { endpoint: subscription.endpoint }
      end

      assert_response :no_content
    end

    test "destroy requires authentication" do
      subscription = PushSubscription.create!(user: users(:alice), endpoint: "https://push.example.com/abc")

      delete push_subscription_url, params: { endpoint: subscription.endpoint }

      assert_response :redirect
      assert PushSubscription.exists?(subscription.id)
    end
  end
end
