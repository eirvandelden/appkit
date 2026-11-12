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
      # The key of the rail hub this hub sits under, nil for a rail hub.
      attr_reader :parent #: Symbol?

      # landing: the request that is this hub's landing page, as a controller path plus params,
      # for example {"controller" => "hubs", "id" => "processing"}.
      # parent: the key of the rail hub this hub sits under; the hub then has no rail item, and the rail marks
      # the parent while it is current. Menu checks that the parent exists and is a rail hub.
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
      #    ?parent: Symbol?
      #  ) -> void
      def initialize(key:, label:, emoji:, path:, landing:, pages: [], controllers: [], action: nil, parent: nil)
        @key = key
        @label = label
        @emoji = emoji
        @path = path
        @landing = landing
        @pages = pages
        @controllers = controllers
        @action = action
        @parent = parent
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

      # Its page with this key, nil otherwise; a String key compares by name, as from a query parameter.
      #: (Symbol | String) -> Page?
      def page(key)
        pages.find { |page| page.key.to_s == key.to_s }
      end

      # True when the hub has no parent hub, so the rail lists it.
      #: () -> bool
      def rail?
        parent.nil?
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
