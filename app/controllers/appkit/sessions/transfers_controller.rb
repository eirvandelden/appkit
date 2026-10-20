module Appkit
  module Sessions
    # The host's ApplicationController, which includes Appkit::Authentication, is the real superclass.
    # @rbs inherits ::ActionController::Base
    class TransfersController < ApplicationController # steep:ignore UnknownConstant
      # @rbs!
      #   include ::Appkit::Authentication
      #   extend ::Appkit::Authentication::ClassMethods

      layout "login"
      allow_unauthenticated_access

      #: () -> void
      def show
      end

      #: () -> void
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
