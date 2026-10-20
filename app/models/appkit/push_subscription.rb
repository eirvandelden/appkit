module Appkit
  class PushSubscription < ActiveRecord::Base
    # @rbs!
    #   attr_accessor endpoint: String
    #   attr_accessor p256dh_key: String
    #   attr_accessor auth_key: String
    #   attr_accessor user_agent: String?
    #   attr_accessor user: untyped

    self.table_name = "appkit_push_subscriptions"

    belongs_to :user

    validates :endpoint, presence: true, uniqueness: true
  end
end
