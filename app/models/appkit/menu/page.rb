module Appkit
  class Menu
    # One page of a hub and what needs attention there; count and summary are lazy and memoized.
    class Page
      attr_reader :key #: Symbol
      attr_reader :label #: String
      attr_reader :path #: String
      attr_reader :controllers #: Array[String]
      attr_reader :filter #: Hash[String, String]

      #: (
      #    key: Symbol,
      #    label: String,
      #    path: String,
      #    controllers: Array[String],
      #    ?filter: Hash[String, String],
      #    ?tile_path: String?,
      #    ?count: (^() -> Integer)?,
      #    ?summary: (^() -> String)?
      #  ) -> void
      def initialize(key:, label:, path:, controllers:, filter: {}, tile_path: nil, count: nil, summary: nil)
        @key = key
        @label = label
        @path = path
        @controllers = controllers
        @filter = filter
        @tile_path = tile_path
        @count_lambda = count
        @summary_lambda = summary
      end

      # The filtered list a tile opens; defaults to path.
      #: () -> String
      def tile_path
        @tile_path || path
      end

      # 2: a filtered page whose controller and filter both match.
      # 1: an unfiltered page whose controller matches, for any action.
      # 0: otherwise; a filtered page never matches without its filter.
      #: (String, Hash[String, untyped]) -> Integer
      def score(controller_path, params)
        return 0 unless controllers.include?(controller_path)
        return 1 if filter.empty?

        filter_matches?(params) ? 2 : 0
      end

      # Runs the count lambda at most once.
      #: () -> Integer?
      def count
        return @count if defined?(@count)

        @count = @count_lambda&.call
      end

      # Runs the summary lambda at most once; data for the host's tile, the nav does not render it.
      #: () -> String?
      def summary
        return @summary if defined?(@summary)

        @summary = @summary_lambda&.call
      end

      private
        #: (Hash[String, untyped]) -> bool
        def filter_matches?(params)
          filter.all? { |name, value| params[name].to_s == value }
        end
    end
  end
end
