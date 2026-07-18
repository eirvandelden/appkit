module Appkit
  class Configuration
    DEFAULT_ICONS = %w[/icon.svg /icon-192.png /icon-512.png /icon-mask-512.png].freeze

    attr_accessor :app_name, :email_attribute, :user_scope, :icons, :sw_extra_cache_paths

    def initialize
      @email_attribute = :email
      @user_scope = -> { User.all }
      @icons = DEFAULT_ICONS
      @sw_extra_cache_paths = []
    end
  end
end
