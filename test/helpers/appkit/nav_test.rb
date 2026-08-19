require "test_helper"

module Appkit
  class NavTest < ActionView::TestCase
    test "renders home, then the app's own links, then preferences and logout" do
      render layout: "appkit/shared/nav", locals: { home_path: "/somewhere" } do
        "<li>App link</li>".html_safe
      end

      assert_select "nav ul" do
        assert_select "li:nth-child(1) a[href='/somewhere']", text: I18n.t("appkit.navigation.home")
        assert_select "li:nth-child(2)", text: "App link"
        assert_select "li:nth-child(3) a[href='#{edit_preferences_path}']", text: I18n.t("appkit.navigation.preferences")
        assert_select "li:nth-child(4) form[action='#{session_path}'] button", text: I18n.t("appkit.navigation.logout")
      end
    end

    test "renders just home, preferences, and logout when the app has no extra links" do
      render layout: "appkit/shared/nav", locals: { home_path: "/somewhere" } do
        "".html_safe
      end

      assert_select "nav ul li", count: 3
    end
  end
end
