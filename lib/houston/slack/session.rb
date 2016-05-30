require "slacks"

module Houston
  module Slack
    class Session < ::Slacks::Session

      def initialize
        super nil
      end

      def error(message)
        Houston.observer.fire "slack:error", message
      end

      def message(data)
        super
      rescue Exception # rescues StandardError by default; but we want to rescue and report all errors
        Houston.report_exception $!
        Rails.logger.error "\e[31m[slack:exception] (#{$!.class}) #{$!.message}\n  #{$!.backtrace.join("\n  ")}\e[0m"
      end

    protected

      def invoke!(listener, e)
        Rails.logger.debug "\e[35m[slack:hear:#{e.message.type}] #{e.message}\e[0m"

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
