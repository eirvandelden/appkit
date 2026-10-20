module Appkit
  # @rbs module-self ::ActiveRecord::Base
  module Authenticatable
    extend ActiveSupport::Concern

    # Rails class macros run on the including class; the available RBS does not describe them.
    # steep:ignore:start
    included do
      has_many :sessions, dependent: :destroy
      has_many :push_subscriptions, class_name: "Appkit::PushSubscription", dependent: :destroy
      has_secure_password
    end
    # steep:ignore:end

    #: () -> untyped
    def deactivate!
      transaction do
        # sessions comes from the host app's table or association.
        sessions.delete_all # steep:ignore NoMethod
        update!(Appkit.config.email_attribute => deactivated_email_address, active: false)
      end
    end

    private
      #: () -> String
      def deactivated_email_address
        email_attribute_value.gsub(/@/, "-deactivated-#{SecureRandom.uuid}@")
      end

      #: () -> String
      def email_attribute_value
        public_send(Appkit.config.email_attribute)
      end
  end
end
