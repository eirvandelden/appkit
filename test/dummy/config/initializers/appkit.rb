Appkit.configure do |config|
  config.app_name = -> { "Dummy" }
  config.brand_color = "#1a73e8"
  # Non-default on purpose: proves health_check_path actually changes the
  # mounted route, rather than just being a settable attribute.
  config.health_check_path = "status"
end
