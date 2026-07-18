Rails.application.routes.draw do
  resource :first_run, only: %i[show create], controller: "appkit/first_runs"

  resource :session, only: %i[new create destroy], controller: "appkit/sessions" do
    resources :transfers, only: %i[show update], controller: "appkit/sessions/transfers"
  end

  resources :qr_code, only: :show, controller: "appkit/qr_code"
end
