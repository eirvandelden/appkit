module Appkit
  class PushSubscriptionsController < ApplicationController
    def create
      Current.user.push_subscriptions.find_or_create_by!(endpoint: params[:endpoint]) do |subscription|
        subscription.p256dh_key = params.dig(:keys, :p256dh)
        subscription.auth_key = params.dig(:keys, :auth)
        subscription.user_agent = request.user_agent
      end

      head :no_content
    end

    def destroy
      Current.user.push_subscriptions.find_by(endpoint: params[:endpoint])&.destroy

      head :no_content
    end
  end
end
