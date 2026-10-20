module Appkit
  # @rbs module-self ::ActionController::Base
  module Authorization
    private
      #: () -> void
      def ensure_can_administer
        # Current is owned by the host app, so the shipped signatures cannot name it.
        head :forbidden unless Current.user.can_administer? # steep:ignore UnknownConstant
      end

      #: () -> void
      def ensure_current_user
        head :forbidden unless @user.current?
      end
  end
end
