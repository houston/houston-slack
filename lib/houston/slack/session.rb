require "attentive"
require "houston/slack/entities"
require "houston/slack/listener_collection"
require "houston/slack/message"
require "houston/slack/reaction"
require "houston/slack/rtm_event"

module Houston
  module Slack
    class Session
      include Attentive

      attr_reader :slack

      def initialize(slack)
        @slack = slack
        bind :connected,
             :error,
             :message,
             :reaction_added,
             :reaction_removed
      end

      def listeners
        @listeners ||= Houston::Slack::ListenerCollection.new
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
        hear(message).each do |match|

          event = Houston::Slack::RtmEvent.new(self, match)
          invoke! match.listener, event

          # Invoke only one listener per message
          return
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

      def invoke!(listener, e)
        Rails.logger.debug "\e[35m[slack:hear:#{e.message.type}] #{e.message}\e[0m"

        Houston.async do
          begin
            listener.call(e)
          rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
            Houston.report_exception $!, parameters: {channel: e.channel, message: e.message, sender: e.sender}
            Rails.logger.error "\e[31m[slack:exception] (#{$!.class}) #{$!.message}\n  #{$!.backtrace.join("\n  ")}\e[0m"
            e.reply "An error occurred when I was trying to answer you"
          end
        end
      end

      def bind(*events)
        events.each do |event|
          slack.on event, &method(event)
        end
      end

    end
  end
end
