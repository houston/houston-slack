require "houston/slack/conversation"

module Houston::Slack
  class Event
    attr_reader :message,
                :channel,
                :sender,
                :match

    def initialize(message: nil, channel: nil, sender: nil, match_data: nil, listener: nil)
      @message = message
      @channel = channel
      @sender = sender
      @match = match_data
      @listener = listener
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

    def matched?(key)
      match[key].present?
    end

    def stop_listening!
      listener.stop_listening!
    end

    def start_conversation!
      Conversation.new(channel, sender)
    end

  private
    attr_reader :listener

  end
end
