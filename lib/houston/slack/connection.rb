require "houston/slack/driver"
require "houston/slack/channel"
require "houston/slack/user"
require "faraday"

module Houston
  module Slack
    class Connection
      
      def initialize
        @client = Houston::Slack::Driver.new
        @open_channels = {}
      end
      
      
      
      def send_message(message, options={})
        channel = options.fetch(:channel) { raise ArgumentError, "Missing parameter :channel" }
        
        # Unless we've already got a valid channel ID, try to resolve it
        channel_id = channel
        channel_id = channels[channel_id] unless channel_id =~ /^[DGC]/
        raise ArgumentError, "Couldn't find a channel named #{channel}" unless channel_id
        
        client.send(type: "message", channel: channel_id, text: message)
      end
      
      
      def listen!
        puts "\e[94mConnecting to Slack\e[0m"
        Thread.new do
          begin
            __listen
          rescue Exception
            puts  "\e[31mDisconnected from Slack: #{$!.message}\n#{$!.backtrace}\e[0m"
          end
        end
      end
      
      
      
    private
      attr_reader :client, :bot_id, :bot_name, :users, :user_ids, :channels
      
      def __listen
        response = Faraday.post("https://slack.com/api/rtm.start", token: Houston::Slack.config.token)
        response = JSON.parse response.body
        websocket_url = response["url"]
        @bot_id = response["self"]["id"]
        @bot_name = response["self"]["name"]
        @users = response["users"].index_by { |attrs| attrs["id"] }
        
        @user_ids = Hash[response["users"].map { |attrs| ["@#{attrs["name"]}", attrs["id"]] }]
        @channels = Hash.new do |hash, key|
          if key.start_with?("@")
            user_id = user_ids[key]
            response = Faraday.post("https://slack.com/api/im.open", {
              token: Houston::Slack.config.token,
              user: user_id})
            response = JSON.parse response.body
            response["channel"]["id"]
          else
            nil
          end
        end
        @channels.merge! Hash[response["channels"].map { |attrs| ["##{attrs["name"]}", attrs["id"]] }]
        @channels.merge! Hash[response["groups"].map { |attrs| [attrs["name"], attrs["id"]] }]
        
        match_me = /<@#{bot_id}>|\b#{bot_name}\b/i
        
        client.connect_to websocket_url
        
        client.on(:error) do |*args|
          Rails.logger.error "\e[31m[slack:error] #{args.inspect}\e[0m"
        end
        
        client.on(:message) do |data|
          if data["error"]
            Rails.logger.error "\e[31m[slack:error] #{data["error"]["msg"]}\e[0m"
          end
          
          if data["type"] == "message" &&
             data["user"] != bot_id
            
            Rails.logger.debug "\e[35m[slack:hear:#{data.fetch("subtype", "message")}] #{data.pick("text", "channel", "user").inspect}\e[0m" if Rails.env.development?
            
            channel = Houston::Slack::Channel.new(data["channel"])
            user = nil
            text = data["text"]
            
            # Is someone talking directly to Houston?
            direct_mention = channel.direct_message? || match_me === text
            
            Houston::Slack.config.responders.each do |responder|
              
              # Does the responder care whether the message is addressed to Houston?
              # If so, skip responders whose dispositions don't match
              next if responder[:mention] && responder[:mention] != direct_mention
              
              # Does the message match one of Houston's known responses?
              next unless responder[:matcher] === text
              
              user ||= Houston::Slack::User.new(users[data["user"]])
              Houston.observer.fire responder[:event], user, channel
            end
          end
        end
        
        client.main_loop
      rescue Errno::EPIPE
        # We got disconnected retry
        Rails.logger.warn "\e[31mDisconnected from Slack; retrying\e[0m"
        sleep 5
        retry
      end
      
    end
  end
end
