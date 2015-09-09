require "houston/slack/engine"
require "houston/slack/configuration"
require "houston/slack/connection"

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
end
