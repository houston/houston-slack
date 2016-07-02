require "houston/slack/entities"
require "houston/slack/message"
require "houston/slack/reaction"
require "houston/slack/rtm_event"
require "houston/slack/sender_ext"

module Houston
  module Slack
    class Session

      attr_reader :slack

      def initialize(slack)
        @slack = slack
        bind :connected,
             :error,
             :message,
             :reaction_added,
             :reaction_removed
      end

    protected

      def connected
        Attentive.invocations = [slack.bot.name, slack.bot.to_s]
      end

      def error(message)
        Houston.observer.fire "slack:error", message
      end

      def message(data)

        # Don't respond to things that another bot said
        return if data.fetch("subtype", "message") == "bot_message"

        # Normalize mentions of users
        data["text"].gsub!(/<@U[^|]+\|([^>]*)>/, %q{@\1})

        # Normalize mentions of channels
        data["text"].gsub!(/<[@#]?([UC][^>]+)>/) do |match|
          begin
            slack.find_channel($1)
          rescue ArgumentError
            match
          end
        end

        message = Houston::Slack::Message.new(self, data)
        Houston::Conversations.hear(message) do |event|
          event.extend Houston::Slack::RtmEvent
        end

      rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
        Houston.report_exception $!
        Rails.logger.error "\e[31m[slack:exception] (#{$!.class}) #{$!.message}\n  #{$!.backtrace.join("\n  ")}\e[0m"
      end

      def reaction_added(data)
        # Only care about messages for now
        return unless data["item"]["type"] == "message"
        e = Houston::Slack::Reaction.new(self, data)
        Houston.observer.fire "slack:reaction:added", e
      end

      def reaction_removed(data)
        # Only care about messages for now
        return unless data["item"]["type"] == "message"
        e = Houston::Slack::Reaction.new(self, data)
        Houston.observer.fire "slack:reaction:removed", e
      end

    private

      def bind(*events)
        events.each do |event|
          slack.on event, &method(event)
        end
      end

    end
  end
end
