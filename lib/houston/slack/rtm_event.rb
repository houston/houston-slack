require "houston/slack/event"

module Houston::Slack
  class RtmEvent < Event
    attr_reader :match

    def initialize(message: nil, match_data: nil, listener: nil)
      super(message: message.text, channel: message.channel, sender: message.sender)
      @message_object = message
      @match = match_data
      @listener = listener
    end

    def matched?(key)
      match[key].present?
    end

    def stop_listening!
      listener.stop_listening!
    end

    def react!(emoji)
      Houston::Slack.connection.add_reaction(emoji, message_object)
    end

  private
    attr_reader :listener, :message_object

  end
end
