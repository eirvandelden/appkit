class AdminController < ApplicationController
  include Appkit::Authorization

  before_action :ensure_can_administer

  def index
  end

  def show
    render html: "admin record".html_safe, layout: true
  end
end
