require "test_helper"

module Appkit
  class QrCodeControllerTest < ActionDispatch::IntegrationTest
    test "renders an SVG for a validly-signed url" do
      signed = QrCodeLink.new("https://example.com/session/transfers/abc123").signed

      get qr_code_url(signed)

      assert_response :success
      assert_equal "image/svg+xml", response.media_type
      assert_match(/<svg/, response.body)
    end
  end
end
