module Appkit
  # Infers manifest.json icon metadata from a configured icon path, e.g.
  # "/icon-mask-512.png" -> sizes "512x512", purpose "maskable".
  class ManifestIcon
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def to_h
      { src: path, type: content_type, sizes: sizes, purpose: purpose }.compact
    end

    private
      def content_type
        File.extname(path) == ".svg" ? "image/svg+xml" : "image/png"
      end

      def sizes
        return nil if svg?

        dimension = path[/-(\d+)\.\w+\z/, 1]
        "#{dimension}x#{dimension}" if dimension
      end

      def purpose
        "maskable" if maskable?
      end

      def maskable?
        path.include?("mask")
      end

      def svg?
        File.extname(path) == ".svg"
      end
  end
end
