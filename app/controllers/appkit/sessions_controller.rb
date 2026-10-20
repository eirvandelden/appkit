module Appkit
  # The host's ApplicationController, which includes Appkit::Authentication, is the real superclass.
  # @rbs inherits ::ActionController::Base
  class SessionsController < ApplicationController # steep:ignore UnknownConstant
    # @rbs!
    #   include ::Appkit::Authentication
    #   extend ::Appkit::Authentication::ClassMethods

    layout "login"
    require_unauthenticated_access only: %i[new create]
    # The rate_limit lambda runs on the controller instance; Steep gives it the class as self.
    # steep:ignore:start
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rejection :too_many_requests }
    # steep:ignore:end

    before_action :ensure_user_exists, only: :new

    #: () -> void
    def new
    end

    #: () -> void
    def create
      if user = authenticate_user
        start_new_session_for user
        redirect_to post_authenticating_url
      else
        render_rejection :unauthorized
      end
    end

    #: () -> void
    def destroy
      reset_authentication

      # root_url is a route helper, defined by the host app's routes.
      redirect_to root_url # steep:ignore NoMethod
    end

    private
      #: () -> void
      def ensure_user_exists
        # first_run_url is a route helper, defined by the host app's routes.
        redirect_to first_run_url if Appkit.config.user_class.call.none? # steep:ignore NoMethod
      end

      #: () -> untyped
      def authenticate_user
        Appkit.config.user_scope.call.authenticate_by(
          Appkit.config.email_attribute => params[:email_address],
          password: params[:password]
        )
      end

      #: (Symbol) -> void
      def render_rejection(status)
        flash[:alert] = t("appkit.sessions.rejection")
        render :new, status: status
      end
  end
end
