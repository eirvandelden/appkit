class AdminController < ApplicationController
  include Appkit::Authorization

  before_action :ensure_can_administer

  def index
    head :ok
  end
end
