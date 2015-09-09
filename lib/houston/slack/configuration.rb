require "houston/slack/listener"
require "thread_safe"

module Houston::Slack
  class Configuration
    attr_reader :listeners

    def initialize
      @listeners = ThreadSafe::Array.new
      @typing_speed = 100.0
    end

    # Define configuration DSL here

    def token(*args)
      @token = args.first if args.any?
      @token
    end

    def typing_speed(*args)
      @typing_speed = args.first.to_f if args.any?
      @typing_speed
    end

    def listen_for(matcher, &block)
      Listener.new(matcher, true, block).tap do |listener|
        @listeners.push listener
      end
    end

    def overhear(matcher, &block)
      Listener.new(matcher, false, block).tap do |listener|
        @listeners.push listener
      end
    end

  end
end
