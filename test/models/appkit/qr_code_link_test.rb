require "test_helper"

module Appkit
  class QrCodeLinkTest < ActiveSupport::TestCase
    test "round-trips a signed url" do
      link = QrCodeLink.new("https://example.com/session/transfers/abc123")

      round_tripped = QrCodeLink.from_signed(link.signed)

      assert_equal link.url, round_tripped.url
    end

    test "a tampered signature fails to verify" do
      link = QrCodeLink.new("https://example.com/session/transfers/abc123")
      tampered = link.signed.reverse

      assert_raises ActiveSupport::MessageVerifier::InvalidSignature do
        QrCodeLink.from_signed(tampered)
      end
    end
  end
end
