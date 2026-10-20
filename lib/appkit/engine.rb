module Appkit
  class Engine < ::Rails::Engine
    # no isolate_namespace — host URL helpers must work inside engine code

    # initializer is an engine DSL call that the railties RBS does not describe.
    initializer "appkit.assets" do |app| # steep:ignore NoMethod
      # root is an engine DSL call that the railties RBS does not describe.
      app.config.assets.paths << root.join("app/assets/stylesheets").to_s # steep:ignore NoMethod
      # root is an engine DSL call that the railties RBS does not describe.
      app.config.assets.paths << root.join("app/javascript").to_s # steep:ignore NoMethod
    end

    # initializer is an engine DSL call that the railties RBS does not describe.
    initializer "appkit.importmap", before: "importmap" do |app| # steep:ignore NoMethod
      if app.config.respond_to?(:importmap)
        # root is an engine DSL call that the railties RBS does not describe.
        app.config.importmap.paths << root.join("config/importmap.rb") # steep:ignore NoMethod
      end
    end

    # initializer is an engine DSL call that the railties RBS does not describe.
    initializer "appkit.health_checks" do |app| # steep:ignore NoMethod
      # okcomputer ships no RBS in the collection.
      ::OkComputer.mount_at = Appkit.config.health_check_path # steep:ignore UnknownConstant

      # register_cache_check is an engine DSL call that the railties RBS does not describe.
      register_cache_check # steep:ignore NoMethod
      # register_queue_check is an engine DSL call that the railties RBS does not describe.
      register_queue_check(app) # steep:ignore NoMethod
    end

    private

    # SolidCache is optional: only wire this check when it's actually the
    # configured cache store, so host apps on a different cache backend
    # don't get a check that could never be meaningfully green.
    #: () -> void
    def register_cache_check
      # solid_cache ships no RBS in the collection.
      return unless defined?(SolidCache) && Rails.cache.is_a?(SolidCache::Store) # steep:ignore UnknownConstant

      # okcomputer ships no RBS in the collection.
      ::OkComputer::Registry.register("cache", ::OkComputer::CacheCheckSolidCache.new) # steep:ignore UnknownConstant
    end

    # Solid Queue is optional too: only register worker-liveness monitoring
    # when it's the active_job adapter, since the check is meaningless (or
    # would error) against a different backend.
    #: (untyped) -> void
    def register_queue_check(app)
      return unless app.config.active_job.queue_adapter == :solid_queue

      # okcomputer ships no RBS in the collection.
      ::OkComputer::Registry.register("queue", Appkit::OkComputer::SolidQueueCheck.new) # steep:ignore UnknownConstant
    end
  end
end
