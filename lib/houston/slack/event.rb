require "houston/slack/conversation"

module Houston::Slack
  class Event
    attr_reader :message, :channel, :sender

    def initialize(message: nil, channel: nil, sender: nil)
      @message = message
      @channel = channel
      @sender = sender
    end

    def user
      return @user if defined?(@user)
      @user = sender && ::User.find_by_email_address(sender.email)
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

  end
end
