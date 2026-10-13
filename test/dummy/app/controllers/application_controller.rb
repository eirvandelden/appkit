class ApplicationController < ActionController::Base
  include Appkit::Authentication
  include Appkit::VersionHeaders

  around_action :switch_locale

  private
    def switch_locale(&action)
      I18n.with_locale(params[:locale] || I18n.default_locale, &action)
    end
end
