module Appkit
  module ThemeHelper
    def theme_attributes
      return {} unless Current.user

      color_scheme = Current.user.color_scheme
      light = Current.user.light_theme
      dark = Current.user.dark_theme

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

    def saved_theme_attributes
      theme_attributes.except(:"data-theme")
    end
  end
end
