module Appkit
  # The host's ApplicationController, which includes Appkit::Authentication, is the real superclass.
  # @rbs inherits ::ActionController::Base
  class PwaController < ::ApplicationController # steep:ignore UnknownConstant
    # @rbs!
    #   include ::Appkit::Authentication
    #   extend ::Appkit::Authentication::ClassMethods

    allow_unauthenticated_access
    skip_forgery_protection

    #: () -> void
    def manifest
      expires_in 0, must_revalidate: true
      render template: "appkit/pwa/manifest", formats: :json, layout: false
    end

    #: () -> void
    def service_worker
      expires_in 0, must_revalidate: true
      render template: "appkit/pwa/service_worker", formats: :js, layout: false,
             content_type: "application/javascript"
    end
  end
end
