require "test_helper"

module Appkit
  class EngineTest < ActiveSupport::TestCase
    test "mounts the health check endpoint at the configured health_check_path" do
      assert_equal Appkit.config.health_check_path, ::OkComputer.mount_at
    end

    test "registers a queue check when the queue adapter is :solid_queue" do
      assert_includes ::OkComputer::Registry.all.check_names, "queue"
    end

    test "does not register a queue check when the queue adapter is not :solid_queue" do
      fake_app = FakeApp.new(queue_adapter: :async)
      ::OkComputer::Registry.deregister("queue")

      Engine.instance.send(:register_queue_check, fake_app)

      assert_not_includes ::OkComputer::Registry.all.check_names, "queue"
    ensure
      Engine.instance.send(:register_queue_check, fake_app_with_solid_queue)
    end

    test "registers a cache check when Rails.cache is a SolidCache::Store" do
      assert_includes ::OkComputer::Registry.all.check_names, "cache"
    end

    test "does not register a cache check when Rails.cache is not a SolidCache::Store" do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::NullStore.new
      ::OkComputer::Registry.deregister("cache")

      Engine.instance.send(:register_cache_check)

      assert_not_includes ::OkComputer::Registry.all.check_names, "cache"
    ensure
      Rails.cache = original_cache
      Engine.instance.send(:register_cache_check)
    end

    private

    def fake_app_with_solid_queue
      FakeApp.new(queue_adapter: :solid_queue)
    end

    FakeApp = Struct.new(:queue_adapter) do
      def config
        Struct.new(:active_job).new(Struct.new(:queue_adapter).new(queue_adapter))
      end
    end
  end
end
