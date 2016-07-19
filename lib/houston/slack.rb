require "houston/slack/engine"
require "houston/slack/configuration"
require "houston/slack/connection"
require "houston/slack/serializers"

module Houston
  module Slack
    extend self

    attr_reader :connection

    def send(message, options)
      connection.send_message(message, options)
    end

    def config(&block)
      @configuration ||= Slack::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end

  Slack.instance_variable_set :@connection, Slack::Connection.new



  register_events {{
    "daemon:slack:reconnecting" => desc("The connection to Slack was lost; Houston will try to reconnect in a few seconds"),
    "slack:error" => params("message").desc("An error message was received from Slack"),
    "slack:reaction:added" => params("emoji", "channel", "message", "sender").desc("A reaction was added to a message on Slack"),
    "slack:reaction:removed" => params("emoji", "channel", "message", "sender").desc("A reaction was added to a message on Slack")
  }}

  add_serializer Houston::Slack::ChannelSerializer.new
  add_serializer Houston::Slack::MessageSerializer.new
  add_serializer Houston::Slack::SenderSerializer.new

end
