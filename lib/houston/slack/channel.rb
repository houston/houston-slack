module Houston
  module Slack
    class Channel
      attr_reader :id
      
      def initialize(id)
        @id = id
      end
      
      def reply(message)
        Houston::Slack.connection.send_message(message, channel: id)
      end
      
      def direct_message?
        id.start_with? "D"
      end
      
    end
  end
end
