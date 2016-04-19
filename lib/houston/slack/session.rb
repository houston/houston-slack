require "slacks"

module Houston
  module Slack
    class Session < Slacks::Session
      attr_writer :typing_speed, :token

      def initialize
        super nil
      end

      def error(message)
        Houston.observer.fire "slack:error", message
      end

    protected

      def process_message(data)
        super
      rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
        Houston.report_exception $!
        Rails.logger.error "\e[31m[slack:exception] (#{$!.class}) #{$!.message}\n  #{$!.backtrace.join("\n  ")}\e[0m"
      end

      def invoke!(listener, e)
        Rails.logger.debug "\e[35m[slack:hear:#{e.message_object.type}] #{e.message_object.inspect}\e[0m"

        Thread.new do
          begin
            listener.call(e)
          rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
            Houston.report_exception $!, parameters: {channel: e.channel, message: e.message, sender: e.sender}
            Rails.logger.error "\e[31m[slack:exception] (#{$!.class}) #{$!.message}\n  #{$!.backtrace.join("\n  ")}\e[0m"
            e.reply "An error occurred when I was trying to answer you"
          ensure
            ActiveRecord::Base.clear_active_connections!
          end
        end
      end

    end
  end
end
