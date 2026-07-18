class User < ActiveRecord::Base
  include Appkit::Authenticatable
  include Appkit::Transferable

  enum :role, { member: 0, administrator: 1 }

  # Exercises Appkit.config.email_attribute with a non-default column name,
  # without requiring a second physical column in the dummy schema.
  alias_attribute :email_address, :email

  # Exercises Appkit::Authorization#ensure_can_administer; app-side per the design.
  def can_administer?
    administrator?
  end
end
