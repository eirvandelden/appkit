Rails.application.routes.draw do
  root "home#index"
  get "admin", to: "admin#index", as: :admin

  mount Appkit::Engine => "/"
end
