class AdminController < ApplicationController
  include Appkit::Authorization

  before_action :ensure_can_administer

  def index
    render html: "admin area".html_safe, layout: true
  end
end
