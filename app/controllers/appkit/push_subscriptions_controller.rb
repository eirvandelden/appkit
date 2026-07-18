module Appkit
  class PushSubscriptionsController < ApplicationController
    def create
      Current.user.push_subscriptions.find_or_create_by!(endpoint: push_subscription_params[:endpoint]) do |subscription|
        subscription.p256dh_key = push_subscription_params.dig(:keys, :p256dh)
        subscription.auth_key = push_subscription_params.dig(:keys, :auth)
        subscription.user_agent = request.user_agent
      end

      head :no_content
    end

    def destroy
      Current.user.push_subscriptions.find_by(endpoint: push_subscription_params[:endpoint])&.destroy

      head :no_content
    end

    private

    def push_subscription_params
      params.permit(:endpoint, keys: [ :p256dh, :auth ])
    end
  end
end
