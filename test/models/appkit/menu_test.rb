require "test_helper"

module Appkit
  class MenuTest < ActiveSupport::TestCase
    test "current_hub picks the highest-scoring page" do
      menu = build_menu("records", { "filter" => "open" })

      assert_equal :review, menu.current_hub.key
    end

    test "filter_match_beats_controller_match" do
      menu = build_menu("records", { "filter" => "open" })
      review_page = menu.hubs.last.pages.first
      work_page = menu.hubs.first.pages.first

      assert menu.current?(review_page)
      assert_not menu.current?(work_page)
    end

    test "current_hub on a record edit is the unfiltered page's hub, not the filtered page's hub" do
      menu = build_menu("records", { "id" => "7", "filter" => "open" })

      assert_equal :work, menu.current_hub.key
    end

    test "ties go to map order" do
      first = hub(:first, pages: [ page(:a, "records") ])
      second = hub(:second, pages: [ page(:b, "records") ])
      menu = Menu.new(hubs: [ first, second ], controller_path: "records", params: {})

      assert_equal :first, menu.current_hub.key
    end

    test "current_hub on a landing request is the hub whose landing matches" do
      menu = build_menu("hubs", { "id" => "review" })

      assert_equal :review, menu.current_hub.key
      assert_not menu.current?(menu.hubs.first)
    end

    test "current_hub falls back to a hub that owns the controller" do
      menu = build_menu("settings", {})

      assert_equal :work, menu.current_hub.key
    end

    test "current_hub can be a hub under a parent" do
      menu = build_menu("categories", { "id" => "3" }, hubs: profile_hubs)

      assert_equal :setup, menu.current_hub.key
      assert menu.current?(menu.current_hub)
    end

    test "current_hub is nil for a request no hub owns" do
      menu = build_menu("unknown", {})

      assert_nil menu.current_hub
      assert_not menu.current?(menu.hubs.first)
    end

    test "links lists every hub and page" do
      labels = build_menu("records", {}).links.map(&:label)

      assert_equal [ "Work", "Records", "Review", "Open records" ], labels
      assert_equal [ "/hubs/work", "/records", "/hubs/review", "/records?filter=open" ],
        build_menu("records", {}).links.map(&:path)
    end

    test "origin_key and origin_params are empty without an origin" do
      menu = build_menu("records", {})

      assert_nil menu.origin
      assert_nil menu.origin_key
      assert_equal({}, menu.origin_params)
    end

    test "origin returns the hub named by from" do
      menu = build_menu("records", { "from" => "review" })

      assert_equal :review, menu.origin.key
      assert_equal "review", menu.origin_key
      assert_equal({ from: "review" }, menu.origin_params)
    end

    test "unknown_origin_is_ignored" do
      menu = build_menu("records", { "from" => "nowhere" })

      assert_nil menu.origin
      assert_nil menu.origin_key
      assert_equal "/records", menu.carry("/records")
      assert_equal "/fallback", menu.exit_path("/fallback")
    end

    test "carry adds from only with an origin" do
      assert_equal "/records", build_menu("records", {}).carry("/records")
      assert_equal "/records?from=work", build_menu("records", { "from" => "work" }).carry("/records")
    end

    test "carry merges into an existing query" do
      menu = build_menu("records", { "from" => "work" })

      assert_equal "/records?filter=open&from=work", menu.carry("/records?filter=open")
    end

    test "carry replaces an existing from" do
      menu = build_menu("records", { "from" => "work" })

      assert_equal "/records?from=work", menu.carry("/records?from=review")
    end

    test "carry keeps a fragment" do
      menu = build_menu("records", { "from" => "work" })

      assert_equal "/records?from=work#top", menu.carry("/records#top")
    end

    test "tile_path on a landing page carries that hub as the origin" do
      work = build_menu("hubs", { "id" => "work" })
      review = build_menu("hubs", { "id" => "review" })

      assert_equal "/records?from=work", work.tile_path(work.hubs.first.pages.first)
      assert_equal "/records?filter=open&from=review", review.tile_path(review.hubs.last.pages.first)
    end

    test "tile_path off a landing page is the plain tile path" do
      menu = build_menu("records", { "from" => "work" })

      assert_equal "/records", menu.tile_path(menu.hubs.first.pages.first)
    end

    test "carry on a landing page without from leaves the path unchanged" do
      assert_equal "/records", build_menu("hubs", { "id" => "work" }).carry("/records")
    end

    test "back on a list with an origin leads to the landing page" do
      back = build_menu("records", { "from" => "work" }).back

      assert_equal "Work", back.label
      assert_equal "/hubs/work", back.path
    end

    test "back on a record with an origin leads to the origin hub's page for that controller" do
      back = build_menu("records", { "id" => "7", "from" => "review" }).back

      assert_equal "Open records", back.label
      assert_equal "/records?filter=open&from=review", back.path
    end

    test "back on a record whose controller has no page in the origin hub uses the fallback" do
      hubs = [ hub(:work, pages: [ page(:records, "records") ]), hub(:review, pages: [ page(:other, "other") ]) ]
      back = build_menu("records", { "id" => "7", "from" => "review" }, hubs: hubs).back("/fallback")

      assert_equal "Records", back.label
      assert_equal "/fallback", back.path
    end

    test "back without an origin uses the fallback and the owning page label" do
      back = build_menu("records", { "id" => "7" }).back("/records")

      assert_equal "Records", back.label
      assert_equal "/records", back.path
    end

    test "back on a record without an origin or fallback is nil" do
      assert_nil build_menu("records", { "id" => "7" }).back
    end

    test "back on a list without an origin is nil" do
      assert_nil build_menu("records", {}).back("/records")
    end

    test "back on a landing page is nil, although its id is present" do
      assert_nil build_menu("hubs", { "id" => "work" }).back("/fallback")
    end

    test "back on a new page counts as a list" do
      menu = build_menu("records", { "action" => "new", "from" => "work" })

      assert_equal [ "Work", "/hubs/work" ], [ menu.back("/records").label, menu.back("/records").path ]
      assert_nil build_menu("records", { "action" => "new" }).back("/records")
    end

    test "exit_path prefers the origin landing page" do
      assert_equal "/hubs/work", build_menu("records", { "from" => "work" }).exit_path("/fallback")
    end

    test "exit_path without an origin is the fallback" do
      assert_equal "/fallback", build_menu("records", {}).exit_path("/fallback")
    end

    test "a parent that names no hub raises" do
      orphan = hub(:setup, parent: :nowhere)

      assert_raises(ArgumentError) { build_menu("records", {}, hubs: [ *default_hubs, orphan ]) }
    end

    test "a parent that has a parent raises" do
      nested = hub(:deep, parent: :setup)

      assert_raises(ArgumentError) { build_menu("records", {}, hubs: [ *profile_hubs, nested ]) }
    end

    test "current? marks the parent hub of the current hub" do
      menu = build_menu("categories", {}, hubs: profile_hubs)
      profile = menu.hubs.find { |candidate| candidate.key == :profile }

      assert menu.current?(profile)
    end

    test "current? does not mark an unrelated hub" do
      menu = build_menu("categories", {}, hubs: profile_hubs)

      assert_not menu.current?(menu.hubs.first)
    end

    test "links skips submit pages and lists each path once" do
      twin = hub(:twin, pages: [ page(:records, "records") ])
      links = build_menu("records", {}, hubs: [ *profile_hubs, twin ]).links

      assert_not_includes links.map(&:path), "/session"
      assert_equal 1, links.count { |link| link.path == "/records" }
      assert_includes links.map(&:label), "Preferences"
    end

    test "tile_path of a submit page is its own path, also on a landing page" do
      menu = build_menu("hubs", { "id" => "profile" }, hubs: profile_hubs)

      assert_equal "/session", menu.tile_path(sign_out_page)
    end

    test "origin reads the hub part of a list origin" do
      assert_equal :review, build_menu("records", { "from" => "review.open" }).origin.key
    end

    test "origin_key keeps a list origin" do
      menu = build_menu("records", { "from" => "review.open" })

      assert_equal "review.open", menu.origin_key
      assert_equal({ from: "review.open" }, menu.origin_params)
    end

    test "an unknown page in a list origin degrades to the hub origin" do
      assert_equal "review", build_menu("records", { "from" => "review.bogus" }).origin_key
    end

    test "a submit page in a list origin degrades to the hub origin" do
      menu = build_menu("records", { "id" => "7", "from" => "profile.sign_out" }, hubs: profile_hubs)

      assert_equal "profile", menu.origin_key
      assert_nil menu.back
    end

    test "carry carries a list origin" do
      assert_equal "/records/7?from=review.open", build_menu("records", { "from" => "review.open" }).carry("/records/7")
    end

    test "carry_list names the current page in the origin hub" do
      menu = build_menu("records", { "filter" => "open", "from" => "review" })

      assert_equal "/records/7?from=review.open", menu.carry_list("/records/7")
    end

    test "carry_list without an origin names the current hub and page" do
      assert_equal "/records/7?from=work.records", build_menu("records", {}).carry_list("/records/7")
    end

    test "carry_list when the current page is not in the origin hub names the current hub" do
      menu = build_menu("records", { "from" => "review" })

      assert_equal "/records/7?from=work.records", menu.carry_list("/records/7")
    end

    test "carry_list without a current page is carry" do
      assert_equal "/records/7?from=work", build_menu("settings", { "from" => "work" }).carry_list("/records/7")
      assert_equal "/records/7", build_menu("unknown", {}).carry_list("/records/7")
    end

    test "back on a record with a list origin leads to that list" do
      back = build_menu("records", { "id" => "7", "from" => "review.open" }).back("/fallback")

      assert_equal "Open records", back.label
      assert_equal "/records?filter=open&from=review.open", back.path
    end

    test "back on a list with a list origin leads to the landing page" do
      back = build_menu("records", { "filter" => "open", "from" => "review.open" }).back

      assert_equal [ "Review", "/hubs/review" ], [ back.label, back.path ]
    end

    test "exit_path with a list origin is the hub landing page" do
      assert_equal "/hubs/review", build_menu("records", { "from" => "review.open" }).exit_path("/fallback")
    end

    private
      def build_menu(controller_path, params, hubs: default_hubs)
        Menu.new(hubs: hubs, controller_path: controller_path, params: params)
      end

      def default_hubs
        [
          hub(:work, pages: [ page(:records, "records") ], controllers: [ "settings" ]),
          hub(:review, pages: [ page(:open, "records", label: "Open records", filter: { "filter" => "open" }) ])
        ]
      end

      def hub(key, pages: [], controllers: [], parent: nil)
        Menu::Hub.new(key: key, label: key.to_s.capitalize, emoji: "📥", path: "/hubs/#{key}",
          landing: { "controller" => "hubs", "id" => key.to_s }, pages: pages, controllers: controllers, parent: parent)
      end
      def page(key, controller, label: key.to_s.capitalize, filter: {})
        path = filter.empty? ? "/#{controller}" : "/#{controller}?#{filter.to_query}"
        Menu::Page.new(key: key, label: label, path: path, controllers: [ controller ], filter: filter)
      end

      def profile_hubs
        [
          *default_hubs,
          hub(:profile, pages: [ page(:preferences, "preferences"), sign_out_page ]),
          hub(:setup, pages: [ page(:categories, "categories") ], parent: :profile)
        ]
      end

      def sign_out_page
        @sign_out_page ||= Menu::Page.new(key: :sign_out, label: "Sign out", path: "/session", controllers: [],
          verb: :delete)
      end
  end
end
