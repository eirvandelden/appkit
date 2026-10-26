require "test_helper"

module Appkit
  class Menu
    class PageTest < ActiveSupport::TestCase
      test "score is 2 for controller and filter" do
        assert_equal 2, filtered_page.score("records", { "filter" => "open" })
      end

      test "score is 1 for an unfiltered page's controller" do
        assert_equal 1, plain_page.score("records", { "filter" => "open", "id" => "7" })
      end

      test "score is 0 for a filtered page without its filter" do
        assert_equal 0, filtered_page.score("records", {})
        assert_equal 0, filtered_page.score("records", { "filter" => "closed" })
      end

      test "score is 0 for a filtered page on a record" do
        assert_equal 0, filtered_page.score("records", { "filter" => "open", "id" => "7" })
      end

      test "score is 0 otherwise" do
        assert_equal 0, plain_page.score("other", {})
      end

      test "count evaluates its lambda once" do
        calls = 0
        page = build_page(count: -> { calls += 1 })

        assert_equal 1, page.count
        assert_equal 1, page.count
        assert_equal 1, calls
      end

      test "count is nil without a lambda" do
        assert_nil plain_page.count
      end

      test "summary evaluates its lambda once" do
        calls = 0
        page = build_page(summary: -> { "run #{calls += 1}" })

        assert_equal "run 1", page.summary
        assert_equal "run 1", page.summary
        assert_equal 1, calls
      end

      test "controllers are public and filter is not" do
        assert_equal [ "records" ], filtered_page.controllers
        assert_not_respond_to filtered_page, :filter
      end

      test "tile_path defaults to path" do
        assert_equal "/records", plain_page.tile_path
        assert_equal "/records?filter=open", filtered_page.tile_path
      end

      private
        def plain_page
          build_page
        end

        def filtered_page
          build_page(filter: { "filter" => "open" }, tile_path: "/records?filter=open")
        end

        def build_page(**options)
          Page.new(key: :records, label: "Records", path: "/records", controllers: [ "records" ], **options)
        end
    end
  end
end
