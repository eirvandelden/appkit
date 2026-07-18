module Appkit
  class PushSubscription < ActiveRecord::Base
    self.table_name = "appkit_push_subscriptions"

    belongs_to :user

    validates :endpoint, presence: true, uniqueness: true
  end
end
