require "houston/slack/event"

module Houston::Slack
  class SlashCommand < Event

    def initialize(message: nil, channel: nil, sender: nil, controller: nil)
      super(message: message, channel: channel, sender: sender)
      @controller = controller
    end

    def respond!(message)
      raise Houston::Slack::AlreadyRespondedError if controller.performed?
      controller.render text: message
    end

    def text
      puts "DEPRECATED: use `Houston::Slack::SlashCommand#message` instead of `text`"
      message
    end

  private
    attr_reader :controller

  end
end
