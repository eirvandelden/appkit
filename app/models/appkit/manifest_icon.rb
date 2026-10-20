module Appkit
  # Infers manifest.json icon metadata from a configured icon path, e.g.
  # "/icon-mask-512.png" -> sizes "512x512", purpose "maskable".
  class ManifestIcon
    attr_reader :path #: String

    #: (String) -> void
    def initialize(path)
      @path = path
    end

    #: () -> Hash[Symbol, String]
    def to_h
      { src: path, type: content_type, sizes: sizes, purpose: purpose }.compact
    end

    private
      #: () -> String
      def content_type
        File.extname(path) == ".svg" ? "image/svg+xml" : "image/png"
      end

      #: () -> String?
      def sizes
        return nil if svg?

        dimension = path[/-(\d+)\.\w+\z/, 1]
        "#{dimension}x#{dimension}" if dimension
      end

      #: () -> bool
      def svg?
        File.extname(path) == ".svg"
      end

      #: () -> String?
      def purpose
        "maskable" if maskable?
      end

      #: () -> bool
      def maskable?
        path.include?("mask")
      end
  end
end
