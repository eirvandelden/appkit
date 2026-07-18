module Appkit
  module SessionBehavior
    extend ActiveSupport::Concern

    ACTIVITY_REFRESH_RATE = 1.hour

    included do
      has_secure_token

      validates :token, presence: true, uniqueness: true
      validates :last_active_at, presence: true

      before_validation { self.last_active_at ||= Time.now }
    end

    class_methods do
      def start!(user_agent:, ip_address:)
        create! user_agent: user_agent, ip_address: ip_address
      end
    end

    def resume(user_agent:, ip_address:)
      return unless last_active_at.before?(ACTIVITY_REFRESH_RATE.ago)

      update! user_agent: user_agent, ip_address: ip_address, last_active_at: Time.now
    end
  end
end
