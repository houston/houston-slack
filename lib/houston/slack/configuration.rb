require "houston/slack/listener"
require "thread_safe"

module Houston::Slack
  class Configuration
    attr_reader :listeners, :slash_commands

    def initialize
      @listeners = ThreadSafe::Array.new
      @typing_speed = 100.0
      @slash_commands = {}
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

    def listen_for(matcher, flags=[], &block)
      Listener.new(matcher, true, flags, block).tap do |listener|
        @listeners.push listener
      end
    end

    def overhear(matcher, flags=[], &block)
      Listener.new(matcher, false, flags, block).tap do |listener|
        @listeners.push listener
      end
    end

    def slash(command_name, &block)
      @slash_commands[command_name] = block
    end

  end
end
