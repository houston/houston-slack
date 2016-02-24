# This is a channel that Houston is aware of
# but is not a member of — and cannot reply to.
#
# It should expose the same API as channel,
# but you will not be able to reply on this
# channel or start a conversation on it.

module Houston
  module Slack
    class GuestChannel < Channel

      def initialize(params)
        @id = attributes["channel_id"]
        @name = attributes["channel_name"]

        @type = :channel
        @type = :group if id.start_with?("G")
        @type = :direct_message if id.start_with?("D")
      end

      def reply(*args)
        raise NotInChannelError, self
      end
      alias :say :reply

      def random_reply(*args)
        raise NotInChannelError, self
      end

      def guest?
        true
      end

    end
  end
end
