module Appkit
  module Authentication
    # @rbs module-self ::ActionController::Base
    module SessionLookup
      #: () -> untyped
      def find_session_by_cookie
        if token = cookies.signed[:session_token]
          # Session is owned by the host app, so the shipped signatures cannot name it.
          Session.find_by(token: token) # steep:ignore UnknownConstant
        end
      end
    end
  end
end
