module Appkit
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      has_many :sessions, dependent: :destroy
      has_secure_password
    end
  end
end
