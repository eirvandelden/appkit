require "test_helper"

module Appkit
  class NavTest < ActionView::TestCase
    test "nav marks the current hub and page" do
      render_nav(controller_path: "records", params: { "filter" => "open" })

      assert_select "nav.rail a[aria-current='true']", text: /Review/
      assert_select "nav.rail a[aria-current]", count: 1
      assert_select "nav.hub-column h2 a[href='/hubs/review']", text: "Review"
      assert_select "nav.hub-column a[aria-current='page']", text: /Open records/
      assert_select "nav.hub-column a[aria-current]", count: 1
    end

    test "nav_shows_a_badge_above_zero_and_none_at_zero" do
      render_nav(controller_path: "records", params: { "filter" => "open" })

      assert_select "nav.hub-column a[href='/records?filter=open'] data[value='3']", text: "3"
      assert_select "nav.hub-column a[href='/closed'] data", count: 0
      assert_select "nav.hub-column a[href='/unknown'] data", count: 0
    end

    test "nav leaves out the hub column for a hub without pages" do
      render_nav(controller_path: "dashboard", params: {})

      assert_select "nav.rail a[aria-current='true']", text: /Overview/
      assert_select "nav.hub-column", count: 0
    end

    test "nav leaves out the hub column when no hub is current" do
      render_nav(controller_path: "nowhere", params: {})

      assert_select "nav.rail a[aria-current]", count: 0
      assert_select "nav.hub-column", count: 0
    end

    test "nav yields the top of the rail" do
      render_nav(controller_path: "dashboard", params: {})

      assert_select "nav.rail > button.search:first-child", text: "Search"
    end

    test "nav hides the hub emoji from assistive tech" do
      render_nav(controller_path: "dashboard", params: {})

      link = css_select("nav.rail a[href='/hubs/review']").first
      named = link.children.reject { |node| node.element? && node["aria-hidden"] == "true" }

      assert_equal "📥", link.at_css("span[aria-hidden='true']").text
      assert_equal "Review", named.map(&:text).join.strip
    end

    test "nav keeps a hub under a parent out of the rail" do
      render_nav(controller_path: "dashboard", params: {})

      assert_select "nav.rail a[href='/hubs/setup']", count: 0
    end

    test "nav marks the parent of a hub under it" do
      render_nav(controller_path: "categories", params: {})

      assert_select "nav.rail a[aria-current='true']", text: /Profile/
      assert_select "nav.rail a[aria-current]", count: 1
      assert_select "nav.hub-column h2 a[href='/hubs/setup']", text: "Setup"
      assert_select "nav.hub-column a[href='/categories'][aria-current='page']", text: /Categories/
    end

    test "nav labels both landmarks" do
      render_nav(controller_path: "records", params: { "filter" => "open" })

      assert_select "nav.rail[aria-label='#{I18n.t("appkit.navigation.rail")}']"
      assert_select "nav.hub-column[aria-label='#{I18n.t("appkit.navigation.hub_column")}']"
    end

test "nav renders no account pop-up" do
  render_nav(controller_path: "dashboard", params: {})

  assert_select "details", count: 0
  assert_select "nav.rail li:last-child a[href='/hubs/profile']", text: /Profile/
end

test "nav renders a submit page as a link without a badge" do
  render_nav(controller_path: "hubs", params: { "id" => "profile" })

  assert_select "nav.hub-column li:last-child > a[href='/session'][data-turbo-method='delete']",
    text: "Sign out"
  assert_select "nav.hub-column li:last-child data", count: 0
  assert_select "nav.hub-column form", count: 0
end

private
      def render_nav(controller_path:, params:)
        render layout: "appkit/shared/nav", locals: { menu: build_menu(controller_path, params) } do
          "<button class='search'>Search</button>".html_safe
        end
      end

      def build_menu(controller_path, params)
        Menu.new(hubs: hubs, controller_path: controller_path, params: params)
      end

      def hubs
        [
          Menu::Hub.new(key: :overview, label: "Overview", emoji: "🏠", path: "/",
            landing: { "controller" => "dashboard" }),
          Menu::Hub.new(key: :review, label: "Review", emoji: "📥", path: "/hubs/review",
            landing: { "controller" => "hubs", "id" => "review" }, pages: review_pages),
          Menu::Hub.new(key: :profile, label: "Profile", emoji: "👤", path: "/hubs/profile",
            landing: { "controller" => "hubs", "id" => "profile" }, pages: profile_pages),
          Menu::Hub.new(key: :setup, label: "Setup", emoji: "⚙️", path: "/hubs/setup",
            landing: { "controller" => "hubs", "id" => "setup" }, parent: :profile,
            pages: [ page(:categories, "Categories", "/categories") ])
        ]
      end

      def review_pages
        [
          page(:open, "Open records", "/records?filter=open", count: -> { 3 }, filter: { "filter" => "open" }),
          page(:closed, "Closed records", "/closed", count: -> { 0 }),
          page(:unknown, "Unknown records", "/unknown")
        ]
      end

      def page(key, label, path, count: nil, filter: {})
        Menu::Page.new(key: key, label: label, path: path, controllers: [ key == :open ? "records" : key.to_s ],
          filter: filter, count: count)
      end

      def profile_pages
        [
          page(:preferences, "Preferences", "/preferences/edit"),
          Menu::Page.new(key: :sign_out, label: "Sign out", path: "/session", controllers: [], verb: :delete)
        ]
      end
  end
end
