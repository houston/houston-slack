require "houston/slack/event"

module Houston::Slack
  class RtmEvent < Event
    attr_reader :match

    def initialize(message: nil, channel: nil, sender: nil, match_data: nil, listener: nil)
      super(message: message, channel: channel, sender: sender)
      @match = match_data
      @listener = listener
    end

    def matched?(key)
      match[key].present?
    end

    def stop_listening!
      listener.stop_listening!
    end

  private
    attr_reader :listener

  end
end
