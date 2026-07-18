require "test_helper"

class FirstRunTest < ActionDispatch::IntegrationTest
  setup do
    Session.delete_all
    User.delete_all
  end

  test "visiting session new redirects to first_run when no users exist" do
    get new_session_url

    assert_redirected_to first_run_url
  end

  test "first_run show renders when no users exist" do
    get first_run_url

    assert_response :success
  end

  test "first_run show redirects to root once a user exists" do
    User.create!(name: "Existing", email: "existing@example.com", password: "password")

    get first_run_url

    assert_redirected_to root_url
  end

  test "first_run create makes the first user an administrator, starts a session, and redirects to root" do
    assert_difference -> { User.count }, 1 do
      post first_run_url, params: { user: { name: "New Person", email: "new@example.com", password: "password" } }
    end

    assert_redirected_to root_url
    assert User.last.administrator?
    assert cookies[:session_token].present?
  end

  test "first_run create is not permitted once a user exists" do
    User.create!(name: "Existing", email: "existing@example.com", password: "password")

    assert_no_difference -> { User.count } do
      post first_run_url, params: { user: { name: "New Person", email: "new@example.com", password: "password" } }
    end

    assert_redirected_to root_url
  end
end
