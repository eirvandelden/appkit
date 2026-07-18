require "test_helper"

class I18nRetrofitTest < ActionDispatch::IntegrationTest
  test "sessions new renders without missing translations" do
    get new_session_url

    assert_response :success
    assert_select "label", text: "Email address"
  end

  test "first_run show renders without missing translations" do
    Session.delete_all
    User.delete_all

    get first_run_url

    assert_response :success
    assert_select "label", text: "Name"
  end
end
