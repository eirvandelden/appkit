require "test_helper"

class OriginFlowTest < ActionDispatch::IntegrationTest
  setup do
    users(:alice).update!(role: :administrator)
    sign_in_as users(:alice)
  end

  test "a tile on a landing page carries its hub as the origin" do
    get hub_url("work")

    assert_select "ul.tiles a[href='#{admin_path(from: "work")}']", text: "Admin"
    assert_select "nav.hub-column a[href='#{admin_path}']"
  end

  test "the origin travels from a tile to a list and on to a record" do
    get hub_url("work")
    get css_select("ul.tiles a").first["href"]

    assert_select "a.back[href='#{hub_path("work")}']", text: "‹ Work"

    get css_select("main a").first["href"]

    assert_equal admin_record_path(7, from: "work"), request.fullpath
    assert_select "a.back[href='#{admin_path(from: "work")}']", text: "‹ Admin"
  end

  test "a landing page has no back link" do
    get hub_url("work")

    assert_select "a.back", count: 0
  end
end
