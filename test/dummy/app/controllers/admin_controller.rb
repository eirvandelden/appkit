class AdminController < ApplicationController
  include Appkit::Authorization

  before_action :ensure_can_administer

  def index
  end

  def show
  end

  def edit
  end

  def update
    redirect_to menu.carry(admin_record_path(params[:id]))
  end
end
