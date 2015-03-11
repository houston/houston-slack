module Houston
  module Slack
    class Channel
      attr_reader :id, :name, :type
      
      def initialize(attributes={})
        @id = attributes["id"]
        @name = attributes["name"]
        @type = :channel
        @type = :direct_message if attributes["is_im"]
        @type = :group if attributes["is_group"]
      end
      
      def reply(message)
        Houston::Slack.connection.send_message(message, channel: id)
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
      
      def to_s
        "<#{id}|#{name}>"
      end
      
    end
  end
end
