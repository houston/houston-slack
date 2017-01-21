module Houston
  module Slack
    class Command
      attr_reader :channel, :sender

      def initialize(channel: nil, sender: nil, controller: nil, response_url: nil)
        @channel = channel
        @sender = sender
        @controller = controller
        @response_url = response_url
      end


      def user
        sender.user
      end


      def respond!(message)
        raise Houston::Slack::AlreadyRespondedError if controller.performed?
        message = {text: message} if message.is_a?(String)
        controller.render json: message
      end

      def delayed_respond!(message)
        message = {text: message} if message.is_a?(String)
        Faraday.post response_url, message, { "Content-Type" => "application/json" }
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
        { channel: channel, sender: sender }
      end


    protected
      attr_reader :controller, :response_url
    end
  end
end
