module Appkit
  class PushNotificationJob < ActiveJob::Base
    # Injectable so tests can substitute a fake without a mocking library; the
    # engine's own dependency, always WebPush at runtime.
    class_attribute :gateway, default: WebPush

    #: (untyped, untyped) -> void
    def perform(push_subscription, payload)
      # class_attribute defines gateway at runtime.
      gateway.payload_send(**delivery_args(push_subscription, payload)) # steep:ignore NoMethod
    rescue WebPush::ExpiredSubscription
      push_subscription.destroy
    end

    private
      #: (untyped, untyped) -> Hash[Symbol, untyped]
      def delivery_args(push_subscription, payload)
        {
          message: JSON.generate(payload),
          endpoint: push_subscription.endpoint,
          p256dh: push_subscription.p256dh_key,
          auth: push_subscription.auth_key,
          vapid: vapid_credentials
        }
      end

      #: () -> Hash[Symbol, untyped]
      def vapid_credentials
        {
          # The credentials RBS has no dig.
          subject: Rails.application.credentials.dig(:web_push, :subject), # steep:ignore NoMethod
          # The credentials RBS has no dig.
          public_key: Rails.application.credentials.dig(:web_push, :vapid_public_key), # steep:ignore NoMethod
          # The credentials RBS has no dig.
          private_key: Rails.application.credentials.dig(:web_push, :vapid_private_key) # steep:ignore NoMethod
        }
      end
  end
end
