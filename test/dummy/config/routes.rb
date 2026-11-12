Rails.application.routes.draw do
  root "home#index"
  get "admin", to: "admin#index", as: :admin
  get "admin/:id", to: "admin#show", as: :admin_record
  get "admin/:id/edit", to: "admin#edit", as: :edit_admin_record
  patch "admin/:id", to: "admin#update"
  get "inbox", to: "inbox#index", as: :inbox
  get "settings", to: "settings#index", as: :settings
  resources :hubs, only: :show

  mount Appkit::Engine => "/"
end
