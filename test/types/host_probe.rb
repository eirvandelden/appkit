# Steep checks this file as a host app would use appkit (the :host target in the Steepfile).
# It is never loaded at runtime.

ApplicationController.allow_unauthenticated_access only: :show
ApplicationController.require_unauthenticated_access
Session.start!(user_agent: nil, ip_address: nil)
Session.expire_stale!
User.find_by_transfer_id("transfer-id")

Appkit.configure do |config|
  config.app_name = "My App"
  config.app_name = -> { "My App" }
  config.app_name = -> { nil }
  config.app_name = -> { :MyApp }
  config.locale_attribute = nil
  config.timezone_attribute = :time_zone
end
