class Session < ActiveRecord::Base
  include Appkit::SessionBehavior

  belongs_to :user
end
