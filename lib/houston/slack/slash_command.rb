require "houston/slack/event"

module Houston
  module Slack
    class SlashCommand < Houston::Slack::Event

      def initialize(message: nil, channel: nil, sender: nil, controller: nil, response_url: nil)
        super(session: Houston::Slack.connection.session, message: message, channel: channel, sender: sender)
        @controller = controller
        @response_url = response_url
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

      def text
        puts "DEPRECATED: use `Houston::Slack::SlashCommand#message` instead of `text`"
        message
      end

    private
      attr_reader :controller, :response_url

    end
  end
end
