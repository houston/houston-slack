module Houston
  module Slack
    class SlashCommand
      attr_reader :message, :channel, :sender, :controller, :response_url

      def initialize(message: nil, channel: nil, sender: nil, controller: nil, response_url: nil)
        @message = message
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
        { channel: channel, message: message, sender: sender }
      end



    private
      attr_reader :controller, :response_url

    end
  end
end
