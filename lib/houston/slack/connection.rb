require "slacks"
require "houston/slack/session"

module Houston
  module Slack
    class Connection
      attr_reader :connected_at
      attr_accessor :token

      delegate :send_message,
               :get_message,
               :update_message,
               :add_reaction,
               :channels,
               :can_see?,
               :find_user,
               :find_user_by_nickname,
               :user_exists?,
               :users,
               :team,
               :bot,
               :typing_speed,
               :typing_speed=,
               to: "connection"

      def connection
        @connection ||= Slacks::Connection.new(token)
      end



      def find_channel(id, thread_ts=nil)
        Houston::Slack::Channel.new(connection.find_channel(id), thread_ts)
      end



      def listen!
        Houston.daemonize "slack" do
          Houston.try(16) do # 2s, 4s, 8s, 16s, 32s, 64s, 2m, 4m, 8m, 17m, 34m, 68m, 2h, 4h, 9h, 18h
            begin
              @connected_at = Time.now
              @listening = true
              connection.listen!

            rescue Slacks::Response::MigrationInProgress
              @listening = false
              # Slack is migrating our team to another server
              Rails.logger.warn "\e[33m[daemon:slack] migration in progress\e[0m"
              Houston.observer.fire "daemon:slack:reconnecting"
              sleep 5
              retry

            rescue Errno::EPIPE
              @listening = false
              # We got disconnected. Retry
              Rails.logger.warn "\e[31m[daemon:slack] Disconnected from Slack; retrying\e[0m"
              Houston.observer.fire "daemon:slack:reconnecting"
              sleep 5
              retry

            rescue
              @listening = false
              Houston.report_exception $!
              Houston.observer.fire "daemon:slack:reconnecting"
              raise
            end
          end
        end
      end

      def listening?
        @listening
      end



    end
  end
end
