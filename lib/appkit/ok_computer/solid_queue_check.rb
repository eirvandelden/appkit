module Appkit
  module OkComputer
    # Verifies a Solid Queue worker is alive by requiring a recent process
    # heartbeat. Deliberately does not check queue depth/backlog: a backed-up
    # queue during a legitimate batch job isn't necessarily unhealthy, while a
    # worker that stopped heartbeating is the load-bearing uptime signal.
    class SolidQueueCheck < ::OkComputer::Check
      def check
        if recent_heartbeat?
          mark_message "Solid Queue worker heartbeat found"
        else
          mark_failure
          mark_message "No Solid Queue worker heartbeat within #{::SolidQueue.process_alive_threshold.inspect}"
        end
      end

      private

      def recent_heartbeat?
        ::SolidQueue::Process.where(last_heartbeat_at: ::SolidQueue.process_alive_threshold.ago..).exists?
      end
    end
  end
end
