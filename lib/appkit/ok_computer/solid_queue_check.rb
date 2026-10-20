module Appkit
  module OkComputer
    # Verifies a Solid Queue worker is alive by requiring a recent process
    # heartbeat. Deliberately does not check queue depth/backlog: a backed-up
    # queue during a legitimate batch job isn't necessarily unhealthy, while a
    # worker that stopped heartbeating is the load-bearing uptime signal.
    # okcomputer ships no RBS, so its Check superclass cannot be typed.
    # @rbs inherits ::Object
    class SolidQueueCheck < ::OkComputer::Check # steep:ignore UnknownConstant
      #: () -> void
      def check
        if recent_heartbeat?
          # okcomputer ships no RBS, so its Check methods cannot be typed.
          mark_message "Solid Queue worker heartbeat found" # steep:ignore NoMethod
        else
          # okcomputer ships no RBS, so its Check methods cannot be typed.
          mark_failure # steep:ignore NoMethod
          # okcomputer ships no RBS, so its Check methods cannot be typed. solid_queue ships no RBS in the collection.
          # steep:ignore:start
          mark_message "No Solid Queue worker heartbeat within #{::SolidQueue.process_alive_threshold.inspect}"
          # steep:ignore:end
        end
      end

      private

      #: () -> bool
      def recent_heartbeat?
        # solid_queue ships no RBS in the collection.
        # steep:ignore:start
        ::SolidQueue::Process.where(last_heartbeat_at: ::SolidQueue.process_alive_threshold.ago..).exists?
        # steep:ignore:end
      end
    end
  end
end
