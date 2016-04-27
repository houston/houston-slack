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

    def listen_for(*args, &block)
      Houston::Slack.connection.session.listeners.listen_for(*args, &block)
    end

    def overhear(*args, &block)
      Houston::Slack.connection.session.listeners.overhear(*args, &block)
    end

    def slash(command_name, &block)
      @slash_commands[command_name] = block
    end

  end
end
