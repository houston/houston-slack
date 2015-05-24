module Houston::Slack
  class SlackController < ApplicationController
    
    def show
      @connection = Houston::Slack.connection
    end
    
    def connect
      Houston::Slack.connection.listen! unless Houston::Slack.connection.listening?
      redirect_to action: :show
    end
    
  end
end
