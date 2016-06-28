require "houston/slack/event"

module Houston
  module Slack
    class Reaction < Houston::Slack::Event
      attr_reader :emoji

      def initialize(session, data)
        @emoji = data["reaction"]
        sender = session.slack.find_user data["user"]

        message = Houston::Slack.connection.get_message data["item"]["channel"], data["item"]["ts"]
        raise Slacks::ResponseError.new(message, message["error"]) unless message["ok"]
        message_data = message.slice("type", "channel").merge(
          message["message"].slice("user", "text", "ts", "attachments", "reactions"))
        message = Houston::Slack::Message.new(session, message_data)

        super(session: session, message: message, channel: message.channel, sender: sender)
      rescue
        $!.additional_information["data"] = data
        $!.additional_information["message"] = message_data
        raise
      end

    end
  end
end
