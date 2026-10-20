module Appkit
  # @rbs module-self ::ActiveRecord::Base
  module UserTheming
    extend ActiveSupport::Concern

    # Rails class macros run on the including class; the available RBS does not describe them.
    # steep:ignore:start
    included do
      enum :color_scheme, { system: 0, light: 1, dark: 2 }, default: :system
      enum :light_theme,  { "solunized-white": 0, "solunized-light": 1 }, default: :"solunized-light"
      enum :dark_theme,   { "solunized-black": 0, "solunized-dark": 1 }, default: :"solunized-dark"
    end
    # steep:ignore:end
  end
end
