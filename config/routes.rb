Rails.application.routes.draw do
  resource :session, only: %i[new create destroy], controller: "appkit/sessions"
end
