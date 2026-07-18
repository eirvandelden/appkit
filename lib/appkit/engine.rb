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

    initializer "appkit.health_checks" do |app|
      ::OkComputer.mount_at = Appkit.config.health_check_path

      register_cache_check
      register_queue_check(app)
    end

    private

    # SolidCache is optional: only wire this check when it's actually the
    # configured cache store, so host apps on a different cache backend
    # don't get a check that could never be meaningfully green.
    def register_cache_check
      return unless defined?(SolidCache) && Rails.cache.is_a?(SolidCache::Store)

      ::OkComputer::Registry.register("cache", ::OkComputer::CacheCheckSolidCache.new)
    end

    # Solid Queue is optional too: only register worker-liveness monitoring
    # when it's the active_job adapter, since the check is meaningless (or
    # would error) against a different backend.
    def register_queue_check(app)
      return unless app.config.active_job.queue_adapter == :solid_queue

      ::OkComputer::Registry.register("queue", Appkit::OkComputer::SolidQueueCheck.new)
    end
  end
end
