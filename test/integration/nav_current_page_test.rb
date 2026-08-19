require "test_helper"

class NavCurrentPageTest < ActionDispatch::IntegrationTest
  test "the home link is marked as the current page when visiting home" do
    sign_in_as users(:alice)

    get root_url

    assert_select "a[href='#{root_path}'][aria-current='page']", text: I18n.t("appkit.navigation.home")
  end

  test "the home link is not marked as the current page when visiting another page" do
    users(:alice).update!(role: :administrator)
    sign_in_as users(:alice)

    get admin_url

    assert_select "a[href='#{root_path}'][aria-current]", count: 0
  end
end
