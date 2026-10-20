module Appkit
  # @rbs module-self ::ActiveRecord::Base
  module SessionBehavior
    extend ActiveSupport::Concern

    ACTIVITY_REFRESH_RATE = 1.hour #: ActiveSupport::Duration

    # Rails class macros run on the including class; the available RBS does not describe them.
    # steep:ignore:start
    included do
      has_secure_token

      validates :token, presence: true, uniqueness: true
      validates :last_active_at, presence: true

      before_validation { self.last_active_at ||= Time.now }
    end
    # steep:ignore:end

    module ClassMethods
      #: (user_agent: String?, ip_address: String?) -> untyped
      def start!(user_agent:, ip_address:)
        # create! is an Active Record class method; ClassMethods has no singleton self type.
        create! user_agent: user_agent, ip_address: ip_address # steep:ignore NoMethod
      end

      # A cookie only stops renewing once the browser drops it; a stolen token
      # replayed directly against the server never does. This is the backstop:
      # sessions idle past the configured expiry are destroyed regardless.
      #: () -> untyped
      def expire_stale!
        # where is an Active Record class method; ClassMethods has no singleton self type.
        where(last_active_at: ...Appkit.config.session_expiry.ago).destroy_all # steep:ignore NoMethod
      end
    end

    #: (user_agent: String?, ip_address: String?) -> untyped
    def resume(user_agent:, ip_address:)
      # last_active_at comes from the host app's table or association.
      return unless last_active_at.before?(ACTIVITY_REFRESH_RATE.ago) # steep:ignore NoMethod

      update! user_agent: user_agent, ip_address: ip_address, last_active_at: Time.now
    end
  end
end
