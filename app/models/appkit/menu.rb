module Appkit
  # Places one request in the menu map: which hub and page are current, where the origin leads.
  class Menu
    # Every hub in map order: the rail hubs and the hubs under a parent hub.
    attr_reader :hubs #: Array[Hub]

    # Raises ArgumentError when a hub's parent names no hub in the map, or names a hub that has a parent itself.
    #: (hubs: Array[Hub], controller_path: String, params: Hash[String, untyped]) -> void
    def initialize(hubs:, controller_path:, params:)
      @hubs = hubs
      @controller_path = controller_path
      @params = params
      ensure_parents_are_rail_hubs
    end

    #: () -> Hub?
    def current_hub
      placement&.first
    end

    # A page: true for the current page. A hub: true for the current hub, or for the current hub's parent hub.
    #: (Hub | Page) -> bool
    def current?(entry)
      return entry.equal?(current_page) if entry.is_a?(Page)

      hub = current_hub
      !hub.nil? && (entry.equal?(hub) || entry.key == hub.parent)
    end

    # Every hub and every page that is not a submit page, as a label and a path, each path once, for search.
    #: () -> Array[Link]
    def links
      links = hubs.flat_map do |hub|
        pages = hub.pages.reject(&:submit?).map { |page| Link.new(label: page.label, path: page.path) }
        [ Link.new(label: hub.label, path: hub.path), *pages ]
      end
      links.uniq(&:path)
    end

    # The hub named by the hub part of params["from"], nil for an unknown key.
    # A list origin is "<hub>.<page>"; the hub key is the part before the first dot.
    #: () -> Hub?
    def origin
      origin_parts&.first
    end

    # "<hub>", or "<hub>.<page>" when the page part names a GET page of that hub; nil without an origin.
    # An unknown page or a submit page in the page part degrades to "<hub>".
    #: () -> String?
    def origin_key
      hub, page = origin_parts
      return unless hub

      page ? list_key(hub, page) : hub.key.to_s
    end

    #: () -> Hash[Symbol, String]
    def origin_params
      key = origin_key
      key ? { from: key } : {}
    end

    # The path with from=<origin key> merged into its query, unchanged without an origin.
    #: (String) -> String
    def carry(path)
      key = origin_key
      key ? with_from(path, key) : path
    end

    # Links a list to its records: from=<current hub>.<current page>, so a record returns to the list it was opened
    # from, also when the list was opened without an origin. Without a current page, the same as carry.
    #: (String) -> String
    def carry_list(path)
      hub, page = placement
      return carry(path) unless hub && page

      with_from(path, list_key(hub, page))
    end

    # A tile's href: on a landing page the page's tile path with from=<that hub's key>, elsewhere the plain tile path.
    # A submit page's tile sends its request to its own path, with no origin.
    #: (Page) -> String
    def tile_path(page)
      return page.tile_path if page.submit?

      hub = landing_hub
      hub ? with_from(page.tile_path, hub.key.to_s) : page.tile_path
    end

    # The title-bar back link; nil on a list without an origin. On a record: the list origin's page when the
    # origin names one, else the origin hub's page for the controller, else the fallback.
    #: (?String?) -> Link?
    def back(fallback = nil)
      return origin_landing_link unless record?

      origin_page_link || fallback_link(fallback)
    end

    # Where a delete lands: the origin landing page, else the fallback.
    #: (String) -> String
    def exit_path(fallback)
      origin&.path || fallback
    end

    private
      #: () -> void
      def ensure_parents_are_rail_hubs
        hubs.each do |hub|
          next if hub.rail?

          parent = hubs.find { |candidate| candidate.key == hub.parent }
          next if parent&.rail?

          raise ArgumentError, "hub #{hub.key} names parent #{hub.parent}, not a rail hub in the map"
        end
      end

      # The highest-scoring page and its hub, ties to map order; else a hub that owns the controller.
      #: () -> [Hub, Page?]?
      def placement
        return @placement if defined?(@placement)

        @placement = best_page_placement || owner_placement
      end

      #: () -> [Hub, Page]?
      def best_page_placement
        best = nil #: [Hub, Page]?
        best_score = 0
        each_page do |hub, page|
          score = page.score(@controller_path, @params)
          best, best_score = [ hub, page ], score if score > best_score
        end
        best
      end

      #: () { (Hub, Page) -> void } -> void
      def each_page(&block)
        hubs.each { |hub| hub.pages.each { |page| block.call(hub, page) } }
      end

      #: () -> [Hub, nil]?
      def owner_placement
        hub = hubs.find { |candidate| candidate.owns?(@controller_path, @params) }
        hub && [ hub, nil ]
      end

      #: () -> Page?
      def current_page
        placement&.last
      end

      # The origin hub and, for a list origin, its GET page; parsed once.
      #: () -> [Hub, Page?]?
      def origin_parts
        return @origin_parts if defined?(@origin_parts)

        @origin_parts = parse_origin
      end

      #: () -> [Hub, Page?]?
      def parse_origin
        hub_key, page_key = @params["from"].to_s.split(".", 2)
        hub = hubs.find { |candidate| candidate.key.to_s == hub_key }
        hub && [ hub, list_page(hub, page_key) ]
      end

      #: (Hub, String?) -> Page?
      def list_page(hub, page_key)
        page = page_key && hub.page(page_key)
        page unless page.nil? || page.submit?
      end

      #: (Hub, Page) -> String
      def list_key(hub, page)
        "#{hub.key}.#{page.key}"
      end

      # The path with from=<key> merged into its query: keeps the query and a fragment, replaces an existing from.
      #: (String, String) -> String
      def with_from(path, key)
        uri = URI.parse(path)
        query = URI.decode_www_form(uri.query.to_s).reject { |name, _| name == "from" } #: Array[[String, String]]
        query << [ "from", key ]
        uri.query = URI.encode_www_form(query)
        uri.to_s
      end

      # The hub whose landing page is this request.
      #: () -> Hub?
      def landing_hub
        hubs.find { |hub| hub.landing?(@controller_path, @params) }
      end

      # A request with an id, except a landing page; new and create have no id, so they count as lists.
      #: () -> bool
      def record?
        @params["id"].present? && landing_hub.nil?
      end

      #: () -> Link?
      def origin_landing_link
        hub = origin
        hub && Link.new(label: hub.label, path: hub.path)
      end

      #: () -> Link?
      def origin_page_link
        page = origin_parts&.last || origin&.page_for(@controller_path)
        page && Link.new(label: page.label, path: carry(page.tile_path))
      end

      #: (String?) -> Link?
      def fallback_link(fallback)
        label = current_page&.label || current_hub&.label
        label && fallback ? Link.new(label: label, path: fallback) : nil
      end
  end
end
