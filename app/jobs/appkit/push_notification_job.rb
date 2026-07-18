module Appkit
  class PushNotificationJob < ActiveJob::Base
    # Injectable so tests can substitute a fake without a mocking library; the
    # engine's own dependency, always WebPush at runtime.
    class_attribute :gateway, default: WebPush

    def perform(push_subscription, payload)
      gateway.payload_send(**delivery_args(push_subscription, payload))
    rescue WebPush::ExpiredSubscription
      push_subscription.destroy
    end

    private
      def delivery_args(push_subscription, payload)
        {
          message: JSON.generate(payload),
          endpoint: push_subscription.endpoint,
          p256dh: push_subscription.p256dh_key,
          auth: push_subscription.auth_key,
          vapid: vapid_credentials
        }
      end

      def vapid_credentials
        {
          subject: Rails.application.credentials.dig(:web_push, :subject),
          public_key: Rails.application.credentials.dig(:web_push, :vapid_public_key),
          private_key: Rails.application.credentials.dig(:web_push, :vapid_private_key)
        }
      end
  end
end
