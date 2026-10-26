Rails.application.routes.draw do
  root "home#index"
  get "admin", to: "admin#index", as: :admin
  get "admin/:id", to: "admin#show", as: :admin_record
  resources :hubs, only: :show

  mount Appkit::Engine => "/"
end
