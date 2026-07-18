require "test_helper"

module Appkit
  module Sessions
    class TransfersControllerTest < ActionDispatch::IntegrationTest
      test "show renders an auto-submitting PUT form" do
        get session_transfer_url(users(:alice).transfer_id)

        assert_response :success
        assert_select "form[method=?]", "post" do
          assert_select "input[name=?][value=?]", "_method", "put"
        end
        assert_select "form[data-controller=?]", "auto-submit"
      end

      test "update starts a session and redirects when the transfer id is valid" do
        user = users(:alice)

        assert_difference -> { Session.where(user: user).count }, 1 do
          put session_transfer_url(user.transfer_id)
        end

        assert_redirected_to root_url
        assert cookies[:session_token].present?
      end

      test "update responds with bad_request for an expired or invalid transfer id" do
        put session_transfer_url(users(:alice).transfer_id.reverse)

        assert_response :bad_request
      end
    end
  end
end
