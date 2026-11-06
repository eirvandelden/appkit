module Appkit
  class Menu
    # A hub: its landing page, its pages and the controllers it owns without a page.
    class Hub
      attr_reader :key #: Symbol
      attr_reader :label #: String
      attr_reader :emoji #: String
      attr_reader :path #: String
      attr_reader :pages #: Array[Page]
      # A title-bar action for the host's landing page; the nav does not render it.
      attr_reader :action #: Link?

      # landing: the request that is this hub's landing page, as a controller path plus params,
      # for example {"controller" => "hubs", "id" => "processing"}.
      # rail: false keeps the hub out of the rail, for a hub the host links from its account menu.
      # Raises ArgumentError when two pages share a controller, so a hub key always restores one list.
      #: (
      #    key: Symbol,
      #    label: String,
      #    emoji: String,
      #    path: String,
      #    landing: Hash[String, String],
      #    ?pages: Array[Page],
      #    ?controllers: Array[String],
      #    ?action: Link?,
      #    ?rail: bool
      #  ) -> void
      def initialize(key:, label:, emoji:, path:, landing:, pages: [], controllers: [], action: nil, rail: true)
        @key = key
        @label = label
        @emoji = emoji
        @path = path
        @landing = landing
        @pages = pages
        @controllers = controllers
        @action = action
        @rail = rail
        ensure_one_page_per_controller
      end

      # True for its landing request or a page-less controller it owns.
      #: (String, Hash[String, untyped]) -> bool
      def owns?(controller_path, params)
        @controllers.include?(controller_path) || landing?(controller_path, params)
      end

      # True for the request that is this hub's landing page.
      #: (String, Hash[String, untyped]) -> bool
      def landing?(controller_path, params)
        @landing.all? do |name, value|
          name == "controller" ? controller_path == value : params[name].to_s == value
        end
      end

      # Its page that owns the controller; a hub holds at most one.
      #: (String) -> Page?
      def page_for(controller_path)
        pages.find { |page| page.controllers.include?(controller_path) }
      end

      # True when the rail lists this hub.
      #: () -> bool
      def rail?
        @rail
      end

      private
        #: () -> void
        def ensure_one_page_per_controller
          controllers = pages.flat_map(&:controllers)
          raise ArgumentError, "hub #{key} has two pages for one controller" if controllers.uniq.size < controllers.size
        end
    end
  end
end
