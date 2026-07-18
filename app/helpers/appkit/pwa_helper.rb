module Appkit
  module PwaHelper
    # iOS ignores manifest icons and doesn't support SVG touch icons, so pick
    # the configured 192px PNG (or the largest non-maskable PNG as a fallback).
    def apple_touch_icon_path
      icon_192 = png_icon_paths.find { |path| path.include?("192") }
      icon_192 || png_icon_paths.max_by { |path| path[/-(\d+)\./, 1].to_i }
    end

    private
      def png_icon_paths
        Appkit.config.icons.select { |path| File.extname(path) == ".png" && !path.include?("mask") }
      end
  end
end
