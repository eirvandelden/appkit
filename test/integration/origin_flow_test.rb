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

    assert_select "main > header nav a.back[href='#{hub_path("work")}']", text: "‹ Work"

    get css_select("main a:not(.back)").first["href"]

    assert_equal admin_record_path(7, from: "work.admin"), request.fullpath
    assert_select "a.back[href='#{admin_path(from: "work.admin")}']", text: "‹ Admin"
  end

  test "a record opened from a combined list returns to it after edit and save" do
    open_record_from_tile("All")

    assert_returns_after_save("All", inbox_path(from: "review.all"))
  end

  test "a record opened from a combined list in the hub column returns to it" do
    get inbox_url
    get css_select("main a:not(.back)").first["href"]

    assert_equal admin_record_path(7, from: "review.all"), request.fullpath
    assert_select "a.back[href='#{inbox_path(from: "review.all")}']", text: "‹ All"
  end

  test "a record opened from its own page returns to that page after edit and save" do
    open_record_from_tile("Open admin")

    assert_returns_after_save("Open admin", admin_path(filter: "open", from: "review.open_admin"))
  end

  test "cancel on the edit form keeps the list origin" do
    open_record_from_tile("All")
    get css_select("main a.edit").first["href"]
    get css_select("main a.cancel").first["href"]

    assert_equal admin_record_path(7, from: "review.all"), request.fullpath
    assert_select "a.back[href='#{inbox_path(from: "review.all")}']", text: "‹ All"
  end

  test "a landing page has no back link" do
    get hub_url("work")

    assert_select "a.back", count: 0
  end

  private
    def open_record_from_tile(label)
      get hub_url("review")
      get css_select("ul.tiles a").find { |link| link.text.strip == label }["href"]
      get css_select("main a:not(.back)").first["href"]
    end

    def assert_returns_after_save(label, list_path)
      get css_select("main a.edit").first["href"]
      form = css_select("main form").first
      from = form.at_css("input[name='from']")["value"]
      patch form["action"], params: { from: from }
      follow_redirect!

      assert_select "a.back[href='#{list_path}']", text: "‹ #{label}"
    end
end
