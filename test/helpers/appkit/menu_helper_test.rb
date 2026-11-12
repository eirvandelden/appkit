require "test_helper"

module Appkit
  class MenuHelperTest < ActionView::TestCase
    test "a page renders a plain link" do
      render html: menu_entry_to("/records", list_page) { "Records" }

      assert_select "a[href='/records']:not([data-turbo-method])", text: "Records"
    end

    test "a submit page renders a link with data-turbo-method" do
      render html: menu_entry_to("/session", sign_out_page) { "Sign out" }

      assert_select "a[href='/session'][data-turbo-method='delete']", text: "Sign out"
      assert_select "form", count: 0
    end

    test "html options pass through and data merges" do
      entry = menu_entry_to("/session", sign_out_page, class: "tile", "aria-current": "page",
        data: { turbo_confirm: "Sure?" }) { "Sign out" }
      render html: entry

      assert_select "a.tile[aria-current='page'][data-turbo-confirm='Sure?'][data-turbo-method='delete']"
    end

    private
      def list_page
        Menu::Page.new(key: :records, label: "Records", path: "/records", controllers: [ "records" ])
      end

      def sign_out_page
        Menu::Page.new(key: :sign_out, label: "Sign out", path: "/session", controllers: [], verb: :delete)
      end
  end
end
