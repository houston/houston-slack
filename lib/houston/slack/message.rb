require "houston/conversations/message"

module Houston
  module Slack
    class Message < ::Houston::Conversations::Message
      attr_reader :session, :data

      def initialize(session, data, params={})
        @session = session
        @data = data
        super data.fetch("text", ""), params
        contexts << :conversation if channel.direct_message?
        contexts << :slack
      end


      def channel
        return @channel if defined?(@channel)
        @channel = session.slack.find_channel data["channel"]
      end

      def sender
        return @sender if defined?(@sender)
        @sender = session.slack.find_user data["user"]
      end

      def timestamp
        data["ts"]
      end

      def type
        data.fetch("subtype", "message")
      end


      def add_reaction(emoji)
        session.slack.add_reaction(emoji, self)
      end


      def respond_to_missing?(method, include_all)
        return true if text.respond_to?(method)
        super
      end

      def method_missing(method, *args, &block)
        return text.public_send(method, *args, &block) if text.respond_to?(method)
        super
      end

    end
  end
end
