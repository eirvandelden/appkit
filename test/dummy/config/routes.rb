Rails.application.routes.draw do
  root "home#index"

  mount Appkit::Engine => "/"
end
