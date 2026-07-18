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

    test "responds with not_found for a tampered or garbage signed id" do
      get qr_code_url("not-a-valid-signed-id")

      assert_response :not_found
    end
  end
end
