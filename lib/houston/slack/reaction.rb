require "houston/slack/event"

module Houston
  module Slack
    class Reaction < Houston::Slack::Event
      attr_reader :emoji

      def initialize(session, data)
        message = Houston::Slack.connection.get_message data["item"]["channel"], data["item"]["ts"]
        raise "Unable to fetch message" unless message["ok"]
        sender = session.slack.find_user data["user"]
        message = Houston::Slack::Message.new(session,
          message.slice("type", "channel").merge(
            message["message"].slice("user", "text", "ts", "attachments", "reactions")))
        super(session: session, message: message, channel: message.channel, sender: sender)
        @emoji = data["reaction"]
      end

    end
  end
end
