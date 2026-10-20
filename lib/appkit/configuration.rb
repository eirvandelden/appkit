module Appkit
  class Configuration
    DEFAULT_ICONS = %w[/icon.svg /icon-192.png /icon-512.png /icon-mask-512.png].freeze #: Array[String]

    attr_accessor :app_name #: (String | ^() -> String)?
    attr_accessor :email_attribute #: Symbol
    attr_accessor :user_scope #: ^() -> untyped
    attr_accessor :user_class #: ^() -> untyped
    attr_accessor :session_class #: ^() -> untyped
    attr_accessor :first_run #: ^(untyped) -> untyped
    attr_accessor :icons #: Array[String]
    attr_accessor :sw_extra_cache_paths #: Array[String]
    attr_accessor :brand_color #: String?
    attr_accessor :timezone_attribute #: Symbol?
    attr_accessor :locale_attribute #: Symbol
    attr_accessor :health_check_path #: String
    attr_accessor :session_expiry #: ActiveSupport::Duration

    #: () -> void
    def initialize
      @email_attribute = :email
      # User is owned by the host app, so the shipped signatures cannot name it.
      @user_scope = -> { User.all } # steep:ignore UnknownConstant
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

    #: () -> String
    def app_display_name
      AppName.new(app_name).to_s
    end
  end
end
