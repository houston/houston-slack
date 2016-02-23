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

    # Before submitting a command to your server, Slack will occasionally send
    # your command URLs a simple GET request to verify the certificate. These
    # requests will include a parameter ssl_check set to 1. Mostly, you may
    # ignore these requests, but please do respond with a HTTP 200 OK.
    # https://api.slack.com/slash-commands#best_practices
    def ssl_verify
      head :ok
    end

    def command
      command_name = params.fetch(:command).gsub(/^\//, "")
      command = Houston::Slack.config.slash_commands[command_name]
      unless command
        render text: "A slash command named '#{command_name}' is not defined", status: 404
        return
      end

      text = params.fetch :text
      channel = Houston::Slack::Channel.find(params.fetch(:channel_id))
      sender = Houston::Slack::User.find(params.fetch(:user_id))

      e = Houston::Slack::SlashCommand.new(
        message: text,
        channel: channel,
        sender: sender,
        controller: self)

      command.call e
      head :ok unless performed?
    end

  end
end
