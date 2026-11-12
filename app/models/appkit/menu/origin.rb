module Appkit
  class Menu
    # Where a flow started: a hub, and for a list origin one GET page of that hub. Written "<hub>" or "<hub>.<page>".
    class Origin
      attr_reader :hub #: Hub
      # The list the flow started from; nil for a hub origin.
      attr_reader :page #: Page?

      # The origin a from value names, nil when it names no hub in the map. The hub key is the part before the
      # first dot. An unknown page or a submit page in the page part degrades to a hub origin.
      #: (Array[Hub], String?) -> Origin?
      def self.parse(hubs, value)
        hub_key, page_key = value.to_s.split(".", 2)
        hub = hubs.find { |candidate| candidate.key.to_s == hub_key }
        return unless hub

        page = page_key && hub.page(page_key)
        new(hub: hub, page: page&.submit? ? nil : page)
      end

      #: (hub: Hub, ?page: Page?) -> void
      def initialize(hub:, page: nil)
        @hub = hub
        @page = page
      end

      # The from value: "<hub>", or "<hub>.<page>" for a list origin.
      #: () -> String
      def key
        page_key = page&.key
        page_key ? "#{hub.key}.#{page_key}" : hub.key.to_s
      end
    end
  end
end
