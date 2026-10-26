module Appkit
  # Places one request in the menu map: which hub and page are current, where the origin leads.
  class Menu
    # Every hub in map order: the rail hubs and any hub kept out of the rail.
    attr_reader :hubs #: Array[Hub]
    # Account menu entries; the partial appends the logout button.
    attr_reader :account #: Array[Link]

    #: (hubs: Array[Hub], account: Array[Link], controller_path: String, params: Hash[String, untyped]) -> void
    def initialize(hubs:, account:, controller_path:, params:)
      @hubs = hubs
      @account = account
      @controller_path = controller_path
      @params = params
    end

    #: () -> Hub?
    def current_hub
      placement&.first
    end

    #: (Hub | Page) -> bool
    def current?(entry)
      entry.is_a?(Hub) ? entry.equal?(current_hub) : entry.equal?(current_page)
    end

    # Every hub and page as a label and a path, for search.
    #: () -> Array[Link]
    def links
      hubs.flat_map do |hub|
        pages = hub.pages.map { |page| Link.new(label: page.label, path: page.path) }
        [ Link.new(label: hub.label, path: hub.path), *pages ]
      end
    end

    # The hub named by params["from"], nil for an unknown key.
    #: () -> Hub?
    def origin
      hubs.find { |hub| hub.key.to_s == @params["from"].to_s }
    end

    #: () -> String?
    def origin_key
      origin&.key&.to_s
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
      return path unless key

      uri = URI.parse(path)
      query = URI.decode_www_form(uri.query.to_s).reject { |name, _| name == "from" } #: Array[[String, String]]
      query << [ "from", key ]
      uri.query = URI.encode_www_form(query)
      uri.to_s
    end

    # The title-bar back link; nil on a list without an origin.
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

      #: () -> bool
      def record?
        @params["id"].present?
      end

      #: () -> Link?
      def origin_landing_link
        hub = origin
        hub && Link.new(label: hub.label, path: hub.path)
      end

      #: () -> Link?
      def origin_page_link
        page = origin&.pages&.find { |candidate| candidate.controllers.include?(@controller_path) }
        page && Link.new(label: page.label, path: carry(page.tile_path))
      end

      #: (String?) -> Link?
      def fallback_link(fallback)
        label = current_page&.label || current_hub&.label
        label && fallback ? Link.new(label: label, path: fallback) : nil
      end
  end
end
