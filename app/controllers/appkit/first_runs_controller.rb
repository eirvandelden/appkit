module Appkit
  # The host's ApplicationController, which includes Appkit::Authentication, is the real superclass.
  # @rbs inherits ::ActionController::Base
  class FirstRunsController < ApplicationController # steep:ignore UnknownConstant
    # @rbs!
    #   include ::Appkit::Authentication
    #   extend ::Appkit::Authentication::ClassMethods

    layout "login"
    allow_unauthenticated_access

    before_action :prevent_running_after_setup

    #: () -> void
    def show
      @user = Appkit.config.user_class.call.new
    end

    #: () -> void
    def create
      user = Appkit::FirstRun.create!(user_params)
      start_new_session_for user

      # root_url is a route helper, defined by the host app's routes.
      redirect_to root_url # steep:ignore NoMethod
    end

    private
      #: () -> void
      def prevent_running_after_setup
        # root_url is a route helper, defined by the host app's routes.
        redirect_to root_url if Appkit.config.user_class.call.any? # steep:ignore NoMethod
      end

      #: () -> ActionController::Parameters
      def user_params
        params.require(:user).permit(:name, Appkit.config.email_attribute, :password)
      end
  end
end
