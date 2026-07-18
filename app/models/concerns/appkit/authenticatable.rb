module Appkit
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      has_many :sessions, dependent: :destroy
      has_many :push_subscriptions, class_name: "Appkit::PushSubscription", dependent: :destroy
      has_secure_password
    end

    def deactivate!
      transaction do
        sessions.delete_all
        update!(Appkit.config.email_attribute => deactivated_email_address, active: false)
      end
    end

    private
      def deactivated_email_address
        email_attribute_value.gsub(/@/, "-deactivated-#{SecureRandom.uuid}@")
      end

      def email_attribute_value
        public_send(Appkit.config.email_attribute)
      end
  end
end
