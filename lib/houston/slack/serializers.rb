module Houston
  module Slack
    class ChannelSerializer
      def applies_to?(object)
        object.is_a?(Houston::Slack::Channel)
      end

      def pack(channel)
        { "id" => channel.id, "thread_ts" => channel.thread_ts }
      end

      def unpack(object)
        Houston::Slack.connection.find_channel(object.fetch("id"), object["thread_ts"])
      end
    end

    class MessageSerializer
      def applies_to?(object)
        object.is_a? Houston::Slack::Message
      end

      def pack(message)
        { "data" => message.data }
      end

      def unpack(object)
        message_data = object.fetch("data")
        Houston::Slack::Message.new(Houston::Slack.session, message_data)
      end
    end

    class SenderSerializer
      def applies_to?(object)
        object.is_a? Slacks::User
      end

      def pack(user)
        { "id" => user.id }
      end

      def unpack(object)
        Houston::Slack.connection.find_user object.fetch("id")
      end
    end
  end
end
