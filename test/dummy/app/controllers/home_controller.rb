class HomeController < ApplicationController
  def index
    render plain: "signed in as #{Current.user.email} via session #{Current.session.id}"
  end
end
