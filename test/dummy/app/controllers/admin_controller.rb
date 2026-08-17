class AdminController < ApplicationController
  include Appkit::Authorization

  before_action :ensure_can_administer

  def index
    render plain: "admin area", layout: true
  end
end
