module Appkit
  # @rbs module-self ::ActionView::Base
  module ThemeHelper
    #: () -> Hash[Symbol, untyped]
    def theme_attributes
      # Current is owned by the host app, so the shipped signatures cannot name it.
      return {} unless Current.user # steep:ignore UnknownConstant

      # Current is owned by the host app, so the shipped signatures cannot name it.
      color_scheme = Current.user.color_scheme # steep:ignore UnknownConstant
      # Current is owned by the host app, so the shipped signatures cannot name it.
      light = Current.user.light_theme # steep:ignore UnknownConstant
      # Current is owned by the host app, so the shipped signatures cannot name it.
      dark = Current.user.dark_theme # steep:ignore UnknownConstant

      attrs = {
        "data-color-scheme": color_scheme,
        "data-light-theme": light,
        "data-dark-theme": dark
      }

      case color_scheme
      when "light"
        attrs[:"data-theme"] = light
      when "dark"
        attrs[:"data-theme"] = dark
      end

      attrs
    end

    #: () -> Hash[Symbol, untyped]
    def saved_theme_attributes
      theme_attributes.except(:"data-theme")
    end
  end
end
