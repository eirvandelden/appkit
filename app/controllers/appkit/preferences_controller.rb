module Appkit
  class PreferencesController < ApplicationController
    helper_method :timezone_attribute_shown?

    def edit
      @user = Current.user
    end

    def update
      @user = Current.user

      if @user.update(preference_params)
        redirect_to edit_preferences_path, notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def preference_params
        permitted = %i[locale color_scheme light_theme dark_theme]
        permitted << :timezone if timezone_attribute_shown?

        params.require(:user).permit(*permitted)
      end

      def timezone_attribute_shown?
        Appkit.config.timezone_attribute && Current.user.respond_to?(Appkit.config.timezone_attribute)
      end
  end
end
