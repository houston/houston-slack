require "houston/slack/channel"

module Houston
  module Slack
    class Message
      attr_reader :session, :data, :text, :contexts

      def initialize(session, data)
        @session = session
        @data = data
        @text = data["text"] || ""
        @contexts = [:slack]
        @contexts << :conversation if channel.direct_message?
      end

      alias :to_s :text

      def channel
        return @channel if defined?(@channel)
        @channel = session.connection.find_channel(data["channel"], data["thread_ts"])
      end

      def sender
        return @sender if defined?(@sender)
        @sender = session.connection.find_user data["user"]
      end

      def timestamp
        data["ts"]
      end

      def type
        data.fetch("subtype", "message")
      end


      def add_reaction(emoji)
        session.connection.add_reaction(emoji, self)
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
