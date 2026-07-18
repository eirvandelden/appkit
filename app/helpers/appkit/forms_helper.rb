module Appkit
  module FormsHelper
    def auto_submit_form_with(**attributes, &block)
      data = attributes.delete(:data) || {}
      data[:controller] = "auto-submit #{data[:controller]}".strip

      form_with(**attributes, data: data, &block)
    end
  end
end
