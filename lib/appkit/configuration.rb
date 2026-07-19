module Appkit
  class Configuration
    DEFAULT_ICONS = %w[/icon.svg /icon-192.png /icon-512.png /icon-mask-512.png].freeze

    attr_accessor :app_name, :email_attribute, :user_scope, :user_class, :first_run,
                  :icons, :sw_extra_cache_paths, :brand_color, :timezone_attribute, :locale_attribute,
                  :health_check_path, :session_expiry, :session_class

    def initialize
      @email_attribute = :email
      @user_scope = -> { User.all }
      @user_class = -> { "User".constantize }
      @session_class = -> { "Session".constantize }
      @first_run = ->(user_params) { user_class.call.create!(user_params.merge(role: :administrator)) }
      @icons = DEFAULT_ICONS
      @sw_extra_cache_paths = []
      @timezone_attribute = nil
      @locale_attribute = :locale
      @health_check_path = "healthz"
      # Matches Appkit::Authentication::SESSION_COOKIE_LIFETIME — the cookie
      # already caps a session at this age, so this default changes no real
      # user's experience; it only closes the gap for a session kept "alive"
      # by direct token replay instead of the cookie.
      @session_expiry = 1.year
    end
  end
end
