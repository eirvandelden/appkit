module Semver
  # Follows the fenced code blocks of a Markdown text, one line at a time. A fence opens with three
  # or more backticks or tildes. Only a fence of the same character, at least as long and with no text
  # after it, closes it: a backtick example inside a tilde block stays text. A fence is indented by at most
  # three spaces: four or more make an indented code block, which holds no fence.
  class Fence
    OPENING = /\A {0,3}(?:(`{3,})[^`]*|(~{3,}).*)\z/
    CLOSING = /\A {0,3}(`+|~+)\s*\z/

    #: () -> void
    def initialize
      @opener = nil #: String?
    end

    # True for a fence line and for a line inside a fence. Call it once for each line, in order.
    #: (String) -> bool
    def code?(line)
      text = line.chomp
      opener = @opener
      return open_with?(text) unless opener

      @opener = nil if closes?(opener, text)
      true
    end

    # True while a fence is still open, at the end of the text for a fence left unclosed.
    #: () -> bool
    def open?
      !@opener.nil?
    end

    private

    def open_with?(line)
      match = OPENING.match(line) or return false
      @opener = match[1] || match[2]
      true
    end

    def closes?(opener, line)
      marker = CLOSING.match(line)&.captures&.first or return false
      marker.start_with?(opener[0].to_s) && marker.length >= opener.length
    end
  end
end
