require "slacks"

module Houston::Slack
  class Configuration
    attr_reader :slash_commands

    def initialize
      @slash_commands = {}
    end

    # Define configuration DSL here

    def token(*args)
      Houston::Slack.connection.token = args.first if args.any?
      Houston::Slack.connection.token
    end

    def typing_speed(*args)
      Houston::Slack.connection.typing_speed = args.first.to_f if args.any?
      Houston::Slack.connection.typing_speed
    end

    def listen_for(matcher, flags=[], &block)
      Slacks::Listener.new(Houston::Slack.connection.session, matcher, true, flags, block).tap do |listener|
        Houston::Slack.connection.session.listeners.instance_variable_get(:@listeners).push listener
      end
    end

    def overhear(matcher, flags=[], &block)
      Slacks::Listener.new(Houston::Slack.connection.session, matcher, false, flags, block).tap do |listener|
        Houston::Slack.connection.session.listeners.instance_variable_get(:@listeners).push listener
      end
    end

    def slash(command_name, &block)
      @slash_commands[command_name] = block
    end

  end
end
