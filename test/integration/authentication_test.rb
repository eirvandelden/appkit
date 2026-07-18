require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "unauthenticated visitors are redirected to the login page" do
    get root_url

    assert_redirected_to new_session_url
  end

  test "return_to_after_authenticating round-trips to the originally requested page" do
    get root_url
    assert_redirected_to new_session_url

    post session_url, params: { email_address: users(:alice).email, password: "password" }

    assert_redirected_to root_url
  end

  test "reset_authentication destroys the Session row, not just the cookie" do
    sign_in_as users(:alice)
    session = Session.order(:created_at).last

    delete session_url

    assert_not Session.exists?(session.id)
    assert cookies[:session_token].blank?
  end

  test "authenticated_as sets Current.session, not just Current.user" do
    sign_in_as users(:alice)
    session = Session.order(:created_at).last

    get root_url

    assert_match "signed in as #{users(:alice).email} via session #{session.id}", response.body
  end

  test "login sets a far-future session cookie expiry" do
    post session_url, params: { email_address: users(:alice).email, password: "password" }

    assert_session_cookie_expires_far_in_future
  end

  test "resuming a session renews the cookie expiry" do
    sign_in_as users(:bob)

    get root_url

    assert_session_cookie_expires_far_in_future
  end

  private
    def assert_session_cookie_expires_far_in_future
      set_cookie_headers = Array(response.headers["Set-Cookie"])
      set_cookie = set_cookie_headers.find { |header| header.include?("session_token") }
      assert set_cookie, "Expected a Set-Cookie header for session_token"

      expires_match = set_cookie.match(/expires=([^;]+)/i)
      assert expires_match, "Expected Set-Cookie to include expires="

      expires_at = Time.parse(expires_match[1])
      assert expires_at > 6.months.from_now,
        "Expected cookie to expire more than 6 months from now, got #{expires_at}"
    end
end
