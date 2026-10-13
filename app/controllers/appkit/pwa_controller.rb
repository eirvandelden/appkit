module Appkit
  class PwaController < ::ApplicationController
    allow_unauthenticated_access
    skip_forgery_protection

    def manifest
      response.headers["Cache-Control"] = "no-cache"
      render template: "appkit/pwa/manifest", formats: :json, layout: false
    end

    def service_worker
      response.headers["Cache-Control"] = "no-cache"
      render template: "appkit/pwa/service_worker", formats: :js, layout: false,
             content_type: "application/javascript"
    end
  end
end
