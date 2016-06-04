require "slacks"
require "houston/slack/session"

module Houston
  module Slack
    class Connection
      attr_reader :connection, :session, :connected_at

      def initialize
        @connection = Slacks::Connection.new(nil)
        @session = Houston::Slack::Session.new(connection)
      end

      delegate :send_message,
               :get_message,
               :update_message,
               :add_reaction,
               :channels,
               :find_channel,
               :find_user,
               :find_user_by_nickname,
               :user_exists?,
               :users,
               :team,
               :bot,
               :token,
               :typing_speed,
               :typing_speed=,
               to: "connection"

      def token=(value)
        connection.instance_variable_set :@token, value
      end



      def listen!
        Houston.daemonize "slack" do
          begin
            @connected_at = Time.now
            @listening = true
            connection.listen!

          rescue Slacks::MigrationInProgress
            # Slack is migrating our team to another server
            Rails.logger.warn "\e[33m[daemon:slack] migration in progress\e[0m"
            Houston.observer.fire "daemon:slack:reconnecting"
            sleep 5
            retry

          rescue Errno::EPIPE
            # We got disconnected. Retry
            Rails.logger.warn "\e[31m[daemon:slack] Disconnected from Slack; retrying\e[0m"
            Houston.observer.fire "daemon:slack:reconnecting"
            sleep 5
            retry
          end
        end

        @listening = false
      end

      def listening?
        @listening
      end



    end
  end
end
