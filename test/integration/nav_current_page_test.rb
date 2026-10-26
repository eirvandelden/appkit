require "test_helper"

class NavCurrentPageTest < ActionDispatch::IntegrationTest
  setup do
    users(:alice).update!(role: :administrator)
    sign_in_as users(:alice)
  end

  test "landing_page_marks_its_hub" do
    get hub_url("work")

    assert_select "nav.rail a[href='#{hub_path("work")}'][aria-current='true']"
    assert_select "nav.rail a[aria-current]", count: 1
    assert_select "nav.hub-column a[aria-current]", count: 0
  end

  test "filtered_page_marks_its_hub_and_page" do
    get admin_url(filter: "open")

    assert_select "nav.rail a[href='#{hub_path("review")}'][aria-current='true']"
    assert_select "nav.hub-column a[href='#{admin_path(filter: "open")}'][aria-current='page']"
    assert_select "nav.hub-column a[aria-current]", count: 1
  end

  test "record_page_marks_the_unfiltered_page" do
    get admin_url

    assert_select "nav.rail a[href='#{hub_path("work")}'][aria-current='true']"
    assert_select "nav.hub-column a[href='#{admin_path}'][aria-current='page']"
    assert_select "nav.hub-column a[aria-current]", count: 1
  end

  test "the overview hub has no hub column" do
    get root_url

    assert_select "nav.rail a[href='#{root_path}'][aria-current='true']"
    assert_select "nav.hub-column", count: 0
  end

  test "a hub kept out of the rail still gets its hub column" do
    get edit_preferences_url

    assert_select "nav.rail a[href='#{hub_path("setup")}']", count: 0
    assert_select "nav.rail a[aria-current]", count: 0
    assert_select "nav.hub-column h2 a[href='#{hub_path("setup")}']", text: "Setup"
    assert_select "nav.hub-column a[href='#{edit_preferences_path}'][aria-current='page']"
  end

  test "the rail ends with the account menu holding preferences and logout" do
    get root_url

    assert_select "nav.rail details a[href='#{edit_preferences_path}']"
    assert_select "nav.rail details form[action='#{session_path}']"
  end
end
