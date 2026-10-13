module Appkit
  # Resolves the name shown to users, for the current locale: the host's
  # top-level `app_name` translation, then the configured name (a string or a
  # callable), then the host application module name split into words.
  class AppName
    def initialize(configured, host_module_name: Rails.application.class.module_parent_name)
      @configured = configured
      @host_module_name = host_module_name
    end

    def to_s
      translated || configured_name || host_module_name.to_s.titleize
    end

    private
      attr_reader :configured, :host_module_name

      def translated
        name = I18n.t(:app_name, default: nil, fallback: false)
        name if name.is_a?(String) && name.present?
      end

      def configured_name
        name = configured.respond_to?(:call) ? configured.call : configured
        name.presence&.to_s
      end
  end
end
