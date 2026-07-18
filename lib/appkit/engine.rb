module Appkit
  class Engine < ::Rails::Engine
    # no isolate_namespace — host URL helpers must work inside engine code

    initializer "appkit.assets" do |app|
      app.config.assets.paths << root.join("app/assets/stylesheets").to_s
      app.config.assets.paths << root.join("app/javascript").to_s
    end

    initializer "appkit.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
      end
    end

    # Non-isolated: expose session_path/new_session_url etc. directly on the
    # host, matching JA's plain (unprefixed) route helpers, rather than
    # requiring an `appkit.` proxy.
    initializer "appkit.url_helpers" do
      ActiveSupport.on_load(:after_routes_loaded) do
        ActiveSupport.on_load(:action_controller) { include Appkit::Engine.routes.url_helpers }
        ActiveSupport.on_load(:action_view) { include Appkit::Engine.routes.url_helpers }
      end
    end
  end
end
