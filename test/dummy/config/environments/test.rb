Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = :none
  config.active_support.deprecation = :stderr
  config.action_controller.allow_forgery_protection = false
  config.log_level = :warn
  config.secret_key_base = "test_secret_key_base_only_used_for_the_dummy_app"
end
