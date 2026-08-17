class HomeController < ApplicationController
  def index
    render html: "signed in as #{Current.user.email} via session #{Current.session.id}".html_safe, layout: true
  end
end
