module Appkit
  # @rbs module-self ::ActionView::Base
  module MenuHelper
    # A tile or hub-column entry for a page, always a link so it keeps the li > a markup mvpa.css styles.
    # A submit page's link also carries data-turbo-method with its verb, so Turbo sends that request.
    # Raises ArgumentError without a block: the block renders the entry's content.
    #: (String, Menu::Page, **untyped) { () -> untyped } -> ActiveSupport::SafeBuffer
    def menu_entry_to(path, page, **html_options, &block)
      raise ArgumentError, "menu_entry_to needs a block for the entry's content" unless block

      options = page.submit? ? html_options.deep_merge(data: { turbo_method: page.verb }) : html_options

      link_to(path, options, &block)
    end
  end
end
