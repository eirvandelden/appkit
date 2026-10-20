module Appkit
  # @rbs module-self ::ActionController::Base
  module VersionHeaders
    extend ActiveSupport::Concern

    # Rails class macros run on the including class; the available RBS does not describe them.
    # steep:ignore:start
    included do
      before_action :set_version_headers
    end
    # steep:ignore:end

    private
      #: () -> void
      def set_version_headers
        # app_version is a host app config option.
        response.headers["X-Version"] = Rails.application.config.app_version # steep:ignore NoMethod
        # git_revision is a host app config option.
        response.headers["X-Rev"] = Rails.application.config.git_revision # steep:ignore NoMethod
      end
  end
end
