class HubsController < ApplicationController
  def show
    @hub = menu.hubs.find { |hub| hub.key.to_s == params[:id] }
    head :not_found unless @hub
  end
end
