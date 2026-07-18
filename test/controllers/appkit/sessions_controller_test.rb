require "test_helper"

module Appkit
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "successful login starts a session and redirects to the app" do
      assert_difference -> { Session.where(user: users(:alice)).count }, 1 do
        post session_url, params: { email_address: users(:alice).email, password: "password" }
      end

      assert_redirected_to root_url
    end

    test "bad credentials render the login form with an unauthorized status" do
      post session_url, params: { email_address: users(:alice).email, password: "wrong" }

      assert_response :unauthorized
      assert_not_nil flash[:alert]
    end

    test "rate limits repeated login attempts" do
      11.times { post session_url, params: { email_address: users(:alice).email, password: "wrong" } }

      assert_response :too_many_requests
    end

    test "logout destroys the session row and clears the cookie" do
      sign_in_as users(:alice)
      session = Session.order(:created_at).last

      delete session_url

      assert_redirected_to root_url
      assert_not Session.exists?(session.id)
      assert cookies[:session_token].blank?
    end
  end
end
