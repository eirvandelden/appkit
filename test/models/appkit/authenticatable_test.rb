require "test_helper"

module Appkit
  class AuthenticatableTest < ActiveSupport::TestCase
    test "deactivate! destroys sessions, mangles the email, and marks the user inactive" do
      user = users(:alice)
      original_email = user.email

      user.deactivate!

      assert user.sessions.reload.empty?
      assert_not user.active?
      assert_not_equal original_email, user.reload.email
      assert_match(/-deactivated-.+@example\.com\z/, user.email)
    end

    test "a deactivated user can no longer authenticate with their old email" do
      user = users(:alice)
      original_email = user.email
      user.deactivate!

      post_result = User.authenticate_by(email: original_email, password: "password")

      assert_nil post_result
    end
  end
end
