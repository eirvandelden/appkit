require "test_helper"

module Appkit
  class Menu
    class HubTest < ActiveSupport::TestCase
      test "owns? is true for its landing request" do
        assert build_hub.owns?("hubs", { "id" => "work" })
      end

      test "owns? is false for another hub's landing id" do
        assert_not build_hub.owns?("hubs", { "id" => "play" })
      end

      test "landing? is true only for its landing request" do
        hub = build_hub(controllers: [ "settings" ])

        assert hub.landing?("hubs", { "id" => "work" })
        assert_not hub.landing?("hubs", { "id" => "play" })
        assert_not hub.landing?("settings", {})
      end

      test "owns? is true for a page-less controller it lists" do
        hub = build_hub(controllers: [ "settings" ])

        assert hub.owns?("settings", {})
        assert_not hub.owns?("other", {})
      end

      test "two pages with one controller raise" do
        pages = [ build_page(:one), build_page(:two) ]

        assert_raises(ArgumentError) { build_hub(pages: pages) }
      end

      test "rail? is true by default" do
        assert_predicate build_hub, :rail?
      end

      test "rail? is false for a hub kept out of the rail" do
        assert_not_predicate build_hub(rail: false), :rail?
      end

      test "action is stored" do
        action = Link.new(label: "Import", path: "/imports/new")

        assert_equal action, build_hub(action: action).action
      end

      private
        def build_hub(**options)
          Hub.new(key: :work, label: "Work", emoji: "🗄️", path: "/hubs/work",
            landing: { "controller" => "hubs", "id" => "work" }, **options)
        end

        def build_page(key)
          Page.new(key: key, label: key.to_s, path: "/#{key}", controllers: [ "records" ])
        end
    end
  end
end
