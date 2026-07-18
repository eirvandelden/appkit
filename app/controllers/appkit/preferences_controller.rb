module Appkit
  class PreferencesController < ApplicationController
    helper_method :timezone_attribute_shown?, :locale_attribute_shown?

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
        permitted = %i[color_scheme light_theme dark_theme]
        permitted << Appkit.config.locale_attribute if locale_attribute_shown?
        permitted << Appkit.config.timezone_attribute if timezone_attribute_shown?

        params.require(:user).permit(*permitted)
      end

      def timezone_attribute_shown?
        Appkit.config.timezone_attribute && Current.user.respond_to?(Appkit.config.timezone_attribute)
      end

      def locale_attribute_shown?
        Appkit.config.locale_attribute && Current.user.respond_to?(Appkit.config.locale_attribute)
      end
  end
end
