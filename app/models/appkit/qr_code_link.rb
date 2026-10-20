module Appkit
  class QrCodeLink
    attr_reader :url #: String

    #: (String) -> void
    def initialize(url)
      @url = url
    end

    #: () -> String
    def signed
      self.class.verifier.generate(@url, purpose: :qr_code)
    end

    #: (String) -> QrCodeLink
    def self.from_signed(signed)
      new verifier.verify(signed, purpose: :qr_code)
    end

    private
      class << self
        #: () -> ActiveSupport::MessageVerifier
        def verifier
          ActiveSupport::MessageVerifier.new(secret, url_safe: true)
        end

        #: () -> String
        def secret
          Rails.application.key_generator.generate_key("qr_codes")
        end
      end
  end
end
