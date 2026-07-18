class User < ActiveRecord::Base
  include Appkit::Authenticatable

  # Exercises Appkit.config.email_attribute with a non-default column name,
  # without requiring a second physical column in the dummy schema.
  alias_attribute :email_address, :email
end
