module Appkit
  # @rbs module-self ::ActiveRecord::Base
  module Transferable
    extend ActiveSupport::Concern

    EXPIRY_DURATION = 4.hours #: ActiveSupport::Duration

    module ClassMethods
      #: (untyped) -> untyped
      def find_by_transfer_id(id)
        # find_signed is an Active Record class method; ClassMethods has no singleton self type.
        find_signed(id, purpose: :transfer) # steep:ignore NoMethod
      end
    end

    #: () -> String
    def transfer_id
      signed_id(purpose: :transfer, expires_in: EXPIRY_DURATION)
    end
  end
end
