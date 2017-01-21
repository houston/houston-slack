require "houston/slack/command"

module Houston
  module Slack
    class SlashCommand < Houston::Slack::Command
      attr_reader :message

      def initialize(message: nil, **args)
        @message = message
        super **args
      end

      def to_h
        super.merge(message: message)
      end

    end
  end
end
