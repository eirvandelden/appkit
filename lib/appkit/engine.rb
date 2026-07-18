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
  end
end
