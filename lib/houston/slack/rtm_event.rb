module Houston
  module Slack
    module RtmEvent

      def react(emoji)
        message.add_reaction(emoji)
      end

      def responding
        channel.typing
      end

    end
  end
end
