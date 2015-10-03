require "houston/slack/channel"
require "houston/slack/conversation"
require "houston/slack/driver"
require "houston/slack/event"
require "houston/slack/listener"
require "houston/slack/user"
require "houston/slack/errors"
require "faraday"

module Houston
  module Slack
    class Connection
      EVENT_MESSAGE = "message".freeze
      EVENT_GROUP_JOINED = "group_joined".freeze
      EVENT_USER_JOINED = "team_join".freeze
      ME = "@houston".freeze
      
      def initialize
        @user_ids_dm_ids = {}
        @users_by_id = {}
        @user_id_by_name = {}
        @groups_by_id = {}
        @group_id_by_name = {}
        @channels_by_id = {}
        @channel_id_by_name = {}
      end
      
      
      
      def send_message(message, options={})
        channel = options.fetch(:channel) { raise ArgumentError, "Missing parameter :channel" }
        attachments = Array(options[:attachments])
        params = {
          channel: to_channel_id(channel),
          text: message,
          as_user: true, # post as the authenticated user (rather than as slackbot)
          link_names: 1} # find and link channel names and user names
        params.merge!(attachments: MultiJson.dump(attachments)) if attachments.any?
        params.merge!(options.slice(:username, :as_user, :parse, :link_names,
          :unfurl_links, :unfurl_media, :icon_url, :icon_emoji))
        api("chat.postMessage", params)
      end
      
      
      def listen!
        Houston.daemonize "slack" do
          begin
            @connected_at = Time.now
            @listening = true
            __listen

          rescue MigrationInProgress
            # Slack is migrating our team to another server
            Rails.logger.warn "\e[33m[daemon:slack] migration in progress\e[0m"
            Houston.observer.fire "daemon:#{name}:reconnecting"
            sleep 5
            retry

          rescue Errno::EPIPE
            # We got disconnected. Retry
            Rails.logger.warn "\e[31m[daemon:slack] Disconnected from Slack; retrying\e[0m"
            Houston.observer.fire "daemon:#{name}:reconnecting"
            sleep 5
            retry
          end
        end

        @listening = false
      end
      
      attr_reader :connected_at
      
      def listening?
        @listening
      end
      
      def channels
        user_id_by_name.keys + group_id_by_name.keys + channel_id_by_name.keys
      end
      
      
      
    private
      attr_reader :client,
                  :bot_id,
                  :bot_name,
                  :user_ids_dm_ids,
                  :users_by_id,
                  :user_id_by_name,
                  :groups_by_id,
                  :group_id_by_name,
                  :channels_by_id,
                  :channel_id_by_name,
                  :websocket_url
      
      def __listen
        response = api("rtm.start")

        unless response["ok"]
          if response["error"] == "migration_in_progress"
            raise MigrationInProgress
          else
            raise ResponseError.new(response, response["error"])
          end
        end

        begin
          @websocket_url = response.fetch("url")
          @bot_id = response.fetch("self").fetch("id")
          @bot_name = response.fetch("self").fetch("name")
          
          @channels_by_id = response.fetch("channels").index_by { |attrs| attrs.fetch("id") }
          @channel_id_by_name = Hash[response.fetch("channels").map { |attrs| ["##{attrs.fetch("name")}", attrs.fetch("id")] }]
          
          @users_by_id = response.fetch("users").index_by { |attrs| attrs.fetch("id") }
          @user_id_by_name = Hash[response.fetch("users").map { |attrs| ["@#{attrs.fetch("name")}", attrs.fetch("id")] }]
          
          @groups_by_id = response.fetch("groups").index_by { |attrs| attrs.fetch("id") }
          @group_id_by_name = Hash[response.fetch("groups").map { |attrs| [attrs.fetch("name"), attrs.fetch("id")] }]
        rescue KeyError
          raise ResponseError.new(response, $!.message)
        end
        
        match_me = /<@#{bot_id}>|\b#{bot_name}\b/i
        
        @client = Houston::Slack::Driver.new
        client.connect_to websocket_url
        
        client.on(:error) do |*args|
          Rails.logger.error "\e[31m[slack:error] #{args.inspect}\e[0m"
          Houston.observer.fire "slack:error", args
        end
        
        client.on(:message) do |data|
          begin
            if data["error"]
              Rails.logger.error "\e[31m[slack:error] #{data["error"]["msg"]}\e[0m"
            end
            
            case data["type"]
            when EVENT_GROUP_JOINED
              group = data["channel"]
              @groups_by_id[group["id"]] = group
              @group_id_by_name[group["name"]] = group["id"]
              
            when EVENT_USER_JOINED
              user = data["user"]
              @users_by_id[user["id"]] = user
              @user_id_by_name[user["name"]] = user["id"]
              
            when EVENT_MESSAGE
              message = data["text"]
              
              if data["user"] != bot_id && !message.blank?
                channel = Houston::Slack::Channel.new(find_channel(data["channel"])) if data["channel"]
                sender = Houston::Slack::User.new(find_user(data["user"])) if data["user"]
                
                # Normalize mentions of Houston
                message.gsub! match_me, ME
                
                # Normalize other parts of the message
                message = normalize_message(message)
                
                # Is someone talking directly to Houston?
                direct_mention = channel.direct_message? || message[ME]
                
                Houston::Slack.config.listeners.each do |listener|
                  # Listeners come in two flavors: direct and indirect
                  #
                  # To trigger a direct listener, Houston must be directly
                  # spoken to: as when the bot is mentioned or it is in
                  # a conversation with someone.
                  #
                  # An indirect listener is triggered in any context
                  # when it matches.
                  #
                  # We can ignore any listener that definitely doesn't
                  # meet these criteria.
                  next unless listener.indirect? or direct_mention or listener.conversation
                  
                  # Does the message match one of Houston's known responses?
                  match_data = listener.match message
                  next unless match_data
                  
                  e = Houston::Slack::Event.new(
                    message: message,
                    match_data: match_data,
                    channel: channel,
                    sender: sender,
                    listener: listener)
                  
                  # Skip listeners if they are not part of this conversation
                  next unless listener.indirect? or direct_mention or listener.conversation.includes?(e)
                  
                  Rails.logger.debug "\e[35m[slack:hear:#{data.fetch("subtype", "message")}] #{message}  (from: #{sender}, channel: #{channel})\e[0m"
                  
                  listener.call(e)
                end
              end
            end
          rescue Exception
            Houston.report_exception $!
          end
        end
        
        client.main_loop
        
      rescue EOFError
        # Slack hung up on us, we'll ask for a new WebSocket URL
        # and reconnect.
        Rails.logger.warn "\e[33m[slack:error] Websocket Driver received EOF; reconnecting\e[0m"
        retry
      end
      
      
      
      def to_channel_id(name)
        return name if name =~ /^[DGC]/ # this already looks like a channel id
        return get_dm_for_username(name) if name.start_with?("@")
        return to_group_id(name) unless name.start_with?("#")
        
        channel_id = channel_id_by_name[name]
        unless channel_id
          response = api("channels.list")
          @channels_by_id = response["channels"].index_by { |attrs| attrs["id"] }
          @channel_id_by_name = Hash[response["channels"].map { |attrs| ["##{attrs["name"]}", attrs["id"]] }]
          channel_id = channel_id_by_name[name]
        end
        raise ArgumentError, "Couldn't find a channel named #{name}" unless channel_id
        channel_id
      end
      
      def to_group_id(name)
        group_id = group_id_by_name[name]
        # Bot Users are not allowed to call `groups.list`
        # so I'm not sure how to look up a private group's ID
        # when we aren't intending to call `rtm.start`.
        raise ArgumentError, "Couldn't find a private group named #{name}" unless group_id
        group_id
      end
      
      def get_dm_for_username(name)
        get_dm_for_user_id to_user_id(name)
      end
      
      def to_user_id(name)
        user_id = user_id_by_name[name]
        unless user_id
          response = api("users.list")
          @users_by_id = response["members"].index_by { |attrs| attrs["id"] }
          @user_id_by_name = Hash[response["members"].map { |attrs| ["@#{attrs["name"]}", attrs["id"]] }]
          user_id = user_id_by_name[name]
        end
        raise ArgumentError, "Couldn't find a user named #{name}" unless user_id
        user_id
      end
      
      def get_dm_for_user_id(user_id)
        channel_id = user_ids_dm_ids[user_id] ||= begin
          response = api("im.open", user: user_id)
          raise ArgumentError, "Unable to direct message the user #{user_id.inspect}: #{response["error"]}" unless response["ok"]
          response["channel"]["id"]
        end
        raise ArgumentError, "Unable to direct message the user #{user_id.inspect}" unless channel_id
        channel_id
      end
      
      
      
      def find_channel(id)
        case id
        when /^U/ then find_user(id)
        when /^G/ then find_group(id)
        when /^D/
          user = find_user(get_user_id_for_dm(id))
          { "id" => id,
            "is_im" => true,
            "name" => user["real_name"],
            "user" => user }
        else
          channels_by_id.fetch(id)
        end
      end
      
      def find_user(id)
        users_by_id.fetch(id) do
          raise ArgumentError, "Unable to find a user with the ID #{id.inspect}"
        end
      end
      
      def find_group(id)
        groups_by_id.fetch(id) do
          raise ArgumentError, "Unable to find a group with the ID #{id.inspect}"
        end
      end
      
      def get_user_id_for_dm(dm)
        user_id = user_ids_dm_ids.key(dm)
        unless user_id
          response = api("im.list")
          user_ids_dm_ids.merge! Hash[response["ims"].map { |attrs| attrs.values_at("user", "id") }]
          user_id = user_ids_dm_ids.key(dm)
        end
        raise ArgumentError, "Unable to find a user for the direct message ID #{dm.inspect}" unless user_id
        user_id
      end
      
      
      
      def api(command, options={})
        response = Faraday.post(
          "https://slack.com/api/#{command}",
          options.merge(token: Houston::Slack.config.token))
        MultiJson.load(response.body)

      rescue MultiJson::ParseError
        $!.additional_information[:response_body] = response.body
        $!.additional_information[:response_status] = response.status
        raise
      end
      
      def normalize_message(message)
        # !todo: strip punctuation, white space, etc
        message.strip
      end
      
    end
  end
end
