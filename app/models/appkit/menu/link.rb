module Appkit
  class Menu
    # A label and a path.
    class Link
      attr_reader :label #: String
      attr_reader :path #: String

      #: (label: String, path: String) -> void
      def initialize(label:, path:)
        @label = label
        @path = path
      end
    end
  end
end
