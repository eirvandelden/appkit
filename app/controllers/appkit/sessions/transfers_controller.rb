module Appkit
  module Sessions
    class TransfersController < ApplicationController
      layout "login"
      allow_unauthenticated_access

      def show
      end

      def update
        if user = Appkit.config.user_scope.call.find_by_transfer_id(params[:id])
          start_new_session_for user
          redirect_to post_authenticating_url
        else
          head :bad_request
        end
      end
    end
  end
end
