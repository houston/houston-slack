require "houston/slack/command"

module Houston
  module Slack
    class Action < Houston::Slack::Command
      attr_reader :name, :value, :ts, :original_message, :attachment_index

      def initialize(name: nil, value: nil, ts: nil, original_message: nil, attachment_index: nil, **args)
        @name = name
        @value = value
        @ts = ts
        @original_message = original_message
        @attachment_index = attachment_index
        super **args
      end

      def to_h
        super.merge(name: name, value: value, ts: ts, original_message: original_message, attachment_index: attachment_index)
      end

    end
  end
end
