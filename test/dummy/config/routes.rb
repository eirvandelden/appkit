Rails.application.routes.draw do
  root "home#index"
  get "admin", to: "admin#index", as: :admin
  resources :hubs, only: :show

  mount Appkit::Engine => "/"
end
