module Appkit
  module Authentication
    module SessionLookup
      def find_session_by_cookie
        if token = cookies.signed[:session_token]
          Session.find_by(token: token)
        end
      end
    end
  end
end
