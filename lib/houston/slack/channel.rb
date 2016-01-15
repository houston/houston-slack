module Houston
  module Slack
    class Channel
      attr_reader :id, :name, :type

      def initialize(attributes={})
        @id = attributes["id"]
        @name = attributes["name"]
        @type = :channel
        @type = :group if attributes["is_group"]

        if attributes["is_im"]
          @type = :direct_message
          @name = attributes["user"]["name"]
        end
      end

      def reply(*messages)
        messages.flatten!
        return unless messages.any?

        first_message = messages.shift
        message_options = {}
        message_options = messages.shift if messages.length == 1 && messages[0].is_a?(Hash)
        Houston::Slack.connection.send_message(first_message, message_options.merge(channel: id))

        messages.each do |message|
          Rails.logger.debug "\e[35m[slack:reply] Typing for %.2f seconds\e[0m" % [message.length / Houston::Slack.config.typing_speed] if Rails.env.development?
          sleep message.length / Houston::Slack.config.typing_speed
          Houston::Slack.connection.send_message(message, channel: id)
        end
      end
      alias :say :reply

      def random_reply(replies)
        if replies.is_a?(Hash)
          weights = replies.values
          unless weights.reduce(&:+) == 1.0
            raise ArgumentError, "Reply weights don't add up to 1.0"
          end

          draw = rand
          sum = 0
          pick = nil
          replies.each do |reply, weight|
            pick = reply unless sum > draw
            sum += weight
          end
          reply pick
        else
          reply replies.sample
        end
      end

      def direct_message?
        type == :direct_message
      end
      alias :dm? :direct_message?
      alias :im? :direct_message?

      def private_group?
        type == :group
      end
      alias :group? :private_group?
      alias :private? :private_group?

      def inspect
        "<Houston::Slack::Channel id=\"#{id}\" name=\"#{name}\">"
      end

      def to_s
        return name if private?
        return "@#{name}" if direct_message?
        "##{name}"
      end

    end
  end
end
