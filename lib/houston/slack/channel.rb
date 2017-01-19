module Houston
  module Slack
    class Channel < SimpleDelegator
      attr_reader :thread_ts

      def initialize(channel, thread_ts)
        @thread_ts = thread_ts
        super channel
      end

      def reply(*messages)
        messages.push({}) if messages.length == 1
        if messages.last.is_a?(Hash) && thread_ts
          messages.last.merge! thread_ts: thread_ts
        end
        super
      end

    end
  end
end
