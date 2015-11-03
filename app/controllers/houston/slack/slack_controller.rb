require "houston/slack/slash_command"

module Houston::Slack
  class SlackController < ApplicationController
    skip_before_filter :verify_authenticity_token, only: [:command]

    def show
      @connection = Houston::Slack.connection
    end

    def connect
      Houston::Slack.connection.listen! unless Houston::Slack.connection.listening?
      redirect_to action: :show
    end

    def command
      command = Houston::Slack.config.slash_commands[params[:command].gsub(/^\//, "")]
      unless command
        render text: "A slash command named '#{params[:command]}' is not defined", status: 404
        return
      end

      e = Houston::Slack::SlashCommand.new(self, params)
      command.call e
      head :no_content unless performed?
    end

  end
end
