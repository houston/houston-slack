require "houston/slack/engine"
require "houston/slack/configuration"
require "houston/slack/connection"

module Houston
  module Slack
    extend self
    
    attr_reader :config
    attr_reader :connection
    
    def send(message, options)
      connection.send_message(message, options)
    end
    
  end
  
  Slack.instance_variable_set :@config, Slack::Configuration.new
  Slack.instance_variable_set :@connection, Slack::Connection.new
end
