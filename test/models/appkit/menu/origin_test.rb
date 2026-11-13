require "test_helper"

module Appkit
  class Menu
    class OriginTest < ActiveSupport::TestCase
      test "parse names a hub origin" do
        origin = Origin.parse(hubs, "review")

        assert_equal :review, origin.hub.key
        assert_nil origin.page
        assert_equal "review", origin.key
      end

      test "parse names a list origin" do
        origin = Origin.parse(hubs, "review.open")

        assert_equal :open, origin.page.key
        assert_equal "review.open", origin.key
      end

      test "parse degrades an unknown page to a hub origin" do
        assert_equal "review", Origin.parse(hubs, "review.bogus").key
      end

      test "parse degrades a submit page to a hub origin" do
        assert_equal "review", Origin.parse(hubs, "review.sign_out").key
      end

      test "parse is nil for an unknown hub or no value" do
        assert_nil Origin.parse(hubs, "nowhere.open")
        assert_nil Origin.parse(hubs, nil)
      end

      test "key writes a list origin" do
        assert_equal "review.open", Origin.new(hub: hubs.first, page: hubs.first.pages.first).key
      end

      private
        def hubs
          @hubs ||= [
            Hub.new(key: :review, label: "Review", emoji: "📥", path: "/hubs/review",
              landing: { "controller" => "hubs", "id" => "review" }, pages: [ open_page, sign_out_page ])
          ]
        end

        def open_page
          Page.new(key: :open, label: "Open", path: "/records?filter=open", controllers: [ "records" ],
            filter: { "filter" => "open" })
        end

        def sign_out_page
          Page.new(key: :sign_out, label: "Sign out", path: "/session", controllers: [], verb: :delete)
        end
    end
  end
end
