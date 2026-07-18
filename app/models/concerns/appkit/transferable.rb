module Appkit
  module Transferable
    extend ActiveSupport::Concern

    EXPIRY_DURATION = 4.hours

    class_methods do
      def find_by_transfer_id(id)
        find_signed(id, purpose: :transfer)
      end
    end

    def transfer_id
      signed_id(purpose: :transfer, expires_in: EXPIRY_DURATION)
    end
  end
end
