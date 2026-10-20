module Appkit
  # The host's ApplicationController, which includes Appkit::Authentication, is the real superclass.
  # @rbs inherits ::ActionController::Base
  class PushSubscriptionsController < ApplicationController # steep:ignore UnknownConstant
    # @rbs!
    #   include ::Appkit::Authentication
    #   extend ::Appkit::Authentication::ClassMethods

    #: () -> void
    def create
      endpoint = push_subscription_params[:endpoint]

      # Current is owned by the host app, so the shipped signatures cannot name it.
      # steep:ignore:start
      Current.user.push_subscriptions.find_or_create_by!(endpoint: endpoint) do |subscription|
        subscription.p256dh_key = push_subscription_params.dig(:keys, :p256dh)
        subscription.auth_key = push_subscription_params.dig(:keys, :auth)
        subscription.user_agent = request.user_agent
      end
      # steep:ignore:end

      head :no_content
    end

    #: () -> void
    def destroy
      # Current is owned by the host app, so the shipped signatures cannot name it.
      # steep:ignore:start
      Current.user.push_subscriptions.find_by(endpoint: push_subscription_params[:endpoint])&.destroy
      # steep:ignore:end

      head :no_content
    end

    private

    #: () -> ActionController::Parameters
    def push_subscription_params
      params.permit(:endpoint, keys: [ :p256dh, :auth ])
    end
  end
end
