require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  test "ensure_can_administer renders forbidden when the user cannot administer" do
    sign_in_as users(:alice)

    get admin_url

    assert_response :forbidden
  end

  test "ensure_can_administer passes through when the user can administer" do
    users(:alice).update!(role: :administrator)
    sign_in_as users(:alice)

    get admin_url

    assert_response :ok
  end
end
