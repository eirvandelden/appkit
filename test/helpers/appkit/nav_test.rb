require "test_helper"

module Appkit
  class NavTest < ActionView::TestCase
    test "renders a home link, a preferences link, and a logout button" do
      render partial: "appkit/shared/nav", locals: { home_path: "/somewhere" }

      assert_select "nav ul" do
        assert_select "li:nth-child(1) a[href='/somewhere']", text: I18n.t("navigation.home")
        assert_select "li:nth-child(2) a[href='#{edit_preferences_path}']", text: I18n.t("navigation.preferences")
        assert_select "li:nth-child(3) form[action='#{session_path}'] button", text: I18n.t("common.logout")
      end
    end
  end
end
