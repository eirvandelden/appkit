module Appkit
  class FirstRunsController < ApplicationController
    layout "login"
    allow_unauthenticated_access

    before_action :prevent_running_after_setup

    def show
      @user = Appkit.config.user_class.call.new
    end

    def create
      user = Appkit::FirstRun.create!(user_params)
      start_new_session_for user

      redirect_to root_url
    end

    private
      def prevent_running_after_setup
        redirect_to root_url if Appkit.config.user_class.call.any?
      end

      def user_params
        params.require(:user).permit(:name, Appkit.config.email_attribute, :password)
      end
  end
end
