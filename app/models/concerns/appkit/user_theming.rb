module Appkit
  module UserTheming
    extend ActiveSupport::Concern

    included do
      enum :color_scheme, { system: 0, light: 1, dark: 2 }, default: :system
      enum :light_theme,  { "solunized-white": 0, "solunized-light": 1 }, default: :"solunized-light"
      enum :dark_theme,   { "solunized-black": 0, "solunized-dark": 1 }, default: :"solunized-dark"
    end
  end
end
