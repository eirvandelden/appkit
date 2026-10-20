module Appkit
  # The host's ApplicationController, which includes Appkit::Authentication, is the real superclass.
  # @rbs inherits ::ActionController::Base
  class PreferencesController < ApplicationController # steep:ignore UnknownConstant
    # @rbs!
    #   include ::Appkit::Authentication
    #   extend ::Appkit::Authentication::ClassMethods

    helper_method :timezone_attribute_shown?, :locale_attribute_shown?

    #: () -> void
    def edit
      # Current is owned by the host app, so the shipped signatures cannot name it.
      @user = Current.user # steep:ignore UnknownConstant
    end

    #: () -> void
    def update
      # Current is owned by the host app, so the shipped signatures cannot name it.
      @user = Current.user # steep:ignore UnknownConstant

      if @user.update(preference_params)
        # edit_preferences_path is a route helper, defined by the host app's routes.
        redirect_to edit_preferences_path, notice: t(".success") # steep:ignore NoMethod
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private
      #: () -> ActionController::Parameters
      def preference_params
        permitted = %i[color_scheme light_theme dark_theme]
        # locale_attribute_shown? checks the attribute is set, but Steep cannot carry that across the call.
        permitted << Appkit.config.locale_attribute if locale_attribute_shown? # steep:ignore ArgumentTypeMismatch
        # timezone_attribute_shown? checks the attribute is set, but Steep cannot carry that across the call.
        permitted << Appkit.config.timezone_attribute if timezone_attribute_shown? # steep:ignore ArgumentTypeMismatch

        params.require(:user).permit(*permitted)
      end

      #: () -> bool?
      def locale_attribute_shown?
        # Current is owned by the host app, so the shipped signatures cannot name it.
        # steep:ignore:start
        Appkit.config.locale_attribute && Current.user.respond_to?(Appkit.config.locale_attribute)
        # steep:ignore:end
      end

      #: () -> bool?
      def timezone_attribute_shown?
        # Current is owned by the host app, so the shipped signatures cannot name it.
        # steep:ignore:start
        Appkit.config.timezone_attribute && Current.user.respond_to?(Appkit.config.timezone_attribute)
        # steep:ignore:end
      end
  end
end
