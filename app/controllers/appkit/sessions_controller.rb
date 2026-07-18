module Appkit
  class SessionsController < ApplicationController
    layout "login"
    allow_unauthenticated_access only: %i[new create]
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rejection :too_many_requests }

    def new
    end

    def create
      if user = authenticate_user
        start_new_session_for user
        redirect_to post_authenticating_url
      else
        render_rejection :unauthorized
      end
    end

    def destroy
      reset_authentication

      redirect_to root_url
    end

    private
      def authenticate_user
        Appkit.config.user_scope.call.authenticate_by(
          Appkit.config.email_attribute => params[:email_address],
          password: params[:password]
        )
      end

      def render_rejection(status)
        flash[:alert] = t("appkit.sessions.rejection")
        render :new, status: status
      end
  end
end
