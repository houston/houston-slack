require "houston/slack/engine"
require "houston/slack/configuration"

module Houston
  module Slack
    extend self
    
    attr_reader :config
    
  end
  
  Slack.instance_variable_set :@config, Slack::Configuration.new
end
