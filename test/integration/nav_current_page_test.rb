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

  test "the_shell_renders_as_the_body_header" do
    get hub_url("work")

    assert_select "body > header > nav.rail"
    assert_select "body > header > nav.hub-column"
  end

  test "filtered_page_marks_its_hub_and_page" do
    get admin_url(filter: "open")

    assert_select "nav.rail a[href='#{hub_path("review")}'][aria-current='true']"
    assert_select "nav.hub-column a[href='#{admin_path(filter: "open")}'][aria-current='page']"
    assert_select "nav.hub-column a[aria-current]", count: 1
  end

  test "record_page_marks_the_unfiltered_page" do
    get admin_record_url(7, filter: "open")

    assert_select "nav.rail a[href='#{hub_path("work")}'][aria-current='true']"
    assert_select "nav.hub-column a[href='#{admin_path}'][aria-current='page']"
    assert_select "nav.hub-column a[aria-current]", count: 1
  end

  test "the overview hub has no hub column" do
    get root_url

    assert_select "nav.rail a[href='#{root_path}'][aria-current='true']"
    assert_select "nav.hub-column", count: 0
  end

  test "a page of a hub under a parent marks the parent in the rail" do
    get settings_url

    assert_select "nav.rail a[href='#{hub_path("profile")}'][aria-current='true']"
    assert_select "nav.rail a[aria-current]", count: 1
    assert_select "nav.rail a[href='#{hub_path("setup")}']", count: 0
    assert_select "nav.hub-column h2 a[href='#{hub_path("setup")}']", text: "Setup"
    assert_select "nav.hub-column a[href='#{settings_path}'][aria-current='page']", text: /Settings/
  end

  test "a landing page of a hub under a parent marks the parent in the rail" do
    get hub_url("setup")

    assert_select "nav.rail a[href='#{hub_path("profile")}'][aria-current='true']"
    assert_select "nav.rail a[href='#{hub_path("setup")}']", count: 0
    assert_select "nav.hub-column h2 a[href='#{hub_path("setup")}']", text: "Setup"
  end

  test "the rail holds no account pop-up" do
    get root_url

    assert_select "nav.rail details", count: 0
    assert_select "nav.rail", text: /#{Regexp.escape(users(:alice).email)}/, count: 0
    assert_select "nav.rail a[href='#{hub_path("profile")}']", text: /Profile/
  end
end
