module Appkit
  class SessionExpiryJob < ActiveJob::Base
    def perform
      Appkit.config.session_class.call.expire_stale!
    end
  end
end
