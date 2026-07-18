require "test_helper"

module Appkit
  class PushNotificationJobTest < ActiveJob::TestCase
    class FakeGateway
      attr_reader :calls

      def initialize(raise_with: nil)
        @calls = []
        @raise_with = raise_with
      end

      def payload_send(**kwargs)
        @calls << kwargs
        raise @raise_with if @raise_with
      end
    end

    VAPID_CREDENTIALS = {
      web_push: { subject: "mailto:test@example.com", vapid_public_key: "public-key", vapid_private_key: "private-key" }
    }.freeze

    setup { stub_vapid_credentials }
    teardown do
      PushNotificationJob.gateway = WebPush
      Rails.application.singleton_class.remove_method(:credentials)
    end

    test "sends the payload with the subscription's keys and VAPID credentials" do
      subscription = PushSubscription.create!(
        user: users(:alice), endpoint: "https://push.example.com/abc",
        p256dh_key: "p256dh-key", auth_key: "auth-key"
      )
      gateway = FakeGateway.new
      PushNotificationJob.gateway = gateway

      PushNotificationJob.perform_now(subscription, { title: "Hello", body: "World" })

      call = gateway.calls.sole
      assert_equal "https://push.example.com/abc", call[:endpoint]
      assert_equal "p256dh-key", call[:p256dh]
      assert_equal "auth-key", call[:auth]
      assert_equal({ title: "Hello", body: "World" }, JSON.parse(call[:message], symbolize_names: true))
      assert_equal({
        subject: "mailto:test@example.com", public_key: "public-key", private_key: "private-key"
      }, call[:vapid])
    end

    test "destroys the subscription when WebPush reports it as expired" do
      subscription = PushSubscription.create!(user: users(:alice), endpoint: "https://push.example.com/gone")
      expired = WebPush::ExpiredSubscription.new(Struct.new(:body).new("gone"), "push.example.com")
      PushNotificationJob.gateway = FakeGateway.new(raise_with: expired)

      PushNotificationJob.perform_now(subscription, { title: "Hi" })

      assert_not PushSubscription.exists?(subscription.id)
    end

    private
      def stub_vapid_credentials
        fake_credentials = Object.new
        fake_credentials.define_singleton_method(:dig) { |*keys| VAPID_CREDENTIALS.dig(*keys) }
        Rails.application.define_singleton_method(:credentials) { fake_credentials }
      end
  end
end
