module Houston
  module Slack
    class Reaction
      attr_reader :emoji, :sender, :message

      def initialize(session, data)
        @emoji = data["reaction"]
        @sender = session.slack.find_user data["user"]

        message = Houston::Slack.connection.get_message data["item"]["channel"], data["item"]["ts"]
        raise Slacks::ResponseError.new(message, message["error"]) unless message["ok"]
        message_data = message.slice("type", "channel").merge(
          message["message"].slice("user", "text", "ts", "attachments", "reactions"))
        @message = Houston::Slack::Message.new(session, message_data)

      rescue
        $!.additional_information["data"] = data
        $!.additional_information["message"] = message_data
        raise
      end



      def channel
        message.channel
      end

      def user
        sender.user
      end



      def reply(*args)
        channel.reply(*args)
      end

      def random_reply(*args)
        channel.random_reply(*args)
      end

      def start_conversation!
        Conversation.new(channel, sender)
      end



      def to_h
        { channel: channel, message: message, sender: sender }
      end

    end
  end
end
